# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Runners
        module AgenticReview
          REVIEW_SCHEMA = {
            type:       :object,
            properties: {
              confidence:     { type: :number, minimum: 0.0, maximum: 1.0 },
              recommendation: { type: :string, enum: %w[approve revise reject] },
              issues:         { type: :array, items: {
                type:       :object,
                properties: {
                  severity:    { type: :string, enum: %w[critical major minor nit] },
                  description: { type: :string },
                  location:    { type: :string }
                }
              } },
              explanation:    { type: :string }
            },
            required:   %i[confidence recommendation explanation]
          }.freeze

          def review_output(input:, output:, review_prompt: nil, **)
            prompt = build_review_message(review_prompt || default_review_prompt, input, output)
            Legion::LLM.structured(message: prompt, schema: REVIEW_SCHEMA,
                                   intent: { capability: :reasoning },
                                   caller: { extension: 'lex-eval', operation: 'agentic_review' })
          rescue StandardError => e
            { confidence: 0.0, recommendation: 'reject',
              issues: [], explanation: "review error: #{e.message}" }
          end

          def review_with_escalation(input:, output:, review_prompt: nil, **)
            review = review_output(input: input, output: output, review_prompt: review_prompt)
            action, priority = determine_escalation(review[:confidence])

            return review.merge(action: :auto_approve, escalated: false) if action == :auto_approve

            review.merge(action: action, escalated: true, priority: priority)
          end

          def review_experiment(**)
            { reviewed: false, reason: 'not_yet_implemented' }
          end

          private

          def determine_escalation(confidence)
            case confidence
            when 0.9..1.0  then [:auto_approve, nil]
            when 0.6...0.9 then %i[light_review low]
            else                %i[full_review high]
            end
          end

          def build_review_message(review_prompt, input, output)
            "#{review_prompt}\n\n---\n\nInput: #{input}\n\nOutput to review: #{output}"
          end

          def default_review_prompt
            'You are a code and content reviewer. Assess the quality, correctness, and completeness ' \
              'of the output given the input. Identify any issues by severity.'
          end
        end
      end
    end
  end
end
