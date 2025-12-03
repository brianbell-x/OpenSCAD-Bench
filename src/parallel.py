"""Parallel execution module for running multiple models concurrently with live status display."""

import logging
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from typing import Optional

from rich.live import Live
from rich.table import Table
from rich.console import Console
from rich.logging import RichHandler

from .config import Config
from .openrouter import send_prompt_streaming, OpenRouterError


# Spinner characters for streaming status animation
SPINNER_CHARS = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]


@dataclass
class ModelStatus:
    """Tracks the status of a single model's API call."""
    
    model: str
    status: str = "waiting"  # One of: "waiting", "streaming", "done", "error"
    elapsed_time: float = 0.0
    error_message: Optional[str] = None
    response: Optional[dict] = field(default=None)
    start_time: Optional[float] = field(default=None, repr=False)
    spinner_index: int = field(default=0, repr=False)


def _build_status_table(
    status_dict: dict[str, ModelStatus],
) -> Table:
    """Build a rich Table showing current status of all models.
    
    Args:
        status_dict: Dictionary mapping model names to their current status.
    
    Returns:
        A rich Table with the current status of all models.
    """
    table = Table(
        show_header=True,
        header_style="bold",
    )
    
    table.add_column("Model", style="cyan", min_width=25)
    table.add_column("Status", min_width=10)
    table.add_column("Time", justify="right", min_width=8)
    
    for model, status in status_dict.items():
        # Format status display
        if status.status == "waiting":
            status_display = "[dim]...[/dim]"
        elif status.status == "streaming":
            spinner = SPINNER_CHARS[status.spinner_index % len(SPINNER_CHARS)]
            status_display = f"[yellow]{spinner}[/yellow]"
        elif status.status == "done":
            status_display = "[green]✓ Done[/green]"
        elif status.status == "error":
            status_display = "[red]✗ Error[/red]"
        else:
            status_display = status.status
        
        # Format time display
        time_display = f"{status.elapsed_time:.1f}s"
        
        table.add_row(model, status_display, time_display)
    
    return table


def _run_single_model(
    model: str,
    challenge_prompt: str,
    config: Config,
    status_dict: dict[str, ModelStatus],
    lock: threading.Lock,
) -> None:
    """Run a single model API call and update status.
    
    Args:
        model: The model identifier to use.
        challenge_prompt: The prompt to send to the model.
        config: Configuration object with API settings.
        status_dict: Shared dictionary to update with status changes.
        lock: Threading lock for safe status updates.
    """
    start_time = time.time()
    
    # Update status to streaming
    with lock:
        status_dict[model].status = "streaming"
        status_dict[model].start_time = start_time
    
    def on_activity() -> None:
        """Callback invoked when streaming activity is detected."""
        with lock:
            status_dict[model].elapsed_time = time.time() - start_time
            status_dict[model].spinner_index += 1
    
    try:
        response = send_prompt_streaming(
            model=model,
            system_prompt=config.system_prompt,
            user_prompt=challenge_prompt,
            api_config=config.api,
            api_key=config.api_key,
            silent=True,
            on_activity=on_activity,
        )
        
        elapsed = time.time() - start_time
        
        with lock:
            status_dict[model].status = "done"
            status_dict[model].elapsed_time = elapsed
            status_dict[model].response = response
            
    except OpenRouterError as e:
        elapsed = time.time() - start_time
        
        with lock:
            status_dict[model].status = "error"
            status_dict[model].elapsed_time = elapsed
            status_dict[model].error_message = str(e)
            
    except Exception as e:
        elapsed = time.time() - start_time
        
        with lock:
            status_dict[model].status = "error"
            status_dict[model].elapsed_time = elapsed
            status_dict[model].error_message = f"Unexpected error: {e}"


def run_models_parallel(
    challenge_name: str,
    challenge_prompt: str,
    models: list[str],
    config: Config,
) -> dict[str, ModelStatus]:
    """Run API calls for multiple models in parallel with live status display.
    
    Args:
        challenge_name: Name of the challenge being run.
        challenge_prompt: The prompt to send to all models.
        models: List of model identifiers to run.
        config: Configuration object with API settings.
    
    Returns:
        Dictionary mapping model names to their final ModelStatus.
    """
    # Initialize status dict
    status_dict: dict[str, ModelStatus] = {
        model: ModelStatus(model=model) for model in models
    }
    
    lock = threading.Lock()
    # Use force_terminal=True to ensure Rich controls the terminal properly
    console = Console(force_terminal=True)
    
    # Temporarily suppress logging handlers that write to stderr
    # This prevents logging output from corrupting the Rich Live display
    root_logger = logging.getLogger()
    original_handlers = root_logger.handlers[:]
    original_level = root_logger.level
    
    # Remove all handlers temporarily - we'll restore them after Live display
    for handler in original_handlers:
        root_logger.removeHandler(handler)
    
    # Use ThreadPoolExecutor for parallel execution
    with ThreadPoolExecutor(max_workers=len(models)) as executor:
        # Submit all model tasks
        futures = {
            executor.submit(
                _run_single_model,
                model,
                challenge_prompt,
                config,
                status_dict,
                lock,
            ): model
            for model in models
        }
        
        # Use Rich Live display for real-time updates
        # transient=True clears the live display when done, preventing stacking
        # vertical_overflow="visible" ensures the table renders correctly
        with Live(
            _build_status_table(status_dict),
            console=console,
            refresh_per_second=10,
            transient=True,
            vertical_overflow="visible",
        ) as live:
            # Poll for updates while tasks are running
            while not all(
                status_dict[model].status in ("done", "error")
                for model in models
            ):
                # Update elapsed time for streaming models
                current_time = time.time()
                with lock:
                    for model, status in status_dict.items():
                        if status.status == "streaming" and status.start_time:
                            status.elapsed_time = current_time - status.start_time
                
                # Refresh the display
                live.update(
                    _build_status_table(status_dict)
                )
                
                time.sleep(0.1)
        
        # Print final static table after Live display ends
        # This ensures the final state is visible and won't be overwritten
        console.print(_build_status_table(status_dict))
        
        # Restore logging handlers
        for handler in original_handlers:
            root_logger.addHandler(handler)
        root_logger.setLevel(original_level)
        
        # Wait for all futures to complete (they should already be done)
        for future in as_completed(futures):
            # Just ensure all tasks have completed
            try:
                future.result()
            except Exception:
                # Errors are already captured in status_dict
                pass
    
    return status_dict