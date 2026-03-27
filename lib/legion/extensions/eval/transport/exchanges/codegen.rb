# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Transport
        module Exchanges
          module Codegen
            extend Legion::Transport::Exchange

            EXCHANGE_NAME = 'codegen'
            EXCHANGE_OPTIONS = { type: 'topic', durable: true }.freeze
          end
        end
      end
    end
  end
end
