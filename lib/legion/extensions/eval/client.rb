# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      class Client
        include Runners::Evaluation

        def initialize(**opts)
          @opts = opts
        end
      end
    end
  end
end
