# frozen_string_literal: true

require_relative 'eval/version'
require_relative 'eval/evaluators/base'
require_relative 'eval/evaluators/llm_judge'
require_relative 'eval/evaluators/code_evaluator'
require_relative 'eval/evaluators/security_evaluator'
require_relative 'eval/helpers/template_loader'
require_relative 'eval/helpers/annotation_schema'
require_relative 'eval/helpers/guardrails'
require_relative 'eval/runners/evaluation'
require_relative 'eval/runners/annotation'
require_relative 'eval/runners/agentic_review'
require_relative 'eval/runners/online'
require_relative 'eval/runners/code_review'
require_relative 'eval/client'

if defined?(Legion::Transport::Exchange)
  require_relative 'eval/transport/exchanges/codegen'
  require_relative 'eval/transport/queues/code_review'
  require_relative 'eval/transport/messages/code_review_requested'
  require_relative 'eval/transport/messages/code_review_completed'
end

require_relative 'eval/actors/code_review_subscriber' if defined?(Legion::Extensions::Actors::Subscription)

module Legion
  module Extensions
    module Eval
      extend Legion::Extensions::Core if defined?(Legion::Extensions::Core)
    end
  end
end

if defined?(Legion::LLM::Hooks)
  require_relative 'eval/helpers/guardrails'
  Legion::Extensions::Eval::Helpers::Guardrails.register_hooks!
end
