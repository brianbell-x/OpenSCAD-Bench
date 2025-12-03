#!/usr/bin/env python3
"""OpenSCAD Benchmark Automation Script.

Orchestrates LLM testing against OpenSCAD coding challenges.
"""

import argparse
import json
import logging
import sys
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

# Add src to path for imports
sys.path.insert(0, str(Path(__file__).parent / "src"))

from src.config import get_config, load_config, ConfigError
from src.openrouter import send_prompt, extract_code, OpenRouterError
from src.parallel import run_models_parallel, ModelStatus
from challenges import discover_challenges, filter_challenges, get_model_output_dir, ChallengeError
from src.renderer import process_attempt, save_params_json


@dataclass
class BenchmarkResult:
    """Result of a single benchmark attempt."""
    challenge: str
    model: str
    api_success: bool
    render_success: bool
    error_message: str | None = None
    render_time: float | None = None


def setup_logging(verbose: bool) -> None:
    """Configure logging based on verbosity level."""
    level = logging.DEBUG if verbose else logging.INFO
    
    # Create formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(levelname)s - %(message)s',
        datefmt='%H:%M:%S'
    )
    
    # Configure root logger
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    
    # Console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(level)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)


def save_raw_response(output_dir: Path, response: dict) -> None:
    """Save raw API response for debugging."""
    response_file = output_dir / "response.json"
    with open(response_file, 'w', encoding='utf-8') as f:
        json.dump(response, f, indent=2)


def print_summary(results: list[BenchmarkResult]) -> None:
    """Print a summary report of benchmark results."""
    print("\n" + "=" * 60)
    print("=== Benchmark Complete ===")
    print("=" * 60)
    print()
    
    if not results:
        print("No results to display.")
        return
    
    # Calculate column widths
    challenge_width = max(len(r.challenge) for r in results)
    challenge_width = max(challenge_width, len("Challenge"))
    
    model_width = max(len(r.model) for r in results)
    model_width = max(model_width, len("Model"))
    
    # Truncate model names if too long
    max_model_width = 35
    if model_width > max_model_width:
        model_width = max_model_width
    
    # Print header
    print("Results:")
    header = f"| {'Challenge':<{challenge_width}} | {'Model':<{model_width}} | Render |"
    separator = f"|{'-' * (challenge_width + 2)}|{'-' * (model_width + 2)}|--------|"
    
    print(separator)
    print(header)
    print(separator)
    
    # Print results
    successful = 0
    for r in results:
        model_display = r.model
        if len(model_display) > model_width:
            model_display = model_display[:model_width - 3] + "..."
        
        if r.render_success:
            status = "✓"
            successful += 1
        elif r.api_success:
            status = "✗"
        else:
            status = "API ✗"
        
        print(f"| {r.challenge:<{challenge_width}} | {model_display:<{model_width}} | {status:^6} |")
    
    print(separator)
    print()
    print(f"Total: {successful}/{len(results)} successful renders")
    print()


def run_benchmark(
    config_path: str,
    dry_run: bool = False,
    verbose: bool = False
) -> list[BenchmarkResult]:
    """Run the full benchmark suite.
    
    Args:
        config_path: Path to the configuration YAML file.
        dry_run: If True, show what would run without calling APIs.
        verbose: If True, enable verbose logging.
        
    Returns:
        List of BenchmarkResult objects.
    """
    logger = logging.getLogger(__name__)
    results: list[BenchmarkResult] = []
    
    # Load configuration
    logger.info("Loading configuration from %s", config_path)
    
    try:
        if dry_run:
            # For dry run, just load config without API key requirement
            config = load_config(config_path)
            logger.info("Dry run mode - skipping API key validation")
        else:
            config = get_config(config_path)
    except FileNotFoundError as e:
        logger.error("Configuration file not found: %s", e)
        sys.exit(1)
    except ConfigError as e:
        logger.error("Configuration error: %s", e)
        sys.exit(1)
    
    logger.info("Loaded %d models from config", len(config.models))
    
    # Discover challenges
    try:
        all_challenges = discover_challenges(config.project_root)
        challenges = filter_challenges(
            all_challenges,
            config.challenges,
            config.exclude_challenges
        )
    except ChallengeError as e:
        logger.error("Challenge error: %s", e)
        sys.exit(1)
    
    logger.info("Discovered %d challenges", len(challenges))
    
    if not challenges:
        logger.warning("No challenges found to run")
        return results
    
    # Display discovered challenges
    for challenge in challenges:
        logger.debug("  - %s", challenge.name)
    
    # Calculate total runs
    total_runs = len(challenges) * len(config.models)
    logger.info("Running %d total benchmark combinations", total_runs)
    
    if dry_run:
        print("\n=== DRY RUN MODE ===\n")
        print("Would run the following benchmarks:\n")
        for challenge in challenges:
            for model in config.models:
                output_dir = get_model_output_dir(challenge, model, config.api)
                print(f"  • {challenge.name} × {model}")
                print(f"    Output: {output_dir}")
        print(f"\nTotal: {total_runs} benchmark runs")
        print("\nNo API calls will be made in dry-run mode.")
        return results
    
    # Run benchmarks - use parallel execution for all models per challenge
    for challenge_idx, challenge in enumerate(challenges, 1):
        logger.info(
            "[Challenge %d/%d] Running: %s with %d models",
            challenge_idx, len(challenges), challenge.name, len(config.models)
        )
        
        # Run all models in parallel for this challenge
        model_statuses = run_models_parallel(
            challenge_name=challenge.name,
            challenge_prompt=challenge.prompt,
            models=config.models,
            config=config,
        )
        
        # Process results for each model (render, save, etc.)
        for model, status in model_statuses.items():
            # Get output directory for this attempt
            output_dir = get_model_output_dir(challenge, model, config.api)
            
            # Save params.json documenting this run's configuration
            save_params_json(output_dir, model, config.api, challenge.name)
            
            api_success = False
            render_success = False
            error_message = None
            render_time = None
            
            if status.status == "done" and status.response is not None:
                # API call succeeded - save response and render
                api_success = True
                
                # Save raw response for debugging
                save_raw_response(output_dir, status.response)
                
                try:
                    # Extract code from response
                    code = extract_code(status.response)
                    logger.debug("Successfully extracted code (%d bytes) for %s", len(code), model)
                    
                    # Render to STL
                    logger.debug("Rendering .scad to .stl for %s", model)
                    render_result = process_attempt(
                        code=code,
                        output_dir=output_dir,
                        openscad_path=config.openscad_path
                    )
                    
                    render_success = render_result.success
                    render_time = render_result.render_time
                    
                    if render_success:
                        logger.info(
                            "✓ Success: %s × %s (render: %.2fs)",
                            challenge.name, model, render_time
                        )
                    else:
                        error_message = render_result.error_message
                        logger.warning(
                            "✗ Render failed: %s × %s - %s",
                            challenge.name, model, error_message
                        )
                        
                        # Save render error to log
                        error_file = output_dir / "render_error.log"
                        with open(error_file, 'w', encoding='utf-8') as f:
                            f.write(f"Render Error at {datetime.now().isoformat()}\n")
                            f.write(f"Model: {model}\n")
                            f.write(f"Challenge: {challenge.name}\n")
                            f.write(f"Error: {error_message}\n")
                            f.write(f"SCAD file: {render_result.scad_path}\n")
                            
                except ValueError as e:
                    error_message = f"Failed to extract code: {e}"
                    logger.error(error_message)
                    api_success = False
                    
                except Exception as e:
                    error_message = f"Unexpected render error: {e}"
                    logger.exception("Unexpected error during rendering for %s", model)
                    
            elif status.status == "error":
                # API call failed
                error_message = status.error_message or "Unknown API error"
                logger.error("API error for %s: %s", model, error_message)
                
                # Save error to log file
                error_file = output_dir / "error.log"
                with open(error_file, 'w', encoding='utf-8') as f:
                    f.write(f"API Error at {datetime.now().isoformat()}\n")
                    f.write(f"Model: {model}\n")
                    f.write(f"Challenge: {challenge.name}\n")
                    f.write(f"Error: {error_message}\n")
            
            results.append(BenchmarkResult(
                challenge=challenge.name,
                model=model,
                api_success=api_success,
                render_success=render_success,
                error_message=error_message,
                render_time=render_time
            ))
    
    return results


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="OpenSCAD Benchmark Automation - Test LLMs against OpenSCAD coding challenges",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                      Run all benchmarks using config.yaml
  %(prog)s --config my.yaml     Use custom config file
  %(prog)s --dry-run            Show what would run without calling APIs
  %(prog)s --verbose            Enable verbose logging

Environment Variables:
  OPENROUTER_API_KEY           Required API key for OpenRouter
        """
    )
    
    parser.add_argument(
        "--config",
        default="config.yaml",
        help="Path to configuration YAML file (default: config.yaml)"
    )
    
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be run without actually calling APIs"
    )
    
    parser.add_argument(
        "--verbose", "-v",
        action="store_true",
        help="Enable verbose logging output"
    )
    
    args = parser.parse_args()
    
    # Setup logging
    setup_logging(args.verbose)
    
    logger = logging.getLogger(__name__)
    logger.info("OpenSCAD Benchmark Automation")
    logger.info("=" * 40)
    
    # Run benchmark
    results = run_benchmark(
        config_path=args.config,
        dry_run=args.dry_run,
        verbose=args.verbose
    )
    
    # Print summary (only if not dry run)
    if not args.dry_run and results:
        print_summary(results)
    
    # Exit with appropriate code
    if results:
        successful = sum(1 for r in results if r.render_success)
        if successful == len(results):
            sys.exit(0)  # All successful
        elif successful > 0:
            sys.exit(1)  # Partial success
        else:
            sys.exit(2)  # All failed
    else:
        sys.exit(0)  # Dry run or no challenges


if __name__ == "__main__":
    main()