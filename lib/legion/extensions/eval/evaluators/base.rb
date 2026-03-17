# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Evaluators
        class Base
          attr_reader :name, :config

          def initialize(name:, config: {})
            @name   = name
            @config = config
          end

          def evaluate(input:, output:, expected: nil, context: {})
            raise NotImplementedError, "#{self.class}#evaluate must be implemented"
          end
        end
      end
    end
  end
end
