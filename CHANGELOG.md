# Changelog

## [0.1.0] - 2026-03-17

### Added
- `Evaluators::Base`: abstract evaluator base class
- `Evaluators::LlmJudge`: LLM-as-judge evaluation with template rendering and score extraction
- `Evaluators::CodeEvaluator`: regex, keyword, JSON validity, and length checks
- `Runners::Evaluation`: run_evaluation with summary stats, list_evaluators
- `Client` standalone client wrapper
- 3 built-in YAML templates: hallucination, relevance, toxicity
