## Layers: PyTorch, ML APIs and algorithm programs (Python)

| Role | Paths | Pattern | Check |
| --- | --- | --- | --- |
| component | `src/<pkg>/models/`, `src/<pkg>/transforms/`, `src/<pkg>/features/`, `src/<pkg>/schemas/` | `nn.Module` subclasses, pure transforms and feature functions, Pydantic request/response models | `ruff format <files> && ruff check <files> && pyright <files>` plus a CPU forward pass on a random tensor of the contract shape |
| logic | `src/<pkg>/train/`, `src/<pkg>/eval/`, `src/<pkg>/losses.py`, `src/<pkg>/metrics.py`, `src/<pkg>/algorithms/`, `src/<pkg>/inference.py` | Training/eval loops, losses, metrics, algorithms, pre/post-processing | `ruff format <files> && ruff check <files> && pyright <files>` |
| wiring | `configs/`, `scripts/` or `train.py` entrypoints, `src/<pkg>/api/` (FastAPI routers), model registry loading | Config, CLI and endpoint registration that call logic | `ruff check . && pyright` |

**Contract format:** typed signatures with shapes and dtypes (jaxtyping, or a shape comment if the project does not use it), config keys, API models.
```python
class Encoder(nn.Module):
    def forward(self, x: Float[Tensor, "B C H W"]) -> Float[Tensor, "B D"]: ...
def train_one_epoch(model, loader, optim, *, grad_clip: float | None) -> dict[str, float]: ...  # keys: loss, acc
# configs/model/encoder.yaml: { channels: int, dim: int, dropout: float }
# POST /predict  PredictRequest{ image_b64: str } -> PredictResponse{ label: str, score: float }
```

**Component rules:** device-agnostic (no `.cuda()`; take the device from inputs); shapes documented in signatures; no I/O, logging or randomness inside modules except declared dropout; parameters initialized as the contract says.
**Logic rules:** seed every RNG from config; `model.eval()` and `torch.inference_mode()` for evaluation and inference; no train/validation/test leakage (fit scalers and vocabularies on train only); numerically stable forms (`log_softmax`, `logsumexp`, epsilon in divisions); mixed precision and gradient clipping only where the contract says; metrics computed over the whole split, not averaged per batch unless specified; algorithms state their time and space complexity in the docstring.
**Wiring rules:** load the model once at startup, not per request; endpoints validate with the schema, call one inference function and map errors to status codes; configs hold values only.
**Integration check (tester):** `pytest <paths>`, then a one-batch smoke run (`python train.py trainer.fast_dev_run=1` or the project's equivalent), then `uvicorn` startup plus one `/predict` request for API projects.
**Model note for the PM:** new algorithms, loss functions and anything numerically delicate go to logic-builder at `effort: high`, or to opus.

### QA: PyTorch / ML / algorithms
- **Levels and paths:** unit `tests/unit/` (modules, transforms, losses, metrics, algorithms) · shape `tests/shapes/` (forward pass on the contract shapes, CPU) · property `tests/property/` with Hypothesis for algorithms and transforms (invariants, not examples) · integration `tests/integration/` (one-batch train step, API round trip with `TestClient`) · regression `tests/regression/` (frozen small model or golden outputs with tolerances).
- **Required case kinds:** shapes and dtypes; gradient flows (`loss.backward()` gives finite, non-zero grads on trainable params); overfit one tiny batch (loss decreases); determinism with a fixed seed; eval mode disables dropout; metrics against a hand-computed example; algorithm edge cases (empty, single element, duplicates, max size) and complexity on a size sweep only if the contract states one.
- **Doubles:** tiny synthetic datasets in fixtures; no downloads; models built with the smallest config.
- **Commands:** narrow `pytest <paths> -q` · full `pytest -q` · static `ruff check . && pyright` · per-test coverage `pytest <paths> --cov=<pkg> --cov-context=test --cov-report=` then `coverage json --show-contexts` (optimizer may use it).
- **Flakiness:** unseeded RNG, GPU nondeterminism (compare with `torch.testing.assert_close` and tolerances), tests that depend on hardware; mark GPU-only tests and skip them on CPU runners.
