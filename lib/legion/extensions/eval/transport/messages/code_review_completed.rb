# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Messages
          class CodeReviewCompleted < Legion::Transport::Message
            def initialize(result:, generation_id:)
              super()
              @result = result
              @generation_id = generation_id
            end

            def message
              { generation_id: @generation_id, **@result }
            end

            def routing_key
              'codegen.review.completed'
            end
          end
        end
      end
    end
  end
end
