# frozen_string_literal: true

module Legion
  module Extensions
    module Eval
      module Evaluators
        class SecurityEvaluator
          DANGEROUS_PATTERNS = {
            shell_execution:        /\b(?:system|exec|spawn|fork|popen|Open3)\s*\(/,
            backtick_execution:     /`[^`]+`/,
            file_deletion:          /\b(?:FileUtils\.rm|FileUtils\.rm_rf|File\.delete|File\.unlink)\b/,
            dynamic_code_execution: /\b(?:eval|class_eval|module_eval|instance_eval|instance_exec)\s*[('"]/,
            unsafe_require:         /\brequire\s+[^'"]/,
            dynamic_dispatch:       /\.(?:send|public_send|__send__)\s*\([^:'"]/
          }.freeze

          def check(code:)
            flagged = []

            code.each_line.with_index(1) do |line, line_num|
              DANGEROUS_PATTERNS.each do |pattern_name, regex|
                match = line.match(regex)
                next unless match

                flagged << {
                  pattern: pattern_name,
                  line:    line_num,
                  match:   match[0].strip
                }
              end
            end

            { passed: flagged.empty?, flagged: flagged }
          end
        end
      end
    end
  end
end
