# frozen_string_literal: true

require 'json'
require_relative 'base'

module Legion
  module Extensions
    module Eval
      module Evaluators
        class CodeEvaluator < Base
          def evaluate(input:, output:, expected: nil, context: {}) # rubocop:disable Lint/UnusedMethodArgument
            checks = @config[:checks] || []
            failures = checks.reject { |check| run_check(check, output.to_s) }
            score = checks.empty? ? 1.0 : (checks.size - failures.size).to_f / checks.size
            { score: score, passed: failures.empty?, failures: failures.map { |c| c[:name] || c[:type] } }
          end

          private

          def run_check(check, output)
            case check[:type].to_s
            when 'regex'             then output.match?(Regexp.new(check[:pattern]))
            when 'keyword_contains'  then Array(check[:keywords]).all? { |k| output.include?(k) }
            when 'min_length'        then output.length >= (check[:length] || 0)
            when 'max_length'        then output.length <= (check[:length] || Float::INFINITY)
            when 'json_valid'        then valid_json?(output)
            else false
            end
          end

          def valid_json?(str)
            ::JSON.parse(str)
            true
          rescue ::JSON::ParserError => _e
            false
          end
        end
      end
    end
  end
end
