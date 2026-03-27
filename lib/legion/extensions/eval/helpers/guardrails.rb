# frozen_string_literal: true

require 'yaml'

module Legion
  module Extensions
    module Eval
      module Helpers
        module Guardrails
          class << self
            def load_guardrails(directory = nil)
              dir = directory || default_directory
              return [] unless dir && ::Dir.exist?(dir)

              ::Dir.glob(::File.join(dir, '*.yaml')).filter_map do |path|
                YAML.safe_load_file(path, symbolize_names: true)
              rescue StandardError
                nil
              end
            end

            def register_hooks!(guardrails = nil)
              guardrails ||= load_guardrails
              return unless defined?(Legion::LLM::Hooks)

              guardrails.each do |rule|
                phase = (rule[:phase] || 'before').to_sym
                register_rule(rule, phase)
              end
            end

            def check_patterns(text, patterns)
              return false unless patterns.is_a?(Array) && text.is_a?(String)

              patterns.any? { |p| text.downcase.include?(p.to_s.downcase) }
            end

            private

            def default_directory
              ::File.expand_path('~/.legionio/guardrails')
            end

            def register_rule(rule, phase)
              handler = build_handler(rule)
              Legion::LLM::Hooks.before_chat(&handler) if %i[before both].include?(phase)
              Legion::LLM::Hooks.after_chat(&handler) if %i[after both].include?(phase)
            end

            def build_handler(rule)
              proc do |messages: nil, response: nil, **_opts|
                text = extract_text(messages, response)
                next unless check_patterns(text, rule[:patterns])

                case rule[:action]&.to_sym
                when :block
                  { action: :block, rule: rule[:name],
                    response: { success: false, blocked: true, reason: rule[:name],
                                content: rule[:fallback_response] || 'Request blocked by guardrail.' } }
                when :warn
                  log.warn("Guardrail #{rule[:name]} triggered")
                  nil
                when :fallback
                  { action: :block, rule: rule[:name],
                    response: { success: true, content: rule[:fallback_response], guardrail: rule[:name] } }
                end
              end
            end

            def extract_text(messages, response)
              if messages
                messages.map { |m| m[:content].to_s }.join(' ')
              elsif response
                response.is_a?(Hash) ? response[:content].to_s : response.to_s
              else
                ''
              end
            end

            def log
              return Legion::Logging if defined?(Legion::Logging)

              @log ||= Object.new.tap do |nl|
                %i[debug info warn error fatal].each { |m| nl.define_singleton_method(m) { |*| nil } }
              end
            end
          end
        end
      end
    end
  end
end
