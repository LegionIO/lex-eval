# frozen_string_literal: true

require_relative 'base'

module Legion
  module Extensions
    module Eval
      module Evaluators
        class LlmJudge < Base
          JUDGE_SCHEMA = {
            type:       :object,
            properties: {
              score:       { type: :number, minimum: 0.0, maximum: 1.0,
                             description: 'Normalized score from 0.0 (worst) to 1.0 (best)' },
              passed:      { type:        :boolean,
                             description: 'Whether the output meets the quality threshold' },
              explanation: { type:        :string,
                             description: 'Brief explanation of the judgment' },
              evidence:    { type: :array, items: { type: :string },
                             description: 'Specific quotes or references supporting the judgment' }
            },
            required:   %i[score passed explanation]
          }.freeze

          def evaluate(input:, output:, expected: nil, context: {}) # rubocop:disable Lint/UnusedMethodArgument
            if defined?(Legion::Telemetry::OpenInference)
              Legion::Telemetry::OpenInference.evaluator_span(template: @config[:name] || 'unknown') do |_span|
                evaluate_impl(input: input, output: output, expected: expected)
              end
            else
              evaluate_impl(input: input, output: output, expected: expected)
            end
          end

          private

          def evaluate_impl(input:, output:, expected:)
            prompt = render_template(input: input, output: output, expected: expected)
            evaluate_structured(prompt)
          rescue StandardError
            evaluate_regex_fallback(prompt)
          end

          def evaluate_structured(prompt)
            return evaluate_regex_fallback(prompt) unless structured_available?

            result = Legion::LLM.structured(message: prompt, schema: JUDGE_SCHEMA,
                                            intent: { capability: :reasoning },
                                            caller: { extension: 'lex-eval', operation: 'judge' })
            { score: result[:score], passed: result[:passed],
              explanation: result[:explanation], evidence: result[:evidence] || [] }
          rescue StandardError
            evaluate_regex_fallback(prompt)
          end

          def evaluate_regex_fallback(prompt)
            response = Legion::LLM.chat(message: prompt, intent: { capability: :reasoning },
                                        caller: { extension: 'lex-eval', operation: 'judge' })
            score = extract_score(response.content)
            { score: score, explanation: response.content, passed: score >= threshold, evidence: [] }
          rescue StandardError => e
            { score: 0.0, explanation: "evaluation error: #{e.message}", passed: false, evidence: [] }
          end

          def structured_available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:structured)
          end

          def render_template(input:, output:, expected:)
            tmpl = @config[:template] || ''
            tmpl.gsub('{{input}}', input.to_s)
                .gsub('{{output}}', output.to_s)
                .gsub('{{expected}}', expected.to_s)
          end

          def extract_score(content)
            match = content.match(/(?:score|rating)[:\s]*(\d+(?:\.\d+)?)/i)
            match ? [match[1].to_f / (@config[:scale] || 10.0), 1.0].min : 0.5
          end

          def threshold
            @config.fetch(:threshold, 0.5)
          end
        end
      end
    end
  end
end
