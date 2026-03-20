# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Runners
        module Online
          def evaluate_response(response:, evaluators: nil, sample_rate: 1.0, **)
            evaluator_names = evaluators || configured_evaluators
            effective_rate  = sample_rate || configured_sample_rate

            return { evaluated: false, reason: :sampled_out, sampled: false } unless rand <= effective_rate

            scores = {}
            evaluator_names.each do |name|
              scores[name.to_sym] = run_single_evaluator(name, response)
            end

            { evaluated: true, scores: scores, sampled: true }
          rescue StandardError => e
            Legion::Logging.warn("lex-eval online: evaluate_response failed: #{e.message}") if defined?(Legion::Logging)
            { evaluated: false, reason: :error, error: e.message, sampled: true }
          end

          private

          def run_single_evaluator(name, response)
            loader = Helpers::TemplateLoader.new
            config = loader.load_template(name.to_s) || {}
            result = run_evaluation(
              evaluator_name:   name,
              evaluator_config: config,
              inputs:           [{ input: response[:input] || '', output: response[:output] || '' }]
            )
            result.dig(:summary, :avg_score)
          rescue StandardError => e
            Legion::Logging.warn("lex-eval online: evaluator #{name} failed: #{e.message}") if defined?(Legion::Logging)
            nil
          end

          def configured_evaluators
            return %w[toxicity] unless defined?(Legion::Settings)

            Legion::Settings.dig(:eval, :online, :evaluators) || %w[toxicity]
          end

          def configured_sample_rate
            return 1.0 unless defined?(Legion::Settings)

            Legion::Settings.dig(:eval, :online, :sample_rate) || 1.0
          end
        end
      end
    end
  end
end
