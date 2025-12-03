# Tests for Reference Image Support

This test suite verifies that `reference.png` files are correctly detected and sent to the API when present in challenge directories.

## Test Coverage

The tests verify:

1. **Challenge Discovery**: Challenges with `reference.png` are correctly detected
2. **API Payload Structure**: When a reference image exists, it's included in the API payload as base64-encoded data
3. **Image Encoding**: Reference images are correctly base64 encoded with proper MIME type (`data:image/png;base64,...`)
4. **Message Content Structure**: Images are included in the user message content as a list with text and image parts
5. **Backward Compatibility**: Challenges without `reference.png` continue to work normally with text-only prompts

## Running Tests

```bash
# Run all reference image tests
pytest tests/test_reference_image.py -v

# Run with coverage
pytest tests/test_reference_image.py --cov=src --cov-report=html
```

## Test Structure

- `test_challenge_with_reference_png_detected`: Verifies challenges with reference.png are discovered
- `test_challenge_without_reference_png`: Verifies challenges without reference.png work normally
- `test_api_payload_includes_reference_image_when_present`: Verifies API payload includes image when present
- `test_api_payload_without_reference_image`: Verifies API payload works without images
- `test_reference_image_base64_encoding`: Verifies correct base64 encoding
- `test_multiple_challenges_mixed_reference_images`: Tests discovery of mixed challenges
- `test_reference_image_in_user_message_content_structure`: Verifies correct message structure
- `test_reference_image_mime_type`: Verifies correct MIME type
- `test_payload_structure_with_and_without_reference`: Parametrized test for both cases
- `test_challenge_reference_image_path_exists`: Verifies path checking
- `test_challenge_reference_image_not_required`: Verifies optional nature
- `test_reference_image_data_integrity`: Verifies data integrity through encoding

## Expected Behavior

When a challenge has `reference.png`:
- The image should be detected during challenge discovery
- The image should be loaded and base64 encoded
- The API payload should include the image in the user message content as:
  ```python
  [
      {"type": "text", "text": "prompt text"},
      {
          "type": "image_url",
          "image_url": {
              "url": "data:image/png;base64,<base64_encoded_data>"
          }
      }
  ]
  ```

When a challenge does NOT have `reference.png`:
- The API payload should use a simple string for user message content
- No image-related processing should occur

