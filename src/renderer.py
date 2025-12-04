"""OpenSCAD rendering integration module.

This module takes generated .scad code and renders it to .stl using the local OpenSCAD executable.
It also provides utilities for saving run metadata.
"""

import json
import subprocess
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import TYPE_CHECKING, Callable

if TYPE_CHECKING:
    from config import ApiConfig


@dataclass
class RenderResult:
    """Result of an OpenSCAD rendering attempt."""

    success: bool
    scad_path: Path
    stl_path: Path | None
    error_message: str | None
    render_time: float


def save_scad(code: str, output_dir: Path, filename: str = "attempt.scad") -> Path:
    """Save OpenSCAD code to the specified directory.

    Args:
        code: The OpenSCAD code to save.
        output_dir: Directory where the file will be saved.
        filename: Name of the output file (default: "attempt.scad").

    Returns:
        Path to the saved file.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    scad_path = output_dir / filename
    scad_path.write_text(code, encoding="utf-8")
    return scad_path


def render_stl(
    scad_path: Path, openscad_path: str, timeout: float = 1200.0
) -> RenderResult:
    """Render an OpenSCAD file to STL.

    Args:
        scad_path: Path to the .scad file to render.
        openscad_path: Path to the OpenSCAD executable.
        timeout: Maximum time in seconds to wait for rendering (default: 1200).

    Returns:
        RenderResult with success/failure information.
    """
    stl_path = scad_path.with_suffix(".stl")

    start_time = time.perf_counter()

    try:
        result = subprocess.run(
            [openscad_path, "-o", str(stl_path), str(scad_path)],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        render_time = time.perf_counter() - start_time

        if result.returncode == 0 and stl_path.exists():
            return RenderResult(
                success=True,
                scad_path=scad_path,
                stl_path=stl_path,
                error_message=None,
                render_time=render_time,
            )
        else:
            # OpenSCAD returned non-zero exit code
            error_msg = result.stderr.strip() if result.stderr else result.stdout.strip()
            if not error_msg:
                error_msg = f"OpenSCAD exited with code {result.returncode}"
            return RenderResult(
                success=False,
                scad_path=scad_path,
                stl_path=None,
                error_message=error_msg,
                render_time=render_time,
            )

    except FileNotFoundError:
        render_time = time.perf_counter() - start_time
        return RenderResult(
            success=False,
            scad_path=scad_path,
            stl_path=None,
            error_message=f"OpenSCAD executable not found: {openscad_path}",
            render_time=render_time,
        )

    except subprocess.TimeoutExpired:
        render_time = time.perf_counter() - start_time
        return RenderResult(
            success=False,
            scad_path=scad_path,
            stl_path=None,
            error_message=f"Rendering timed out after {timeout} seconds",
            render_time=render_time,
        )


def process_attempt(
    code: str, output_dir: Path, openscad_path: str, timeout: float = 1200.0
) -> RenderResult:
    """Save OpenSCAD code and render it to STL.

    Convenience function that combines save_scad and render_stl.

    Args:
        code: The OpenSCAD code to render.
        output_dir: Directory where files will be saved.
        openscad_path: Path to the OpenSCAD executable.
        timeout: Maximum time in seconds to wait for rendering (default: 1200).

    Returns:
        RenderResult with success/failure information.
    """
    scad_path = save_scad(code, output_dir)
    return render_stl(scad_path, openscad_path, timeout=timeout)


def process_renders_parallel(
    render_tasks: list[tuple[str, Path, str]],
    openscad_path: str,
    max_workers: int = 5,
    timeout: float = 1200.0,
    on_complete: Callable[[str, RenderResult], None] | None = None,
) -> dict[str, RenderResult]:
    """Process multiple renders in parallel with thread pool.
    
    Args:
        render_tasks: List of tuples (model_name, output_dir, code) to render.
        openscad_path: Path to the OpenSCAD executable.
        max_workers: Maximum number of concurrent render threads (default: 5).
        timeout: Maximum time in seconds per render (default: 1200).
        on_complete: Optional callback function(model_name, RenderResult) called when each render completes.
    
    Returns:
        Dictionary mapping model names to their RenderResult.
    """
    results: dict[str, RenderResult] = {}
    
    def render_task(model: str, output_dir: Path, code: str) -> tuple[str, RenderResult]:
        scad_path = save_scad(code, output_dir)
        result = render_stl(scad_path, openscad_path, timeout)
        return model, result
    
    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {
            executor.submit(render_task, model, output_dir, code): model
            for model, output_dir, code in render_tasks
        }
        
        for future in as_completed(futures):
            model, result = future.result()
            results[model] = result
            if on_complete:
                on_complete(model, result)
    
    return results


def save_params_json(
    output_dir: Path,
    model: str,
    api_config: "ApiConfig",
) -> Path:
    """Save run parameters to a params.json file.
    
    Documents the parameter configuration used for a benchmark run including
    all LLM parameters, timestamp, and model information.
    
    Args:
        output_dir: Directory where params.json will be saved.
        model: The model ID used for this run.
        api_config: The API configuration with LLM parameters.
        
    Returns:
        Path to the saved params.json file.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Build params dictionary
    params_data = {
        "model": model,
        "timestamp": datetime.now().isoformat(),
        "timeout": api_config.timeout,
    }
    
    # Add all LLM parameters that are set
    llm_params = api_config.get_all_params()
    if llm_params:
        params_data["llm_parameters"] = llm_params
    
    # Add non-default parameters separately for easy reference
    non_default = api_config.get_non_default_params()
    if non_default:
        params_data["non_default_parameters"] = non_default
    
    # Write to file
    params_path = output_dir / "params.json"
    with open(params_path, 'w', encoding='utf-8') as f:
        json.dump(params_data, f, indent=2)
    
    return params_path