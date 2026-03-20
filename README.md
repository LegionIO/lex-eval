# lex-eval

LLM output evaluation framework for LegionIO. Provides LLM-as-judge and code-based evaluators for scoring LLM outputs against expected results, with per-row results and summary statistics.

## Overview

`lex-eval` runs structured evaluation suites against LLM outputs. Each evaluation takes a list of input/output/expected triples, scores them with the chosen evaluator, and returns a result set with pass/fail per row and an aggregate score.

## Installation

```ruby
gem 'lex-eval'
```

## Usage

```ruby
require 'legion/extensions/eval'

client = Legion::Extensions::Eval::Client.new

# Run an LLM-judge evaluation
result = client.run_evaluation(
  evaluator_name: 'accuracy',
  evaluator_config: { type: :llm_judge, criteria: 'factual correctness' },
  inputs: [
    { input: 'What is BGP?', output: 'Border Gateway Protocol', expected: 'Border Gateway Protocol' },
    { input: 'What is OSPF?', output: 'Open Shortest Path First', expected: 'Open Shortest Path First' }
  ]
)
# => { evaluator: 'accuracy',
#      results: [{ passed: true, score: 1.0, row_index: 0 }, ...],
#      summary: { total: 2, passed: 2, failed: 0, avg_score: 1.0 } }

# Run a code-based evaluation
client.run_evaluation(
  evaluator_name: 'json-validity',
  evaluator_config: { type: :code },
  inputs: [{ input: 'parse this', output: '{"valid": true}', expected: nil }]
)

# List built-in evaluator templates
client.list_evaluators
```

## Evaluator Types

| Type | Description |
|------|-------------|
| `:llm_judge` | Uses `legion-llm` to score output against expected using natural language criteria |
| `:code` | Runs a Ruby proc or checks structural validity |

## Built-In Templates

Three YAML evaluator templates ship with the gem and are returned by `list_evaluators`:

- `hallucination` — detects factual claims not grounded in context
- `relevance` — scores output topical alignment with the input
- `toxicity` — flags harmful, biased, or unsafe content

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
