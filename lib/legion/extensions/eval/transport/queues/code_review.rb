# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Queues
          module CodeReview
            include Legion::Transport::Queue

            QUEUE_NAME = 'eval.code_review'
            QUEUE_OPTIONS = { durable: true }.freeze
            BINDING_OPTIONS = { routing_key: 'eval.code_review.requested' }.freeze
            EXCHANGE = Exchanges::Codegen
          end
        end
      end
    end
  end
end
