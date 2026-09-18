# AI Workflow Rules

## Approach

Build this project incrementally using a spec-driven workflow. Context files (`project-overview.md`, `architecture.md`, `ui-context.md`, `code-standards.md`, and `progress-tracker.md`) define what to build, how to build it, and the current state of progress. Always implement directly against these specification files—do not infer or invent product behavior from scratch.

## Scoping Rules

- Work on one feature unit or single system boundary at a time.
- Prefer small, verifiable increments over large speculative changes.
- Do not combine unrelated system boundaries in a single implementation step.

## When to Split Work

Split an implementation step if it combines:

- Client UI changes and backend AI pipeline orchestrator changes.
- Camera hardware integration and REST API client routing.
- Database schema migrations and ONNX inference runtime initialization.
- Behavior or outputs not clearly defined in the context files.

If a change cannot be verified end-to-end quickly, the scope is too broad—split it into smaller, isolated steps.

## Handling Missing Requirements

- Do not invent product behavior or model cascade parameters not explicitly defined in the context files.
- If a requirement is ambiguous (e.g., specific classification grading scale), resolve it in the relevant context file before implementing.
- If a requirement is missing, add it as an open question in `progress-tracker.md` before continuing.

## Protected Files

Do not modify the following unless explicitly instructed:

- `lib/core/theme/` — Generated theme tokens derived from `ui-context.md`.
- `app/models/weights/*` — Pre-trained binary weights for Stage A, Stage B, and Stage C models.
- Core third-party library internals (`flutter_hooks`, `onnxruntime`, `pydantic`).

## Keeping Docs in Sync

Update the relevant context file whenever implementation changes:

- System architecture, 3-model backend execution logic, or boundary responsibilities (`architecture.md`).
- Storage model decisions or API schema shifts (`architecture.md` / `code-standards.md`).
- UI tokens, color variables, or component standards (`ui-context.md`).
- Feature scope, in-scope parameters, or out-of-scope boundaries (`project-overview.md`).

## Before Moving to the Next Unit

1. The current unit works end-to-end within its defined scope without breaking dependencies.
2. No invariant defined in `architecture.md` was violated.
3. `progress-tracker.md` accurately reflects the completed work, session notes, and next goals.
4. Static analysis and build checks pass (`flutter analyze` for Flutter client and `pytest` / `mypy` for FastAPI backend).