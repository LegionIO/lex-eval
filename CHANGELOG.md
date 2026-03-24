# Changelog

## [Unreleased]

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
