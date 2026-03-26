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
        run_specs: false,
        llm_review: false,
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
        run_specs: false,
        llm_review: false,
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
        run_specs: false,
        llm_review: false,
        quality_gate: { enabled: false }
      })

      result = described_class.review_generated(code: valid_code, spec_code: '', context: {})
      expect(result[:confidence]).to be_a(Float)
      expect(result[:confidence]).to be > 0.0
    end
  end
end
