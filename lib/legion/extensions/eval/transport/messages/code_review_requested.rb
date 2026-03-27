# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Messages
          class CodeReviewRequested < Legion::Transport::Message
            QUEUE = Queues::CodeReview
          end
        end
      end
    end
  end
end
