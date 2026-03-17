# frozen_string_literal: true

require_relative 'base'

module Legion
  module Extensions
    module Eval
      module Evaluators
        class LlmJudge < Base
          def evaluate(input:, output:, expected: nil, context: {}) # rubocop:disable Lint/UnusedMethodArgument
            prompt = render_template(input: input, output: output, expected: expected)
            response = Legion::LLM.chat(message: prompt, intent: { capability: :reasoning })
            score = extract_score(response.content)
            { score: score, explanation: response.content, passed: score >= threshold }
          rescue StandardError => e
            { score: 0.0, explanation: "evaluation error: #{e.message}", passed: false }
          end

          private

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
