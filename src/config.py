"""Configuration loading and validation for OpenSCAD benchmark automation."""

from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional, Union
import os
import re
import shutil

import yaml
from dotenv import load_dotenv


class ConfigError(Exception):
    """Raised when configuration is invalid."""
    pass


# Default values for LLM parameters (used to detect non-default settings)
LLM_PARAM_DEFAULTS = {
    "temperature": 1.0,
    "top_p": 1.0,
    "top_k": 0,
    "frequency_penalty": 0.0,
    "presence_penalty": 0.0,
    "repetition_penalty": 1.0,
    "min_p": 0.0,
    "top_a": 0.0,
    "seed": None,
    "max_tokens": None,
}

# Valid reasoning effort levels
VALID_REASONING_EFFORTS = {"low", "medium", "high"}


@dataclass
class ReasoningConfig:
    """Configuration for reasoning/thinking tokens.
    
    Models like OpenAI o-series, Anthropic Claude 3.7+, DeepSeek R1, etc.
    support extended reasoning. These settings control that behavior.
    """
    enabled: bool = False  # Explicitly enable reasoning with defaults
    effort: Optional[str] = None  # "low", "medium", or "high"
    max_tokens: Optional[int] = None  # Specific token limit (Anthropic-style)
    exclude: bool = False  # If True, reasoning happens but isn't returned
    
    def is_enabled(self) -> bool:
        """Check if reasoning is enabled."""
        return self.enabled or self.effort is not None or self.max_tokens is not None
    
    def to_api_dict(self) -> Optional[dict]:
        """Convert to dictionary for API request.
        
        Returns:
            Dictionary suitable for the 'reasoning' parameter in API requests,
            or None if reasoning is not configured.
        """
        if not self.is_enabled() and not self.exclude:
            return None
        
        result = {}
        
        # If just enabled with no specific settings, use medium effort as default
        if self.enabled and self.effort is None and self.max_tokens is None:
            result["effort"] = "medium"
        elif self.effort is not None:
            result["effort"] = self.effort
        
        if self.max_tokens is not None:
            result["max_tokens"] = self.max_tokens
        if self.exclude:
            result["exclude"] = True
        
        return result if result else None


@dataclass
class ApiConfig:
    """API configuration settings including LLM parameters."""
    timeout: int = 600
    
    # LLM Parameters (all optional - None means use model defaults)
    temperature: Optional[float] = None
    top_p: Optional[float] = None
    top_k: Optional[int] = None
    frequency_penalty: Optional[float] = None
    presence_penalty: Optional[float] = None
    repetition_penalty: Optional[float] = None
    min_p: Optional[float] = None
    top_a: Optional[float] = None
    seed: Optional[int] = None
    max_tokens: Optional[int] = None
    
    # Reasoning settings
    reasoning: Optional[ReasoningConfig] = None
    
    def has_non_default_params(self) -> bool:
        """Check if any LLM parameters are set to non-default values.
        
        Returns:
            True if any parameter differs from the default, False otherwise.
        """
        if self.temperature is not None and self.temperature != LLM_PARAM_DEFAULTS["temperature"]:
            return True
        if self.top_p is not None and self.top_p != LLM_PARAM_DEFAULTS["top_p"]:
            return True
        if self.top_k is not None and self.top_k != LLM_PARAM_DEFAULTS["top_k"]:
            return True
        if self.frequency_penalty is not None and self.frequency_penalty != LLM_PARAM_DEFAULTS["frequency_penalty"]:
            return True
        if self.presence_penalty is not None and self.presence_penalty != LLM_PARAM_DEFAULTS["presence_penalty"]:
            return True
        if self.repetition_penalty is not None and self.repetition_penalty != LLM_PARAM_DEFAULTS["repetition_penalty"]:
            return True
        if self.min_p is not None and self.min_p != LLM_PARAM_DEFAULTS["min_p"]:
            return True
        if self.top_a is not None and self.top_a != LLM_PARAM_DEFAULTS["top_a"]:
            return True
        if self.seed is not None:
            return True
        if self.max_tokens is not None:
            return True
        # Check reasoning settings
        if self.reasoning is not None and self.reasoning.is_enabled():
            return True
        return False
    
    def get_non_default_params(self) -> dict:
        """Get a dictionary of parameters that differ from defaults.
        
        Returns:
            Dictionary mapping parameter names to their non-default values.
        """
        params = {}
        if self.temperature is not None and self.temperature != LLM_PARAM_DEFAULTS["temperature"]:
            params["temperature"] = self.temperature
        if self.top_p is not None and self.top_p != LLM_PARAM_DEFAULTS["top_p"]:
            params["top_p"] = self.top_p
        if self.top_k is not None and self.top_k != LLM_PARAM_DEFAULTS["top_k"]:
            params["top_k"] = self.top_k
        if self.frequency_penalty is not None and self.frequency_penalty != LLM_PARAM_DEFAULTS["frequency_penalty"]:
            params["frequency_penalty"] = self.frequency_penalty
        if self.presence_penalty is not None and self.presence_penalty != LLM_PARAM_DEFAULTS["presence_penalty"]:
            params["presence_penalty"] = self.presence_penalty
        if self.repetition_penalty is not None and self.repetition_penalty != LLM_PARAM_DEFAULTS["repetition_penalty"]:
            params["repetition_penalty"] = self.repetition_penalty
        if self.min_p is not None and self.min_p != LLM_PARAM_DEFAULTS["min_p"]:
            params["min_p"] = self.min_p
        if self.top_a is not None and self.top_a != LLM_PARAM_DEFAULTS["top_a"]:
            params["top_a"] = self.top_a
        if self.seed is not None:
            params["seed"] = self.seed
        if self.max_tokens is not None:
            params["max_tokens"] = self.max_tokens
        # Include reasoning if enabled
        if self.reasoning is not None and self.reasoning.is_enabled():
            reasoning_dict = self.reasoning.to_api_dict()
            if reasoning_dict:
                params["reasoning"] = reasoning_dict
        return params
    
    def get_all_params(self) -> dict:
        """Get a dictionary of all set LLM parameters (non-None values).
        
        Returns:
            Dictionary mapping parameter names to their values.
        """
        params = {}
        if self.temperature is not None:
            params["temperature"] = self.temperature
        if self.top_p is not None:
            params["top_p"] = self.top_p
        if self.top_k is not None:
            params["top_k"] = self.top_k
        if self.frequency_penalty is not None:
            params["frequency_penalty"] = self.frequency_penalty
        if self.presence_penalty is not None:
            params["presence_penalty"] = self.presence_penalty
        if self.repetition_penalty is not None:
            params["repetition_penalty"] = self.repetition_penalty
        if self.min_p is not None:
            params["min_p"] = self.min_p
        if self.top_a is not None:
            params["top_a"] = self.top_a
        if self.seed is not None:
            params["seed"] = self.seed
        if self.max_tokens is not None:
            params["max_tokens"] = self.max_tokens
        # Include reasoning if configured
        if self.reasoning is not None:
            reasoning_dict = self.reasoning.to_api_dict()
            if reasoning_dict:
                params["reasoning"] = reasoning_dict
        return params


@dataclass
class Config:
    """Main configuration for OpenSCAD benchmark automation."""
    models: list[str]
    challenges: Union[str, list[str]] = "all"
    exclude_challenges: list[str] = field(default_factory=list)
    openscad_path: str = "openscad"
    api: ApiConfig = field(default_factory=ApiConfig)
    
    # Loaded at runtime
    _system_prompt: str = field(default="", repr=False)
    _api_key: Optional[str] = field(default=None, repr=False)
    _project_root: Optional[Path] = field(default=None, repr=False)
    
    @property
    def system_prompt(self) -> str:
        """Get the system prompt content."""
        if not self._system_prompt:
            raise ConfigError("System prompt not configured.")
        return self._system_prompt
    
    @property
    def api_key(self) -> str:
        """Get the API key from environment."""
        if self._api_key is None:
            raise ConfigError("API key not loaded. Call load_api_key() first.")
        return self._api_key
    
    @property
    def project_root(self) -> Path:
        """Get the project root directory."""
        if self._project_root is None:
            raise ConfigError("Project root not set.")
        return self._project_root


def _validate_model_id(model_id: str) -> None:
    """Validate that a model ID matches the expected format."""
    if not isinstance(model_id, str):
        raise ConfigError(f"Model ID must be a string, got {type(model_id).__name__}")
    
    # Must contain exactly one slash
    if model_id.count('/') != 1:
        raise ConfigError(
            f"Invalid model ID format: '{model_id}'. "
            "Expected format: {{provider}}/{{model-name}}"
        )
    
    provider, model_name = model_id.split('/')
    if not provider or not model_name:
        raise ConfigError(
            f"Invalid model ID format: '{model_id}'. "
            "Both provider and model name must be non-empty."
        )


def _validate_challenges(challenges: Union[str, list]) -> None:
    """Validate the challenges configuration."""
    if isinstance(challenges, str):
        if challenges != "all":
            raise ConfigError(
                f"Invalid challenges value: '{challenges}'. "
                "Must be 'all' or a list of challenge names."
            )
    elif isinstance(challenges, list):
        if not challenges:
            raise ConfigError("Challenges list cannot be empty.")
        for challenge in challenges:
            if not isinstance(challenge, str):
                raise ConfigError(
                    f"Challenge name must be a string, got {type(challenge).__name__}"
                )
            if not challenge:
                raise ConfigError("Challenge name cannot be empty.")
    else:
        raise ConfigError(
            f"Challenges must be 'all' or a list of strings, got {type(challenges).__name__}"
        )


def _validate_exclude_challenges(exclude_challenges: list) -> None:
    """Validate the exclude_challenges configuration."""
    if not isinstance(exclude_challenges, list):
        raise ConfigError(
            f"'exclude_challenges' must be a list of strings, got {type(exclude_challenges).__name__}"
        )
    for challenge in exclude_challenges:
        if not isinstance(challenge, str):
            raise ConfigError(
                f"Exclude challenge name must be a string, got {type(challenge).__name__}"
            )
        if not challenge:
            raise ConfigError("Exclude challenge name cannot be empty.")


def _validate_api_config(api_dict: dict) -> ApiConfig:
    """Validate and create ApiConfig from dictionary."""
    api_config = ApiConfig()
    
    if "timeout" in api_dict:
        timeout = api_dict["timeout"]
        if not isinstance(timeout, int) or timeout <= 0:
            raise ConfigError(f"API timeout must be a positive integer, got {timeout}")
        api_config.timeout = timeout
    
    # Validate LLM parameters
    
    # Temperature: 0.0 to 2.0
    if "temperature" in api_dict and api_dict["temperature"] is not None:
        temp = api_dict["temperature"]
        if not isinstance(temp, (int, float)):
            raise ConfigError(f"temperature must be a number, got {type(temp).__name__}")
        if temp < 0.0 or temp > 2.0:
            raise ConfigError(f"temperature must be between 0.0 and 2.0, got {temp}")
        api_config.temperature = float(temp)
    
    # Top P: 0.0 to 1.0
    if "top_p" in api_dict and api_dict["top_p"] is not None:
        top_p = api_dict["top_p"]
        if not isinstance(top_p, (int, float)):
            raise ConfigError(f"top_p must be a number, got {type(top_p).__name__}")
        if top_p < 0.0 or top_p > 1.0:
            raise ConfigError(f"top_p must be between 0.0 and 1.0, got {top_p}")
        api_config.top_p = float(top_p)
    
    # Top K: 0 or above (integer)
    if "top_k" in api_dict and api_dict["top_k"] is not None:
        top_k = api_dict["top_k"]
        if not isinstance(top_k, int):
            raise ConfigError(f"top_k must be an integer, got {type(top_k).__name__}")
        if top_k < 0:
            raise ConfigError(f"top_k must be 0 or above, got {top_k}")
        api_config.top_k = top_k
    
    # Frequency Penalty: -2.0 to 2.0
    if "frequency_penalty" in api_dict and api_dict["frequency_penalty"] is not None:
        freq = api_dict["frequency_penalty"]
        if not isinstance(freq, (int, float)):
            raise ConfigError(f"frequency_penalty must be a number, got {type(freq).__name__}")
        if freq < -2.0 or freq > 2.0:
            raise ConfigError(f"frequency_penalty must be between -2.0 and 2.0, got {freq}")
        api_config.frequency_penalty = float(freq)
    
    # Presence Penalty: -2.0 to 2.0
    if "presence_penalty" in api_dict and api_dict["presence_penalty"] is not None:
        pres = api_dict["presence_penalty"]
        if not isinstance(pres, (int, float)):
            raise ConfigError(f"presence_penalty must be a number, got {type(pres).__name__}")
        if pres < -2.0 or pres > 2.0:
            raise ConfigError(f"presence_penalty must be between -2.0 and 2.0, got {pres}")
        api_config.presence_penalty = float(pres)
    
    # Repetition Penalty: 0.0 to 2.0
    if "repetition_penalty" in api_dict and api_dict["repetition_penalty"] is not None:
        rep = api_dict["repetition_penalty"]
        if not isinstance(rep, (int, float)):
            raise ConfigError(f"repetition_penalty must be a number, got {type(rep).__name__}")
        if rep < 0.0 or rep > 2.0:
            raise ConfigError(f"repetition_penalty must be between 0.0 and 2.0, got {rep}")
        api_config.repetition_penalty = float(rep)
    
    # Min P: 0.0 to 1.0
    if "min_p" in api_dict and api_dict["min_p"] is not None:
        min_p = api_dict["min_p"]
        if not isinstance(min_p, (int, float)):
            raise ConfigError(f"min_p must be a number, got {type(min_p).__name__}")
        if min_p < 0.0 or min_p > 1.0:
            raise ConfigError(f"min_p must be between 0.0 and 1.0, got {min_p}")
        api_config.min_p = float(min_p)
    
    # Top A: 0.0 to 1.0
    if "top_a" in api_dict and api_dict["top_a"] is not None:
        top_a = api_dict["top_a"]
        if not isinstance(top_a, (int, float)):
            raise ConfigError(f"top_a must be a number, got {type(top_a).__name__}")
        if top_a < 0.0 or top_a > 1.0:
            raise ConfigError(f"top_a must be between 0.0 and 1.0, got {top_a}")
        api_config.top_a = float(top_a)
    
    # Seed: integer (optional)
    if "seed" in api_dict and api_dict["seed"] is not None:
        seed = api_dict["seed"]
        if not isinstance(seed, int):
            raise ConfigError(f"seed must be an integer, got {type(seed).__name__}")
        api_config.seed = seed
    
    # Max Tokens: positive integer (optional)
    if "max_tokens" in api_dict and api_dict["max_tokens"] is not None:
        max_tokens = api_dict["max_tokens"]
        if not isinstance(max_tokens, int):
            raise ConfigError(f"max_tokens must be an integer, got {type(max_tokens).__name__}")
        if max_tokens < 1:
            raise ConfigError(f"max_tokens must be at least 1, got {max_tokens}")
        api_config.max_tokens = max_tokens
    
    # Validate reasoning settings
    if "reasoning" in api_dict and api_dict["reasoning"] is not None:
        reasoning_dict = api_dict["reasoning"]
        if not isinstance(reasoning_dict, dict):
            raise ConfigError(f"reasoning must be a mapping (dictionary), got {type(reasoning_dict).__name__}")
        
        reasoning_config = ReasoningConfig()
        
        # Enabled: boolean (enable reasoning with default settings)
        if "enabled" in reasoning_dict and reasoning_dict["enabled"] is not None:
            enabled = reasoning_dict["enabled"]
            if not isinstance(enabled, bool):
                raise ConfigError(f"reasoning.enabled must be a boolean, got {type(enabled).__name__}")
            reasoning_config.enabled = enabled
        
        # Effort: "low", "medium", or "high"
        if "effort" in reasoning_dict and reasoning_dict["effort"] is not None:
            effort = reasoning_dict["effort"]
            if not isinstance(effort, str):
                raise ConfigError(f"reasoning.effort must be a string, got {type(effort).__name__}")
            if effort not in VALID_REASONING_EFFORTS:
                raise ConfigError(
                    f"reasoning.effort must be one of {sorted(VALID_REASONING_EFFORTS)}, got '{effort}'"
                )
            reasoning_config.effort = effort
        
        # Max Tokens for reasoning: positive integer
        if "max_tokens" in reasoning_dict and reasoning_dict["max_tokens"] is not None:
            r_max_tokens = reasoning_dict["max_tokens"]
            if not isinstance(r_max_tokens, int):
                raise ConfigError(f"reasoning.max_tokens must be an integer, got {type(r_max_tokens).__name__}")
            if r_max_tokens < 1:
                raise ConfigError(f"reasoning.max_tokens must be at least 1, got {r_max_tokens}")
            reasoning_config.max_tokens = r_max_tokens
        
        # Exclude: boolean
        if "exclude" in reasoning_dict and reasoning_dict["exclude"] is not None:
            exclude = reasoning_dict["exclude"]
            if not isinstance(exclude, bool):
                raise ConfigError(f"reasoning.exclude must be a boolean, got {type(exclude).__name__}")
            reasoning_config.exclude = exclude
        
        api_config.reasoning = reasoning_config
    
    return api_config


def load_config(config_path: Union[str, Path]) -> Config:
    """Load and validate configuration from a YAML file.
    
    Args:
        config_path: Path to the configuration YAML file.
        
    Returns:
        Validated Config object.
        
    Raises:
        ConfigError: If configuration is invalid.
        FileNotFoundError: If config file doesn't exist.
    """
    config_path = Path(config_path)
    project_root = config_path.parent
    
    if not config_path.exists():
        raise FileNotFoundError(f"Configuration file not found: {config_path}")
    
    with open(config_path, 'r', encoding='utf-8') as f:
        raw_config = yaml.safe_load(f)
    
    if not isinstance(raw_config, dict):
        raise ConfigError("Configuration file must contain a YAML mapping (dictionary).")
    
    # Validate required fields
    if "models" not in raw_config:
        raise ConfigError("Configuration must include 'models' field.")
    
    models = raw_config["models"]
    if not isinstance(models, list) or not models:
        raise ConfigError("'models' must be a non-empty list of model IDs.")
    
    for model_id in models:
        _validate_model_id(model_id)
    
    # Validate challenges
    challenges = raw_config.get("challenges", "all")
    _validate_challenges(challenges)
    
    # Validate exclude_challenges
    exclude_challenges = raw_config.get("exclude_challenges", [])
    if exclude_challenges is None:
        exclude_challenges = []
    _validate_exclude_challenges(exclude_challenges)
    
    # Validate API config
    api_dict = raw_config.get("api", {})
    if not isinstance(api_dict, dict):
        raise ConfigError("'api' must be a mapping (dictionary).")
    api_config = _validate_api_config(api_dict)
    
    # Validate system prompt
    system_prompt = raw_config.get("system_prompt", "")
    if not system_prompt or not isinstance(system_prompt, str):
        raise ConfigError("Configuration must include a non-empty 'system_prompt' field.")
    
    # Create config object
    config = Config(
        models=models,
        challenges=challenges,
        exclude_challenges=exclude_challenges,
        openscad_path=raw_config.get("openscad_path", "openscad"),
        api=api_config,
    )
    config._project_root = project_root
    config._system_prompt = system_prompt.strip()
    
    return config


def load_api_key(config: Config) -> None:
    """Load the API key from environment variable.
    
    Args:
        config: Configuration object to store the API key.
        
    Raises:
        ConfigError: If OPENROUTER_API_KEY environment variable is not set.
    """
    load_dotenv()
    api_key = os.environ.get("OPENROUTER_API_KEY")
    
    if not api_key:
        raise ConfigError(
            "OPENROUTER_API_KEY environment variable is not set. "
            "Please set it to your OpenRouter API key."
        )
    
    config._api_key = api_key


def validate_openscad_path(config: Config) -> bool:
    """Check if the OpenSCAD executable exists.
    
    Args:
        config: Configuration object with openscad_path set.
        
    Returns:
        True if OpenSCAD is found, False otherwise.
    """
    openscad_path = config.openscad_path
    
    # Check if it's an absolute path that exists
    if Path(openscad_path).is_file():
        return True
    
    # Check if it's in PATH
    return shutil.which(openscad_path) is not None


def get_config(config_path: Union[str, Path] = "config.yaml") -> Config:
    """Load and fully initialize configuration.
    
    This is the main entry point for loading configuration. It:
    1. Loads and validates the YAML config (including system prompt)
    2. Loads the API key from environment
    3. Warns if OpenSCAD is not found
    
    Args:
        config_path: Path to the configuration YAML file.
        
    Returns:
        Fully initialized Config object.
        
    Raises:
        ConfigError: If configuration is invalid.
        FileNotFoundError: If config file doesn't exist.
    """
    import warnings
    
    config = load_config(config_path)
    load_api_key(config)
    
    if not validate_openscad_path(config):
        warnings.warn(
            f"OpenSCAD executable not found at '{config.openscad_path}'. "
            "Rendering will fail unless the path is corrected.",
            UserWarning
        )
    
    return config