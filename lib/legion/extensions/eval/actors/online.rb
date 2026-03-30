# frozen_string_literal: true

require 'legion/extensions/actors/subscription'

module Legion
  module Extensions
    module Eval
      module Actor
        class Online < Legion::Extensions::Actors::Subscription
          EXCHANGE = 'llm.response'
          QUEUE    = 'eval.online'

          def runner_class
            Legion::Extensions::Eval::Runners::Online
          end

          def runner_function
            'evaluate_response'
          end

          def check_subtask?
            false
          end

          def generate_task?
            false
          end

          def use_runner?
            false
          end

          def enabled? # rubocop:disable Legion/Extension/ActorEnabledSideEffects
            return false unless Legion.const_defined?(:Transport, false)
            return false unless defined?(Legion::Extensions::Eval::Runners::Online)

            online_enabled?
          rescue StandardError => _e
            false
          end

          private

          def online_enabled?
            return true unless defined?(Legion::Settings)

            Legion::Settings.dig(:eval, :online, :enabled) != false
          end
        end
      end
    end
  end
end
