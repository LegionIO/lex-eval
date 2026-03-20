# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      class Client
        include Runners::Evaluation
        include Runners::Annotation
        include Runners::AgenticReview

        def initialize(db: nil, **opts)
          @db = db
          @opts = opts
        end
      end
    end
  end
end
