# frozen_string_literal: true

return unless defined?(Legion::Extensions::Actors::Subscription)

module Legion
  module Extensions
    module Eval
      module Actor
        class CodeReviewSubscriber < Legion::Extensions::Actors::Subscription
          QUEUE = defined?(Transport::Queues::CodeReview) ? Transport::Queues::CodeReview : nil

          def runner_class = self.class
          def runner_function = 'action'

          def action(payload)
            code = payload[:runner_code] || payload[:code]
            spec_code = payload[:spec_code] || ''
            context = payload[:context] || {}
            generation_id = payload[:generation_id]

            result = Runners::CodeReview.review_generated(code: code, spec_code: spec_code, context: context)

            if defined?(Transport::Messages::CodeReviewCompleted)
              Transport::Messages::CodeReviewCompleted.new(
                result:        result,
                generation_id: generation_id
              ).publish
            end

            result
          rescue StandardError => e
            Legion::Logging.warn("CodeReviewSubscriber failed: #{e.message}") if defined?(Legion::Logging)
            { passed: false, verdict: :reject, error: e.message }
          end
        end
      end
    end
  end
end
