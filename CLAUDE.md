# lex-eval

**Level 3 Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Grandparent**: `/Users/miverso2/rubymine/legion/CLAUDE.md`

## What Is This Gem?

LLM output evaluation framework for LegionIO. Provides LLM-as-judge and code-based evaluators for scoring LLM outputs, with per-row pass/fail results and summary statistics.

**Gem**: `lex-eval`
**Version**: 0.1.0
**Namespace**: `Legion::Extensions::Eval`

## File Structure

```
lib/legion/extensions/eval/
  version.rb
  evaluators/
    base.rb            # Base evaluator class with shared interface
    llm_judge.rb       # Uses legion-llm to score against criteria
    code_evaluator.rb  # Code/structural validity evaluator
  runners/
    evaluation.rb      # run_evaluation, list_evaluators
  client.rb
spec/
  (5 spec files)
```

## Key Design Decisions

- Evaluators implement `evaluate(input:, output:, expected:)` returning `{ passed:, score: }`
- `run_evaluation` maps over all input rows, merges `row_index`, and builds a summary
- `build_evaluator` selects evaluator type via `config[:type]` (`:llm_judge` or `:code`); defaults to `:llm_judge`
- `list_evaluators` reads YAML templates from `lib/legion/extensions/eval/templates/`; returns empty array if directory is absent
- LLM judge requires `legion-llm` to be loaded and started; gracefully degrades otherwise

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```
