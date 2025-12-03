# Contributing to OpenSCAD Bench

This project relies on community contributions to grow. There are two main ways to contribute:

1. **Add Model Results**: Run the benchmark with models/configurations that haven't been tested yet
2. **Add New Challenges**: Create new real-world problems to test

## Quick Start: Running the Benchmark

Before contributing, you'll need to run the benchmark locally:

### Prerequisites

1. **Python 3.10+** with dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. **OpenSCAD** installed locally ([download here](https://openscad.org/downloads.html))

3. **OpenRouter API Key**: Get one at [openrouter.ai](https://openrouter.ai) and set it:
   ```bash
   export OPENROUTER_API_KEY=your_key_here
   # Or create a .env file with: OPENROUTER_API_KEY=your_key_here
   ```

### Running Benchmarks

1. Edit [`config.yaml`](config.yaml) to specify which models to test:
   ```yaml
   models:
     - openai/gpt-5.1
     - anthropic/claude-sonnet-4.5
   ```

2. Run the benchmark:
   ```bash
   python -m main
   ```

3. Results are saved to `challenges/[challenge-name]/models/[model-name]/`

---

## 1. Adding Model/Configuration Results

Help expand our coverage by testing models or configurations that haven't been benchmarked yet.

### What to Contribute

- **New models**: Models not yet tested on existing challenges
- **New configurations**: Different parameter settings (temperature, reasoning effort, etc.)

### How to Contribute Results

1. **Configure your run** in [`config.yaml`](config.yaml):
   ```yaml
   models:
     - your-provider/model-name
   
   # Optional: Test with non-default parameters
   api:
     temperature: 0.7
     # See config.yaml for all available parameters
   ```

2. **Run the benchmark**:
   ```bash
   python -m main
   ```

3. **Review the results** in `challenges/*/models/your-model-name/`:
   - `attempt.scad` - Generated OpenSCAD code
   - `output.stl` - Rendered 3D model (if successful)
   - `params.json` - Configuration used for this run

4. **Create a Pull Request** with your results

---

## 2. Adding a New Challenge

A good challenge is a real-world problem that requires spatial reasoning. It shouldn't be purely abstract art; it should have functional requirements (dimensions, fit, etc.).

**Ideal challenges are problems that current SOTA models struggle to solve.** If every model aces it on the first try, it's not pushing the boundaries of what we're testing.

### Creating the Challenge

1. Create a new folder in `challenges/` with a descriptive name (e.g., `challenges/headphone-hook`)

2. Copy `challenges/TEMPLATE.md` to `challenges/your-challenge/README.md`

3. Create a `prompt.md` file containing **only** the exact text you would paste into an LLM

4. Fill out the README with:
   - **Success Criteria**: Specific things to check (e.g., "Must fit a 25mm desk")
   - **Skills Tested**: Tags like `boolean-ops`, `parametric`, `threads`, etc.

5. (Optional) Add a `reference.png` if visual context is helpful

### Required: Include Baseline Results

When submitting a new challenge, **please include benchmark results from current SOTA models** from each major provider. This establishes a baseline for comparison and ensures the challenge is well-tested.

**Run your challenge against the latest flagship model from each provider:**
- OpenAI
- Anthropic
- Google
- xAI

Check [OpenRouter's model list](https://openrouter.ai/models) for current model identifiers.

This helps the community by:
- Validating that the challenge prompt is clear and achievable
- Providing immediate comparison data
- Showing which models handle the challenge well (or poorly)

---

## Pull Request Guidelines

### For Model Results

1. **Title format**: `results: [model-name] on [challenge(s)]`
2. **Include**: Brief notes on any interesting observations
3. **Don't modify**: Existing results from other contributors

### For New Challenges

1. **Title format**: `challenge: [challenge-name]`
2. **Include**:
   - The challenge files (README.md, prompt.md)
   - Baseline results from SOTA models (see above)
   - Any reference images if helpful

---

## General Guidelines

- **Honesty**: Don't cherry-pick the one good result out of 50 tries. If a model fails, that's valuable data too!
- **Reproducibility**: The `params.json` file documents your exact configuration. Don't modify it manually.
- **One PR per contribution**: Keep model results and new challenges in separate PRs