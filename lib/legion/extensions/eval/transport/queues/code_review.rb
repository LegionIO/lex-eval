# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Queues
          class CodeReview < Legion::Transport::Queue
            def queue_name
              'eval.code_review'
            end

            def queue_options
              { durable: true }
            end

            def routing_key
              'eval.code_review.requested'
            end

            def exchange
              Exchanges::Codegen
            end
          end
        end
      end
    end
  end
end
