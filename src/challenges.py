"""Challenge discovery and prompt loading for OpenSCAD benchmark."""

import shutil
import warnings
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from config import ApiConfig


class ChallengeError(Exception):
    """Raised when challenge discovery or filtering fails."""
    pass


@dataclass
class Challenge:
    """Represents a benchmark challenge.
    
    Attributes:
        name: Challenge directory name (e.g., "headphone-hook")
        prompt: Content of prompt.md
        path: Full path to challenge directory
    """
    name: str
    prompt: str
    path: Path


def discover_challenges(base_path: Path) -> list[Challenge]:
    """Discover all valid challenges from the challenges directory.
    
    A valid challenge is a directory containing a prompt.md file.
    The TEMPLATE directory is excluded.
    
    Args:
        base_path: Path to the project root directory.
        
    Returns:
        List of Challenge objects sorted by name.
        
    Raises:
        ChallengeError: If challenges directory doesn't exist.
    """
    challenges_dir = base_path / "challenges"
    
    if not challenges_dir.exists():
        raise ChallengeError(f"Challenges directory not found: {challenges_dir}")
    
    if not challenges_dir.is_dir():
        raise ChallengeError(f"Challenges path is not a directory: {challenges_dir}")
    
    challenges = []
    
    for entry in challenges_dir.iterdir():
        # Skip non-directories
        if not entry.is_dir():
            continue
        
        # Skip TEMPLATE directory
        if entry.name == "TEMPLATE":
            continue
        
        # Check for prompt.md
        prompt_file = entry / "prompt.md"
        if not prompt_file.exists():
            continue
        
        # Read the prompt content
        try:
            prompt_content = prompt_file.read_text(encoding="utf-8").strip()
        except IOError as e:
            raise ChallengeError(f"Failed to read prompt for challenge '{entry.name}': {e}")
        
        challenges.append(Challenge(
            name=entry.name,
            prompt=prompt_content,
            path=entry,
        ))
    
    # Sort by name
    challenges.sort(key=lambda c: c.name)
    
    return challenges


def filter_challenges(
    challenges: list[Challenge],
    filter_list: list[str] | str,
    exclude_list: list[str] | None = None
) -> list[Challenge]:
    """Filter challenges by name, optionally excluding specific ones.
    
    Args:
        challenges: List of all available challenges.
        filter_list: Either "all" to return all challenges, or a list of
            challenge names to filter to.
        exclude_list: Optional list of challenge names to exclude. Only applies
            when filter_list is "all". If a challenge is in exclude_list but
            doesn't exist, a warning is issued.
            
    Returns:
        Filtered list of challenges.
        
    Raises:
        ChallengeError: If a requested challenge doesn't exist.
    """
    # Build lookup set for available challenges
    available = {c.name: c for c in challenges}
    
    if filter_list == "all":
        result = list(challenges)
        
        # Apply exclusion filter if provided
        if exclude_list:
            # Validate that excluded challenges exist and warn if not
            for name in exclude_list:
                if name not in available:
                    warnings.warn(
                        f"Excluded challenge '{name}' does not exist. "
                        f"Available challenges: {sorted(available.keys())}",
                        UserWarning
                    )
            
            # Filter out excluded challenges
            result = [c for c in result if c.name not in exclude_list]
        
        return result
    
    # Check that all requested challenges exist
    missing = []
    for name in filter_list:
        if name not in available:
            missing.append(name)
    
    if missing:
        available_names = sorted(available.keys())
        raise ChallengeError(
            f"Requested challenges not found: {missing}. "
            f"Available challenges: {available_names}"
        )
    
    # Return filtered list, preserving order from filter_list
    return [available[name] for name in filter_list]


def sanitize_model_name(model: str) -> str:
    """Convert a model ID to a filesystem-safe name.
    
    Replaces characters that are invalid in Windows directory names:
    - Forward slashes (/) with double dashes (--)
    - Colons (:) with single dash (-)
    
    Args:
        model: Model ID like "openai/gpt-4o" or "x-ai/grok-4.1-fast:free"
        
    Returns:
        Sanitized name like "openai--gpt-4o" or "x-ai--grok-4.1-fast-free"
    """
    sanitized = model.replace("/", "--")
    sanitized = sanitized.replace(":", "-")
    return sanitized


def generate_param_suffix(api_config: "ApiConfig") -> str:
    """Generate a folder name suffix based on non-default parameters.
    
    Creates a short, descriptive suffix for distinguishing runs with different
    parameter configurations.
    
    Args:
        api_config: The API configuration with LLM parameters.
        
    Returns:
        A suffix string like "temp07" or "temp07-topk50" or "custom" for complex configs.
        Returns empty string if no non-default parameters are set.
        
    Examples:
        - temperature=0.7 → "temp07"
        - temperature=0.7, top_k=50 → "temp07-topk50"
        - Many params → "custom"
    """
    non_default = api_config.get_non_default_params()
    if not non_default:
        return ""
    
    # Define abbreviations for common parameters
    param_abbrevs = {
        "temperature": "temp",
        "top_p": "topp",
        "top_k": "topk",
        "frequency_penalty": "freqp",
        "presence_penalty": "presp",
        "repetition_penalty": "repp",
        "min_p": "minp",
        "top_a": "topa",
        "seed": "seed",
        "max_tokens": "maxt",
        "reasoning": "reason",
    }
    
    # Build suffix parts
    parts = []
    
    for param, value in non_default.items():
        if param not in param_abbrevs:
            continue
            
        abbrev = param_abbrevs[param]
        
        if param == "reasoning":
            # For reasoning, just indicate it's enabled
            if isinstance(value, dict):
                if "effort" in value:
                    parts.append(f"reason-{value['effort']}")
                elif "max_tokens" in value:
                    parts.append(f"reason-{value['max_tokens']}")
                else:
                    parts.append("reason")
            continue
        
        # Format numeric values compactly
        if isinstance(value, float):
            # Format as compact string: 0.7 → "07", 1.5 → "15"
            if value == int(value):
                formatted = str(int(value))
            else:
                # Remove decimal point for compactness
                formatted = f"{value:.2f}".replace(".", "").lstrip("0") or "0"
        elif isinstance(value, int):
            formatted = str(value)
        else:
            formatted = str(value)
        
        parts.append(f"{abbrev}{formatted}")
    
    # If too many parts (more than 3), use "custom" instead
    if len(parts) > 3:
        return "custom"
    
    return "-".join(parts)


def get_model_output_dir(
    challenge: Challenge,
    model: str,
    api_config: "ApiConfig | None" = None
) -> Path:
    """Get the output directory for a model's challenge attempt.
    
    When non-default API parameters are used, the folder name includes a suffix
    to distinguish runs with different configurations.
    
    Args:
        challenge: The challenge being attempted.
        model: The model ID (e.g., "openai/gpt-4o").
        api_config: Optional API configuration. If provided and has non-default
            parameters, a suffix will be appended to the folder name.
        
    Returns:
        Path to the model's output directory. The directory is created
        if it doesn't exist.
        
    Examples:
        - Base: challenges/box-lid/models/openai--gpt-4o/
        - With temp=0.7: challenges/box-lid/models/openai--gpt-4o--temp07/
        - Complex config: challenges/box-lid/models/openai--gpt-4o--custom/
    """
    sanitized = sanitize_model_name(model)
    
    # Add parameter suffix if non-default params are configured
    if api_config is not None:
        suffix = generate_param_suffix(api_config)
        if suffix:
            sanitized = f"{sanitized}--{suffix}"
    
    output_dir = challenge.path / "models" / sanitized
    
    # Remove existing directory if it exists, then create fresh
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    
    return output_dir