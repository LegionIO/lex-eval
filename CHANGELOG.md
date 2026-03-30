# Changelog

## [0.3.12] - 2026-03-29

### Changed
- `review_generated` now accepts `**extra` splat for task system payload compatibility; `context:` is optional (default `{}`)
- Verdict values are now strings (`'approve'`, `'reject'`, `'revise'`) instead of symbols for conditioner matching
- `build_result` passes `code`, `spec_code`, and extra kwargs through to the result hash for downstream consumers
- `CodeReviewSubscriber` actor enables `check_subtask?` for task system integration

## [0.3.11] - 2026-03-29

### Added
- Multi-provider model diversity for adversarial K-factor LLM review (`review_models:` kwarg)
- `build_model_assignments` cycles available providers, skips unavailable; falls back to default only when review_models is nil/empty or all providers unavailable
- `provider_available?` checks `Settings[:llm][:providers][sym][:enabled]`
- `llm_review` accepts `model_spec:` and forwards `model:`/`provider:` to `AgenticReview.review_output`
- Settings fallback: `codegen.self_generate.validation.review_models` (default `[]`)

## [0.3.10] - 2026-03-28

### Added
- K-factor adversarial LLM review (`review_k:` kwarg, default 1)

### Fixed
- `CodeReview#llm_review`: pass `input: context` and `review_prompt:` to `AgenticReview.review_output` instead of the unknown `criteria:` and `context:` kwargs which were silently absorbed by `**`

## [0.3.9] - 2026-03-28

### Added
- `CodeReview#run_quality_gate`: Stage 5 optional QualityGate pass after LLM review, powered by `Legion::Extensions::Factory::Helpers::QualityGate` when lex-factory is loaded
- `CodeReview#quality_gate_available?`: soft availability check; skips stage gracefully when lex-factory is absent
- `CodeReview#quality_gate_dimensions`: extracts completeness/correctness/quality/security dimension scores from prior stages for QualityGate input
- `CodeReview#stage_passed?`: shared predicate used by both `stage_scores` and `quality_gate_dimensions`
- QualityGate aggregate score now included in `calculate_confidence` via `stage_scores`
- Issue message appended to result when QualityGate aggregate falls below threshold
- Settings key `codegen.self_generate.validation.quality_gate.enabled` (default true when lex-factory available) and `quality_gate.threshold` to forward a custom threshold
- 6 new specs covering QualityGate integration: stage present, disabled via settings, fail message, aggregate in confidence, scores hash shape, graceful skip when lex-factory absent

## [0.3.8] - 2026-03-27

### Fixed
- Capture exception in `Helpers::Guardrails#load_guardrails` rescue block (`rescue StandardError => e`) and log warning to satisfy CI Rescue Logging lint

## [0.3.7] - 2026-03-27

### Fixed
- Replace `log&.warn(...)` with `log.warn(...)` in `CodeReviewSubscriber` and `Helpers::Guardrails` so the CI `\blog\.` rescue-logging check matches
- Fix `log` helper in both files to always return a non-nil object (returns `Legion::Logging` when available, a no-op null logger otherwise)

## [0.3.6] - 2026-03-27

### Fixed
- Replace `Legion::Logging.warn(...)` calls with `log&.warn(...)` using a private `log` helper in `CodeReviewSubscriber` and `Helpers::Guardrails` to satisfy the Helper Migration lint rule

## [0.3.4] - 2026-03-27

### Fixed
- `CodeReviewRequested` and `CodeReviewCompleted` messages: changed from `include` to class inheritance (`< Legion::Transport::Message`)

## [0.3.3] - 2026-03-27

### Fixed
- Exchange `Codegen`: changed from module with `extend` to class inheriting `Legion::Transport::Exchange` (Exchange is a Class, not a Module)
- Queue `CodeReview`: changed from module with `include` to class inheriting `Legion::Transport::Queue` for consistency

## [0.3.2] - 2026-03-27

### Fixed
- Exchange module: `include` -> `extend` for `Legion::Transport::Exchange` (class, not module)
- Actor: `CodeReviewSubscriber` changed from module to class inheriting `Actors::Subscription`
- Actor file guarded with `return unless defined?` for standalone spec compatibility

## [0.3.1] - 2026-03-26

### Changed
- set remote_invocable? false for local dispatch

## [0.3.0] - 2026-03-26

### Added
- SecurityEvaluator for generated code static analysis (6 dangerous pattern checks)
- CodeReview runner with 4-stage validation pipeline (syntax, security, specs, LLM review)
- CodeReviewSubscriber actor with AMQP transport layer

## [0.2.5] - 2026-03-24

### Added
- `review_experiment` A/B output comparison in AgenticReview — runs both outputs through `review_output`, compares confidence scores, declares winner with delta
- Specs for `review_experiment` covering winner selection, tie detection, delta calculation, and error handling

### Changed
- Add `caller: { extension: 'lex-eval', operation: '...' }` identity parameter to all Legion::LLM call sites: `LlmJudge#evaluate_structured`, `LlmJudge#evaluate_regex_fallback`, and `AgenticReview#review_output`

## [0.2.3] - 2026-03-22

### Changed
- Add legion-* sub-gems as runtime dependencies (legion-logging, legion-settings, legion-cache, legion-crypt, legion-data, legion-json, legion-transport)
- Replace direct `Legion::Logging.warn` calls in `Runners::Online` with injected `log` helper
- Update spec_helper with real sub-gem helper stubs (replaces hand-rolled Legion::Logging stub)

## [0.2.2] - 2026-03-19

### Added
- `Runners::Online`: online evaluation runner with configurable evaluators, sample rate, and per-evaluator error isolation
- `Actor::Online`: subscription actor listening on `llm.response` exchange; guarded by `enabled?` checking transport availability and settings
- Settings defaults for `eval.online`: `enabled: true`, `evaluators: ['toxicity']`, `sample_rate: 1.0`
- `Client` now includes `Runners::Online`

## [0.2.1] - 2026-03-20

### Added
- `Helpers::Guardrails` for loading YAML pattern rules and registering before/after hooks with `Legion::LLM::Hooks`
- Three built-in guardrail templates: `jailbreak_detector`, `pii_detector`, `toxicity_detector`
- Boot registration: automatically registers guardrails when `Legion::LLM::Hooks` is available

## [0.2.0] - 2026-03-20

### Added
- Function-calling LLM judge via Legion::LLM.structured with JUDGE_SCHEMA (85%+ F1)
- 9 new eval templates: faithfulness, qa_correctness, sql_generation, code_generation, code_readability, tool_calling, human_vs_ai, rag_relevancy, summarization
- Template metadata: category and requires_expected fields on all templates
- TemplateLoader with lex-prompt integration and YAML fallback
- seed_prompts for bootstrapping eval templates into lex-prompt
- Public build_evaluator API on Client
- Annotation queues: create_queue, enqueue, assign, complete, skip, stats, export_to_dataset
- AnnotationSchema helper for DB table creation
- Agentic review: review_output, review_with_escalation with confidence-based routing

### Changed
- LlmJudge uses structured output extraction with regex fallback
- list_evaluators delegates to TemplateLoader

## [0.1.0] - 2026-03-17

### Added
- `Evaluators::Base`: abstract evaluator base class
- `Evaluators::LlmJudge`: LLM-as-judge evaluation with template rendering and score extraction
- `Evaluators::CodeEvaluator`: regex, keyword, JSON validity, and length checks
- `Runners::Evaluation`: run_evaluation with summary stats, list_evaluators
- `Client` standalone client wrapper
- 3 built-in YAML templates: hallucination, relevance, toxicity
