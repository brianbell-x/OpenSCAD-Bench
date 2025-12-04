"""OpenRouter API client for sending prompts and extracting code responses."""

import json
import re
from typing import Callable, Generator, Optional, Union

import requests

try:
    from config import ApiConfig
except ImportError:
    from .config import ApiConfig


class OpenRouterError(Exception):
    """Base exception for OpenRouter API errors."""
    
    def __init__(self, message: str, model: str, status_code: Optional[int] = None):
        self.model = model
        self.status_code = status_code
        super().__init__(f"[{model}] {message}")


class AuthenticationError(OpenRouterError):
    """Raised when API authentication fails."""
    pass


class RateLimitError(OpenRouterError):
    """Raised when rate limit is exceeded."""
    pass


class ModelNotFoundError(OpenRouterError):
    """Raised when the requested model is not found."""
    pass


class ContentFilterError(OpenRouterError):
    """Raised when content is filtered by the model."""
    pass


def _build_payload(
    model: str,
    system_prompt: str,
    user_prompt: Union[str, list],
    api_config: ApiConfig
) -> dict:
    """Build the API request payload.
    
    Args:
        model: The model ID (e.g., 'openai/gpt-4o').
        system_prompt: The system prompt to set context.
        user_prompt: The user's prompt/request. Can be a string or a list
            containing text and image content parts.
        api_config: API configuration settings (includes LLM parameters).
        
    Returns:
        The payload dictionary for the API request.
    """
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt},
        ],
    }
    
    # Add LLM parameters if configured
    if api_config.temperature is not None:
        payload["temperature"] = api_config.temperature
    if api_config.top_p is not None:
        payload["top_p"] = api_config.top_p
    if api_config.top_k is not None:
        payload["top_k"] = api_config.top_k
    if api_config.frequency_penalty is not None:
        payload["frequency_penalty"] = api_config.frequency_penalty
    if api_config.presence_penalty is not None:
        payload["presence_penalty"] = api_config.presence_penalty
    if api_config.repetition_penalty is not None:
        payload["repetition_penalty"] = api_config.repetition_penalty
    if api_config.min_p is not None:
        payload["min_p"] = api_config.min_p
    if api_config.top_a is not None:
        payload["top_a"] = api_config.top_a
    if api_config.seed is not None:
        payload["seed"] = api_config.seed
    if api_config.max_tokens is not None:
        payload["max_tokens"] = api_config.max_tokens
    
    # Add reasoning settings if configured
    if api_config.reasoning is not None:
        reasoning_dict = api_config.reasoning.to_api_dict()
        if reasoning_dict:
            payload["reasoning"] = reasoning_dict
    
    return payload


def _get_headers(api_key: str) -> dict:
    """Get the standard headers for API requests.
    
    Args:
        api_key: OpenRouter API key.
        
    Returns:
        Headers dictionary.
    """
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": "https://github.com/openscad-bench",
        "X-Title": "OpenSCAD Bench",
    }


def _handle_http_error(response: requests.Response, model: str) -> None:
    """Handle HTTP error responses.
    
    Args:
        response: The HTTP response object.
        model: The model ID for error messages.
        
    Raises:
        AuthenticationError: If API key is invalid.
        RateLimitError: If rate limit is exceeded.
        ModelNotFoundError: If the model doesn't exist.
        OpenRouterError: For other API errors.
    """
    if response.status_code == 401:
        raise AuthenticationError(
            "Invalid API key or authentication failed",
            model=model,
            status_code=401
        )
    elif response.status_code == 429:
        raise RateLimitError(
            "Rate limit exceeded. Please wait before retrying.",
            model=model,
            status_code=429
        )
    elif response.status_code == 404:
        raise ModelNotFoundError(
            f"Model not found: {model}",
            model=model,
            status_code=404
        )
    elif response.status_code >= 400:
        # Try to extract error message from response
        try:
            error_data = response.json()
            error_msg = error_data.get("error", {}).get("message", response.text)
        except (ValueError, KeyError):
            error_msg = response.text
        
        raise OpenRouterError(
            f"API error ({response.status_code}): {error_msg}",
            model=model,
            status_code=response.status_code
        )


def _check_response_error(data: dict, model: str) -> None:
    """Check for errors in the response body.
    
    Args:
        data: The parsed response data.
        model: The model ID for error messages.
        
    Raises:
        ContentFilterError: If content is filtered.
        OpenRouterError: For other API errors.
    """
    if "error" in data:
        error_info = data["error"]
        error_msg = error_info.get("message", str(error_info))
        error_code = error_info.get("code")
        
        # Check for content filter
        if error_code == "content_filter" or "content" in error_msg.lower():
            raise ContentFilterError(error_msg, model=model)
        
        raise OpenRouterError(error_msg, model=model)


def send_prompt_streaming(
    model: str,
    system_prompt: str,
    user_prompt: Union[str, list],
    api_config: ApiConfig,
    api_key: str,
    silent: bool = False,
    on_activity: Optional[Callable[[], None]] = None
) -> dict:
    """Send a streaming chat completion request to OpenRouter.
    
    Streams the response to stdout in real-time and accumulates the full response.
    
    Args:
        model: The model ID (e.g., 'openai/gpt-4o').
        system_prompt: The system prompt to set context.
        user_prompt: The user's prompt/request.
        api_config: API configuration settings (includes LLM parameters).
        api_key: OpenRouter API key.
        silent: If True, do not print content to stdout (for parallel execution).
        on_activity: Optional callback called when chunks are received (for UI updates).
        
    Returns:
        The full response dictionary from the API (reconstructed from stream).
        
    Raises:
        AuthenticationError: If API key is invalid.
        RateLimitError: If rate limit is exceeded.
        ModelNotFoundError: If the model doesn't exist.
        ContentFilterError: If content is filtered.
        OpenRouterError: For other API errors.
    """
    import logging
    logger = logging.getLogger(__name__)
    
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = _get_headers(api_key)
    payload = _build_payload(model, system_prompt, user_prompt, api_config)
    payload["stream"] = True
    
    accumulated_content = ""
    accumulated_reasoning = ""
    response_id = None
    response_model = None
    finish_reason = None
    first_chunk_received = False
    processing_logged = False
    
    try:
        with requests.post(
            url,
            headers=headers,
            json=payload,
            timeout=api_config.timeout,
            stream=True
        ) as response:
            # Handle HTTP errors before streaming
            _handle_http_error(response, model)
            
            buffer = ""
            for chunk in response.iter_content(chunk_size=1024, decode_unicode=True):
                if chunk:
                    if not first_chunk_received:
                        logger.debug("First chunk received from API")
                        first_chunk_received = True
                    buffer += chunk
                    
                    # Process complete lines in the buffer
                    while True:
                        line_end = buffer.find('\n')
                        if line_end == -1:
                            break
                        
                        line = buffer[:line_end].strip()
                        buffer = buffer[line_end + 1:]
                        
                        # Skip empty lines
                        if not line:
                            continue
                        
                        # Handle SSE comments (like ": OPENROUTER PROCESSING")
                        # Show user feedback that processing is happening
                        if line.startswith(':'):
                            if not processing_logged:
                                logger.info("Waiting for model to process...")
                                processing_logged = True
                            continue
                        
                        # Process data lines
                        if line.startswith('data: '):
                            data = line[6:]
                            
                            # Check for end of stream
                            if data == '[DONE]':
                                break
                            
                            try:
                                data_obj = json.loads(data)
                                
                                # Capture response metadata
                                if response_id is None and "id" in data_obj:
                                    response_id = data_obj["id"]
                                if response_model is None and "model" in data_obj:
                                    response_model = data_obj["model"]
                                
                                # Extract content from delta
                                choices = data_obj.get("choices", [])
                                if choices:
                                    delta = choices[0].get("delta", {})
                                    content = delta.get("content")
                                    if content:
                                        if not silent:
                                            print(content, end="", flush=True)
                                        accumulated_content += content
                                        if on_activity:
                                            on_activity()
                                    
                                    # Capture reasoning content (for models like o-series, Claude 3.7+, DeepSeek R1)
                                    reasoning = delta.get("reasoning")
                                    if reasoning:
                                        accumulated_reasoning += reasoning
                                        if on_activity:
                                            on_activity()
                                    
                                    # Capture finish reason
                                    fr = choices[0].get("finish_reason")
                                    if fr:
                                        finish_reason = fr
                                        
                            except json.JSONDecodeError:
                                # Skip malformed JSON chunks
                                pass
                    
    except requests.Timeout:
        raise OpenRouterError(
            f"Request timed out after {api_config.timeout} seconds",
            model=model
        )
    except requests.RequestException as e:
        raise OpenRouterError(f"Request failed: {e}", model=model)
    
    # Construct a response dict that matches the non-streaming format
    # This ensures extract_code() works with both streaming and non-streaming responses
    message_dict = {
        "role": "assistant",
        "content": accumulated_content
    }
    
    # Add reasoning fields only if they have content
    if accumulated_reasoning:
        message_dict["reasoning"] = accumulated_reasoning
    
    reconstructed_response = {
        "id": response_id or "stream-response",
        "model": response_model or model,
        "choices": [
            {
                "message": message_dict,
                "finish_reason": finish_reason or "stop"
            }
        ]
    }
    
    return reconstructed_response


def send_prompt(
    model: str,
    system_prompt: str,
    user_prompt: Union[str, list],
    api_config: ApiConfig,
    api_key: str
) -> dict:
    """Send a non-streaming chat completion request to OpenRouter.
    
    Note: For parallel execution, use send_prompt_streaming() directly
    with silent=True, which is what the parallel runner does.
    
    Args:
        model: The model ID (e.g., 'openai/gpt-4o').
        system_prompt: The system prompt to set context.
        user_prompt: The user's prompt/request.
        api_config: API configuration settings (includes LLM parameters).
        api_key: OpenRouter API key.
        
    Returns:
        The full response dictionary from the API.
        
    Raises:
        AuthenticationError: If API key is invalid.
        RateLimitError: If rate limit is exceeded.
        ModelNotFoundError: If the model doesn't exist.
        ContentFilterError: If content is filtered.
        OpenRouterError: For other API errors.
    """
    url = "https://openrouter.ai/api/v1/chat/completions"
    headers = _get_headers(api_key)
    payload = _build_payload(model, system_prompt, user_prompt, api_config)
    
    try:
        response = requests.post(
            url,
            headers=headers,
            json=payload,
            timeout=api_config.timeout,
        )
    except requests.Timeout:
        raise OpenRouterError(
            f"Request timed out after {api_config.timeout} seconds",
            model=model
        )
    except requests.RequestException as e:
        raise OpenRouterError(f"Request failed: {e}", model=model)
    
    # Handle HTTP errors
    _handle_http_error(response, model)
    
    # Parse response
    try:
        data = response.json()
    except ValueError as e:
        raise OpenRouterError(f"Invalid JSON response: {e}", model=model)
    
    # Check for error in response body (some errors come with 200 status)
    _check_response_error(data, model)
    
    # Remove reasoning_details from response if present
    if "choices" in data:
        for choice in data["choices"]:
            if "message" in choice and "reasoning_details" in choice["message"]:
                del choice["message"]["reasoning_details"]
    
    return data


def extract_code(response: dict) -> str:
    """Extract OpenSCAD code from the API response.
    
    Handles cases where the model wraps code in markdown fences
    (```openscad ... ``` or ``` ... ```).
    
    Args:
        response: The full response dictionary from send_prompt().
        
    Returns:
        The raw OpenSCAD code string.
        
    Raises:
        ValueError: If no content could be extracted from the response.
    """
    # Extract content from response
    try:
        choices = response.get("choices", [])
        if not choices:
            raise ValueError("Response contains no choices")
        
        message = choices[0].get("message", {})
        content = message.get("content")
        
        if content is None:
            raise ValueError("Response message has no content")
    except (KeyError, IndexError, TypeError) as e:
        raise ValueError(f"Failed to extract content from response: {e}")
    
    # Strip markdown code fences if present
    code = _strip_markdown_fences(content)
    
    return code


def _strip_markdown_fences(content: str) -> str:
    """Strip markdown code fences from content.
    
    Handles:
    - ```openscad ... ```
    - ```scad ... ```
    - ``` ... ```
    - Multiple code blocks (extracts all and joins)
    
    Args:
        content: The raw content string.
        
    Returns:
        Content with markdown fences removed.
    """
    content = content.strip()
    
    # Pattern to match code blocks with optional language specifier
    # Matches ```openscad, ```scad, or just ```
    pattern = r'```(?:openscad|scad)?\s*\n?(.*?)```'
    
    matches = re.findall(pattern, content, re.DOTALL | re.IGNORECASE)
    
    if matches:
        # If we found code blocks, join them (in case of multiple blocks)
        return '\n\n'.join(match.strip() for match in matches)
    
    # No code blocks found, return content as-is
    # But still check for single-line backticks
    if content.startswith('`') and content.endswith('`'):
        return content[1:-1].strip()
    
    return content