# frozen_string_literal: true

require 'yaml'

module Legion
  module Extensions
    module Eval
      module Runners
        module Evaluation
          def run_evaluation(evaluator_name:, evaluator_config: {}, inputs: [], **)
            evaluator = build_evaluator(evaluator_name, evaluator_config)
            results = inputs.map.with_index do |row, idx|
              result = evaluator.evaluate(input: row[:input], output: row[:output], expected: row[:expected])
              result.merge(row_index: idx)
            end

            summary = {
              total:     results.size,
              passed:    results.count { |r| r[:passed] },
              failed:    results.count { |r| !r[:passed] },
              avg_score: results.empty? ? 0.0 : (results.sum { |r| r[:score] } / results.size).round(3)
            }

            { evaluator: evaluator_name, results: results, summary: summary }
          end

          def list_evaluators(**)
            template_dir = File.join(__dir__, '..', 'templates')
            return { evaluators: [] } unless Dir.exist?(template_dir)

            builtin = Dir.glob(File.join(template_dir, '*.yml')).map do |f|
              YAML.safe_load_file(f, symbolize_names: true)
            end
            { evaluators: builtin }
          end

          private

          def build_evaluator(name, config)
            type = config[:type]&.to_sym || :llm_judge
            case type
            when :llm_judge then Evaluators::LlmJudge.new(name: name, config: config)
            when :code      then Evaluators::CodeEvaluator.new(name: name, config: config)
            else raise ArgumentError, "unknown evaluator type: #{type}"
            end
          end
        end
      end
    end
  end
end
