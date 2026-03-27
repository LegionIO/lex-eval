# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Exchanges
          class Codegen < Legion::Transport::Exchange
            def exchange_name
              'codegen'
            end

            def exchange_options
              { type: 'topic', durable: true }
            end
          end
        end
      end
    end
  end
end
