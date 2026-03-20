# frozen_string_literal: true

require_relative 'eval/version'
require_relative 'eval/evaluators/base'
require_relative 'eval/evaluators/llm_judge'
require_relative 'eval/evaluators/code_evaluator'
require_relative 'eval/helpers/template_loader'
require_relative 'eval/helpers/annotation_schema'
require_relative 'eval/helpers/guardrails'
require_relative 'eval/runners/evaluation'
require_relative 'eval/runners/annotation'
require_relative 'eval/runners/agentic_review'
require_relative 'eval/client'

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
