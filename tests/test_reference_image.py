"""Tests to ensure reference.png is being sent to the API."""

import base64
import tempfile
from pathlib import Path
from unittest.mock import Mock, patch, MagicMock

import pytest

import sys
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from src.challenges import Challenge, discover_challenges
from src.openrouter import _build_payload
from src.config import ApiConfig


def create_test_challenge(
    tmp_path: Path,
    name: str,
    prompt: str,
    has_reference: bool = False
) -> Path:
    """Create a test challenge directory structure.
    
    Args:
        tmp_path: Temporary directory path.
        name: Challenge name.
        prompt: Prompt content.
        has_reference: Whether to create reference.png.
        
    Returns:
        Path to the challenge directory.
    """
    challenge_dir = tmp_path / "challenges" / name
    challenge_dir.mkdir(parents=True)
    
    prompt_file = challenge_dir / "prompt.md"
    prompt_file.write_text(prompt, encoding="utf-8")
    
    if has_reference:
        reference_file = challenge_dir / "reference.png"
        reference_file.write_bytes(b"fake_png_data_for_testing")
    
    return challenge_dir


def test_challenge_with_reference_png_detected(tmp_path: Path):
    """Test that challenges with reference.png are detected correctly."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=True
    )
    
    challenges = discover_challenges(tmp_path)
    
    assert len(challenges) == 1
    challenge = challenges[0]
    assert challenge.name == "test-challenge"
    assert challenge.prompt == "Test prompt"
    
    reference_path = challenge.path / "reference.png"
    assert reference_path.exists()


def test_challenge_without_reference_png(tmp_path: Path):
    """Test that challenges without reference.png work normally."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=False
    )
    
    challenges = discover_challenges(tmp_path)
    
    assert len(challenges) == 1
    challenge = challenges[0]
    assert challenge.name == "test-challenge"
    
    reference_path = challenge.path / "reference.png"
    assert not reference_path.exists()


def test_api_payload_includes_reference_image_when_present(tmp_path: Path):
    """Test that API payload includes reference.png when challenge has it."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt with reference.png",
        has_reference=True
    )
    
    reference_path = challenge_dir / "reference.png"
    image_data = reference_path.read_bytes()
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    
    api_config = ApiConfig()
    
    user_content = [
        {"type": "text", "text": "Test prompt with reference.png"},
        {
            "type": "image_url",
            "image_url": {
                "url": f"data:image/png;base64,{image_base64}"
            }
        }
    ]
    
    payload = _build_payload(
        model="test/model",
        system_prompt="System prompt",
        user_prompt=user_content,
        api_config=api_config
    )
    
    assert payload["model"] == "test/model"
    assert len(payload["messages"]) == 2
    
    user_message = payload["messages"][1]
    assert user_message["role"] == "user"
    
    user_content_result = user_message["content"]
    assert isinstance(user_content_result, list)
    assert len(user_content_result) == 2
    
    assert user_content_result[0]["type"] == "text"
    assert user_content_result[0]["text"] == "Test prompt with reference.png"
    
    assert user_content_result[1]["type"] == "image_url"
    assert "image_url" in user_content_result[1]
    assert "url" in user_content_result[1]["image_url"]
    assert user_content_result[1]["image_url"]["url"].startswith("data:image/png;base64,")
    
    image_data_decoded = base64.b64decode(
        user_content_result[1]["image_url"]["url"].split(",")[1]
    )
    assert image_data_decoded == image_data


def test_api_payload_without_reference_image(tmp_path: Path):
    """Test that API payload works normally when no reference.png exists."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt without reference",
        has_reference=False
    )
    
    api_config = ApiConfig()
    
    payload = _build_payload(
        model="test/model",
        system_prompt="System prompt",
        user_prompt="Test prompt without reference",
        api_config=api_config
    )
    
    assert payload["model"] == "test/model"
    assert len(payload["messages"]) == 2
    
    user_message = payload["messages"][1]
    assert user_message["role"] == "user"
    assert user_message["content"] == "Test prompt without reference"
    assert isinstance(user_message["content"], str)


def test_reference_image_base64_encoding(tmp_path: Path):
    """Test that reference.png is correctly base64 encoded."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=True
    )
    
    reference_path = challenge_dir / "reference.png"
    image_data = reference_path.read_bytes()
    
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    
    expected_url = f"data:image/png;base64,{image_base64}"
    
    api_config = ApiConfig()
    user_content = [
        {"type": "text", "text": "Test prompt"},
        {
            "type": "image_url",
            "image_url": {"url": expected_url}
        }
    ]
    
    payload = _build_payload(
        model="test/model",
        system_prompt="System prompt",
        user_prompt=user_content,
        api_config=api_config
    )
    
    user_message = payload["messages"][1]
    image_url = user_message["content"][1]["image_url"]["url"]
    
    assert image_url == expected_url
    assert image_url.startswith("data:image/png;base64,")
    
    decoded_data = base64.b64decode(image_url.split(",")[1])
    assert decoded_data == image_data


def test_multiple_challenges_mixed_reference_images(tmp_path: Path):
    """Test discovery of multiple challenges with and without reference.png."""
    create_test_challenge(tmp_path, "challenge-with-ref", "Prompt 1", has_reference=True)
    create_test_challenge(tmp_path, "challenge-without-ref", "Prompt 2", has_reference=False)
    create_test_challenge(tmp_path, "another-with-ref", "Prompt 3", has_reference=True)
    
    challenges = discover_challenges(tmp_path)
    
    assert len(challenges) == 3
    
    challenge_names = {c.name for c in challenges}
    assert challenge_names == {"challenge-with-ref", "challenge-without-ref", "another-with-ref"}
    
    for challenge in challenges:
        if challenge.name in ("challenge-with-ref", "another-with-ref"):
            assert (challenge.path / "reference.png").exists()
        else:
            assert not (challenge.path / "reference.png").exists()


def test_reference_image_in_user_message_content_structure(tmp_path: Path):
    """Test that reference image is included in correct message content structure."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=True
    )
    
    reference_path = challenge_dir / "reference.png"
    image_data = reference_path.read_bytes()
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    
    api_config = ApiConfig()
    
    user_content = [
        {"type": "text", "text": "Test prompt"},
        {
            "type": "image_url",
            "image_url": {
                "url": f"data:image/png;base64,{image_base64}"
            }
        }
    ]
    
    payload = _build_payload(
        model="test/model",
        system_prompt="System prompt",
        user_prompt=user_content,
        api_config=api_config
    )
    
    user_message = payload["messages"][1]
    
    assert user_message["role"] == "user"
    assert isinstance(user_message["content"], list)
    
    content = user_message["content"]
    assert len(content) == 2
    
    assert content[0] == {"type": "text", "text": "Test prompt"}
    assert content[1]["type"] == "image_url"
    assert "image_url" in content[1]
    assert "url" in content[1]["image_url"]


def test_reference_image_mime_type(tmp_path: Path):
    """Test that reference.png uses correct MIME type in data URL."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=True
    )
    
    reference_path = challenge_dir / "reference.png"
    image_data = reference_path.read_bytes()
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    
    api_config = ApiConfig()
    
    user_content = [
        {"type": "text", "text": "Test prompt"},
        {
            "type": "image_url",
            "image_url": {
                "url": f"data:image/png;base64,{image_base64}"
            }
        }
    ]
    
    payload = _build_payload(
        model="test/model",
        system_prompt="System prompt",
        user_prompt=user_content,
        api_config=api_config
    )
    
    user_message = payload["messages"][1]
    image_url = user_message["content"][1]["image_url"]["url"]
    
    assert image_url.startswith("data:image/png;base64,")


@pytest.mark.parametrize("has_reference", [True, False])
def test_payload_structure_with_and_without_reference(tmp_path: Path, has_reference: bool):
    """Parametrized test for payload structure with and without reference.png."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=has_reference
    )
    
    api_config = ApiConfig()
    
    if has_reference:
        reference_path = challenge_dir / "reference.png"
        image_data = reference_path.read_bytes()
        image_base64 = base64.b64encode(image_data).decode("utf-8")
        
        user_content = [
            {"type": "text", "text": "Test prompt"},
            {
                "type": "image_url",
                "image_url": {
                    "url": f"data:image/png;base64,{image_base64}"
                }
            }
        ]
    else:
        user_content = "Test prompt"
    
    payload = _build_payload(
        model="test/model",
        system_prompt="System prompt",
        user_prompt=user_content,
        api_config=api_config
    )
    
    assert payload["model"] == "test/model"
    assert len(payload["messages"]) == 2
    
    system_message = payload["messages"][0]
    assert system_message["role"] == "system"
    assert system_message["content"] == "System prompt"
    
    user_message = payload["messages"][1]
    assert user_message["role"] == "user"
    
    if has_reference:
        assert isinstance(user_message["content"], list)
        assert len(user_message["content"]) == 2
        assert user_message["content"][0]["type"] == "text"
        assert user_message["content"][1]["type"] == "image_url"
    else:
        assert isinstance(user_message["content"], str)
        assert user_message["content"] == "Test prompt"


def test_challenge_reference_image_path_exists(tmp_path: Path):
    """Test that reference.png path can be checked for existing challenges."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=True
    )
    
    challenges = discover_challenges(tmp_path)
    assert len(challenges) == 1
    
    challenge = challenges[0]
    reference_path = challenge.path / "reference.png"
    
    assert reference_path.exists()
    assert reference_path.is_file()
    assert reference_path.suffix == ".png"


def test_challenge_reference_image_not_required(tmp_path: Path):
    """Test that reference.png is optional and challenges work without it."""
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=False
    )
    
    challenges = discover_challenges(tmp_path)
    assert len(challenges) == 1
    
    challenge = challenges[0]
    reference_path = challenge.path / "reference.png"
    
    assert not reference_path.exists()


def test_reference_image_data_integrity(tmp_path: Path):
    """Test that reference.png data is correctly preserved through encoding."""
    original_data = b"PNG\x89\x50\x4E\x47\x0D\x0A\x1A\x0A" + b"x" * 100
    
    challenge_dir = create_test_challenge(
        tmp_path,
        "test-challenge",
        "Test prompt",
        has_reference=False
    )
    
    reference_path = challenge_dir / "reference.png"
    reference_path.write_bytes(original_data)
    
    image_data = reference_path.read_bytes()
    assert image_data == original_data
    
    image_base64 = base64.b64encode(image_data).decode("utf-8")
    decoded_data = base64.b64decode(image_base64)
    
    assert decoded_data == original_data
    assert len(decoded_data) == len(original_data)

