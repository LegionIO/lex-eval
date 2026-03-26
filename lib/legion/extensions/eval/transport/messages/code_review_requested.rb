# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Messages
          class CodeReviewRequested
            include Legion::Transport::Message

            QUEUE = Queues::CodeReview
          end
        end
      end
    end
  end
end
