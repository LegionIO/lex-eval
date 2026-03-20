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

12 YAML evaluator templates ship with the gem and are returned by `list_evaluators`:

`hallucination`, `relevance`, `toxicity`, `faithfulness`, `qa_correctness`, `sql_generation`, `code_generation`, `code_readability`, `tool_calling`, `human_vs_ai`, `rag_relevancy`, `summarization`

## Annotation Queues

Human-in-the-loop annotation for labeling LLM outputs:

```ruby
client = Legion::Extensions::Eval::Client.new(db: Sequel.sqlite)
Legion::Extensions::Eval::Helpers::AnnotationSchema.create_tables(client.instance_variable_get(:@db))

client.create_queue(name: 'review', description: 'Manual review queue')
client.enqueue_items(queue_name: 'review', items: [{ input: 'q', output: 'a' }])
client.assign_next(queue_name: 'review', annotator: 'alice', count: 5)
client.complete_annotation(item_id: 1, label_score: 0.9, label_category: 'correct')
client.queue_stats(queue_name: 'review')
client.export_to_dataset(queue_name: 'review')
```

## Agentic Review

AI-reviews-AI with confidence-based escalation:

```ruby
client = Legion::Extensions::Eval::Client.new
result = client.review_output(input: 'question', output: 'answer')
# => { confidence: 0.92, recommendation: 'approve', issues: [], explanation: '...' }

result = client.review_with_escalation(input: 'q', output: 'a')
# => { action: :auto_approve, escalated: false, ... }  (confidence > 0.9)
# => { action: :light_review, escalated: true, priority: :low, ... }  (0.6-0.9)
# => { action: :full_review, escalated: true, priority: :high, ... }  (< 0.6)
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
