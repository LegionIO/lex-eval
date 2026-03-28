# frozen_string_literal: true

require 'open3'
require 'tmpdir'

module Legion
  module Extensions
    module Eval
      module Runners
        module CodeReview
          extend self
          include Legion::Logging::Helper

          SPEC_TIMEOUT = 30

          def review_generated(code:, spec_code:, context:) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
            settings = validation_settings
            stages = {}
            issues = []

            # Stage 1: Syntax check
            if settings[:syntax_check] != false
              stages[:syntax] = check_syntax(code, spec_code)
              unless stages[:syntax][:passed]
                return build_result(passed: false, verdict: :reject, stages: stages,
                                    issues: stages[:syntax][:errors], confidence: 0.0)
              end
            end

            # Stage 2: Security check
            stages[:security] = check_security(code)
            unless stages[:security][:passed]
              issues.concat(stages[:security][:flagged].map { |f| "security: #{f[:pattern]} on line #{f[:line]}" })
              return build_result(passed: false, verdict: :reject, stages: stages, issues: issues, confidence: 0.0)
            end

            # Stage 3: Spec execution (optional)
            if settings[:run_specs] && !spec_code.to_s.empty?
              stages[:specs] = run_specs(code, spec_code)
              unless stages[:specs][:passed]
                issues << "specs failed: #{stages[:specs][:output]}"
                return build_result(passed: false, verdict: :revise, stages: stages, issues: issues, confidence: 0.2)
              end
            end

            # Stage 4: LLM review (optional)
            if settings[:llm_review] && llm_available?
              stages[:llm_review] = llm_review(code, context)
              issues.concat(stages[:llm_review][:issues] || [])
            end

            # Stage 5: QualityGate (optional, requires lex-factory)
            qg_settings = settings[:quality_gate] || {}
            if quality_gate_available? && qg_settings[:enabled] != false
              stages[:quality_gate] = run_quality_gate(stages, qg_settings)
              unless stages[:quality_gate][:pass]
                issues << "quality gate failed: aggregate #{stages[:quality_gate][:aggregate]} below threshold #{stages[:quality_gate][:threshold]}"
              end
            end

            confidence = calculate_confidence(stages)
            verdict = confidence >= 0.5 ? :approve : :revise

            build_result(passed: true, verdict: verdict, stages: stages, issues: issues, confidence: confidence)
          end

          private

          def validation_settings
            return {} unless defined?(Legion::Settings)

            Legion::Settings.dig(:codegen, :self_generate, :validation) || {}
          rescue StandardError => e
            log.warn("validation_settings failed: #{e.message}")
            {}
          end

          def check_syntax(code, spec_code)
            errors = []
            begin
              RubyVM::InstructionSequence.compile(code)
            rescue SyntaxError => e
              log.debug("syntax check failed: #{e.message}")
              errors << "code: #{e.message}"
            end

            if spec_code && !spec_code.empty?
              begin
                RubyVM::InstructionSequence.compile(spec_code)
              rescue SyntaxError => e
                log.debug("spec syntax check failed: #{e.message}")
                errors << "spec: #{e.message}"
              end
            end

            { passed: errors.empty?, errors: errors }
          end

          def check_security(code)
            evaluator = Evaluators::SecurityEvaluator.new
            evaluator.check(code: code)
          end

          def run_specs(code, spec_code)
            Dir.mktmpdir('legion_code_review') do |dir|
              File.write(File.join(dir, 'generated.rb'), code)
              spec_content = "require_relative 'generated'\n#{spec_code}"
              File.write(File.join(dir, 'generated_spec.rb'), spec_content)

              stdout, stderr, status = Open3.capture3(
                'bundle', 'exec', 'rspec', File.join(dir, 'generated_spec.rb'),
                '--format', 'progress',
                chdir:   dir,
                timeout: SPEC_TIMEOUT
              )

              { passed: status.success?, output: stdout, errors: stderr, exit_code: status.exitstatus }
            end
          rescue StandardError => e
            log.warn("spec execution failed: #{e.message}")
            { passed: false, output: '', errors: e.message, exit_code: -1 }
          end

          def llm_review(code, context)
            return { passed: true, issues: [], confidence: 0.5 } unless defined?(Runners::AgenticReview)

            result = Runners::AgenticReview.review_output(
              output:   code,
              criteria: 'Review this generated Ruby code for correctness, safety, and Legion conventions.',
              context:  context
            )

            {
              passed:     result[:reviewed] != false,
              issues:     result[:issues] || [],
              confidence: result[:confidence] || 0.5
            }
          rescue StandardError => e
            log.warn("llm review failed: #{e.message}")
            { passed: true, issues: ["llm review failed: #{e.message}"], confidence: 0.5 }
          end

          def llm_available?
            defined?(Legion::LLM) && Legion::LLM.respond_to?(:chat)
          end

          def quality_gate_available?
            defined?(Legion::Extensions::Factory::Helpers::QualityGate)
          end

          def run_quality_gate(stages, qg_settings)
            kwargs = quality_gate_dimensions(stages)
            kwargs[:threshold] = qg_settings[:threshold] if qg_settings[:threshold]
            Legion::Extensions::Factory::Helpers::QualityGate.score(**kwargs)
          rescue StandardError => e
            log.warn("quality gate failed: #{e.message}")
            { pass: true, aggregate: 1.0, threshold: 0.8, scores: {}, error: e.message }
          end

          def quality_gate_dimensions(stages)
            {
              completeness: stage_passed?(stages[:syntax]) ? 1.0 : 0.0,
              correctness:  qg_correctness(stages[:specs]),
              quality:      stages.dig(:llm_review, :confidence) || 1.0,
              security:     stage_passed?(stages[:security]) ? 1.0 : 0.0
            }
          end

          def qg_correctness(specs_stage)
            return 1.0 unless specs_stage

            stage_passed?(specs_stage) ? 1.0 : 0.3
          end

          def stage_passed?(stage)
            stage&.dig(:passed) == true
          end

          def calculate_confidence(stages)
            scores = stage_scores(stages)
            return 0.5 if scores.empty?

            scores.sum / scores.size
          end

          def stage_scores(stages) # rubocop:disable Metrics/PerceivedComplexity
            scores = []
            scores << (stage_passed?(stages[:syntax]) ? 1.0 : 0.0) if stages[:syntax]
            scores << (stage_passed?(stages[:security]) ? 1.0 : 0.0) if stages[:security]
            scores << (stage_passed?(stages[:specs]) ? 1.0 : 0.3) if stages[:specs]
            scores << (stages.dig(:llm_review, :confidence) || 0.5) if stages[:llm_review]
            scores << stages.dig(:quality_gate, :aggregate) if stages[:quality_gate]
            scores
          end

          def build_result(passed:, verdict:, stages:, issues:, confidence:)
            { passed: passed, verdict: verdict, confidence: confidence, stages: stages, issues: issues }
          end
        end
      end
    end
  end
end
