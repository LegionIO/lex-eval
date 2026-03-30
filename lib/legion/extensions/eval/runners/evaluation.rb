# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Runners
        module Evaluation
          extend self # rubocop:disable Style/ModuleFunction

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
            { evaluators: Helpers::TemplateLoader.new.list_templates }
          end

          def build_evaluator(name, config = {})
            if config.empty?
              loader = Helpers::TemplateLoader.new
              template_config = loader.load_template(name.to_s)
              config = template_config if template_config
            end
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
