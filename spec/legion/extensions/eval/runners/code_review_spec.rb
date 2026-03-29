# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Runners::CodeReview do
  describe '.review_generated' do
    let(:valid_code) do
      <<~RUBY
        # frozen_string_literal: true

        module Legion
          module Generated
            module_function

            def greet(name:)
              { success: true, greeting: "Hello \#{name}" }
            end
          end
        end
      RUBY
    end

    let(:valid_spec) do
      <<~RUBY
        require 'rspec'
        RSpec.describe 'greet' do
          it 'works' do
            expect(true).to be true
          end
        end
      RUBY
    end

    let(:syntax_error_code) { 'def foo(' }

    it 'fails fast on syntax error' do
      result = described_class.review_generated(code: syntax_error_code, spec_code: '', context: {})
      expect(result[:passed]).to be false
      expect(result[:verdict]).to eq(:reject)
      expect(result[:stages][:syntax][:passed]).to be false
    end

    it 'fails on security violations' do
      dangerous = "system('rm -rf /')"
      result = described_class.review_generated(code: dangerous, spec_code: '', context: {})
      expect(result[:passed]).to be false
      expect(result[:stages][:security][:passed]).to be false
    end

    it 'passes syntax and security for clean code with validation disabled' do
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                        syntax_check: true,
                                                                                                        run_specs:    false,
                                                                                                        llm_review:   false,
                                                                                                        quality_gate: { enabled: false }
                                                                                                      })

      result = described_class.review_generated(code: valid_code, spec_code: valid_spec, context: {})
      expect(result[:passed]).to be true
      expect(result[:verdict]).to eq(:approve)
      expect(result[:stages][:syntax][:passed]).to be true
      expect(result[:stages][:security][:passed]).to be true
    end

    it 'returns all stage results' do
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                        syntax_check: true,
                                                                                                        run_specs:    false,
                                                                                                        llm_review:   false,
                                                                                                        quality_gate: { enabled: false }
                                                                                                      })

      result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
      expect(result[:stages]).to have_key(:syntax)
      expect(result[:stages]).to have_key(:security)
    end

    it 'calculates confidence score' do
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                        syntax_check: true,
                                                                                                        run_specs:    false,
                                                                                                        llm_review:   false,
                                                                                                        quality_gate: { enabled: false }
                                                                                                      })

      result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
      expect(result[:confidence]).to be_a(Float)
      expect(result[:confidence]).to be > 0.0
    end

    context 'when lex-factory QualityGate is available' do
      before do
        stub_const('Legion::Extensions::Factory::Helpers::QualityGate', Module.new do
          def self.score(completeness:, correctness:, quality:, security:, **opts)
            threshold = opts[:threshold] || 0.8
            aggregate = (completeness * 0.35) + (correctness * 0.35) + (quality * 0.20) + (security * 0.10)
            { pass: aggregate >= threshold, aggregate: aggregate.round(4), threshold: threshold,
              scores: { completeness: completeness, correctness: correctness, quality: quality, security: security } }
          end
        end)
      end

      it 'runs the QualityGate stage and includes it in the result' do
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                          syntax_check: true,
                                                                                                          run_specs:    false,
                                                                                                          llm_review:   false
                                                                                                        })

        result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
        expect(result[:stages]).to have_key(:quality_gate)
        expect(result[:stages][:quality_gate]).to include(:pass, :aggregate, :threshold, :scores)
      end

      it 'includes the quality_gate aggregate in confidence calculation' do
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                          syntax_check: true,
                                                                                                          run_specs:    false,
                                                                                                          llm_review:   false
                                                                                                        })

        result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
        expect(result[:confidence]).to be_a(Float)
        expect(result[:confidence]).to be > 0.0
      end

      it 'adds an issue message when QualityGate fails' do
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                          syntax_check: true,
                                                                                                          run_specs:    false,
                                                                                                          llm_review:   false,
                                                                                                          quality_gate: { threshold: 1.1 }
                                                                                                        })

        result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
        expect(result[:issues].any? { |i| i.include?('quality gate failed') }).to be true
      end

      it 'skips QualityGate when disabled in settings' do
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                          syntax_check: true,
                                                                                                          run_specs:    false,
                                                                                                          llm_review:   false,
                                                                                                          quality_gate: { enabled: false }
                                                                                                        })

        result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
        expect(result[:stages]).not_to have_key(:quality_gate)
      end

      it 'passes QualityGate stage info through to the result stages hash' do
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                          syntax_check: true,
                                                                                                          run_specs:    false,
                                                                                                          llm_review:   false
                                                                                                        })

        result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
        qg = result[:stages][:quality_gate]
        expect(qg[:scores]).to include(:completeness, :correctness, :quality, :security)
      end
    end

    describe 'adversarial LLM review (K > 1)' do
      let(:approve_review) { { passed: true, issues: [], confidence: 0.8 } }

      before do
        allow(described_class).to receive(:llm_available?).and_return(true)
        allow(described_class).to receive(:validation_settings).and_return({ llm_review: true, syntax_check: false })
        allow(described_class).to receive(:llm_review).and_return(approve_review)
      end

      context 'when review_k is passed' do
        it 'runs LLM review K times' do
          result = described_class.review_generated(code: 'puts 1', spec_code: '', context: {}, review_k: 3)
          expect(result[:stages][:llm_review][:k]).to eq(3)
          expect(result[:stages][:llm_review][:approvals]).to eq(3)
        end
      end

      context 'when review_k defaults to 1' do
        it 'runs single LLM review' do
          result = described_class.review_generated(code: 'puts 1', spec_code: '', context: {})
          expect(result[:stages][:llm_review]).not_to have_key(:k)
        end
      end
    end

    context 'when lex-factory QualityGate is not available' do
      it 'skips the QualityGate stage gracefully' do
        allow(Legion::Settings).to receive(:dig).and_return(nil)
        allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                          syntax_check: true,
                                                                                                          run_specs:    false,
                                                                                                          llm_review:   false
                                                                                                        })

        # Ensure QualityGate constant is absent
        hide_const('Legion::Extensions::Factory::Helpers::QualityGate') if defined?(Legion::Extensions::Factory::Helpers::QualityGate)

        result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
        expect(result[:passed]).to be true
        expect(result[:stages]).not_to have_key(:quality_gate)
      end
    end
  end
end
