# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Evaluators::SecurityEvaluator do
  subject(:evaluator) { described_class.new }

  describe '#check' do
    it 'passes clean code' do
      code = <<~RUBY
        module Legion
          module Generated
            def self.greet(name:)
              { success: true, greeting: "Hello \#{name}" }
            end
          end
        end
      RUBY
      result = evaluator.check(code: code)
      expect(result[:passed]).to be true
      expect(result[:flagged]).to be_empty
    end

    it 'flags shell invocations via system' do
      code = 'system("rm -rf /")'
      result = evaluator.check(code: code)
      expect(result[:passed]).to be false
      expect(result[:flagged].any? { |f| f[:pattern] == :shell_execution }).to be true
    end

    it 'flags backtick execution' do
      code = '`ls -la`'
      result = evaluator.check(code: code)
      expect(result[:passed]).to be false
      expect(result[:flagged].any? { |f| f[:pattern] == :backtick_execution }).to be true
    end

    it 'flags file deletion' do
      code = 'FileUtils.rm_rf("/tmp/data")'
      result = evaluator.check(code: code)
      expect(result[:passed]).to be false
      expect(result[:flagged].any? { |f| f[:pattern] == :file_deletion }).to be true
    end

    it 'flags eval/class_eval' do
      code = 'eval("puts 1")'
      result = evaluator.check(code: code)
      expect(result[:passed]).to be false
      expect(result[:flagged].any? { |f| f[:pattern] == :dynamic_code_execution }).to be true
    end

    it 'flags unsafe require' do
      code = 'require params[:gem_name]'
      result = evaluator.check(code: code)
      expect(result[:passed]).to be false
      expect(result[:flagged].any? { |f| f[:pattern] == :unsafe_require }).to be true
    end

    it 'flags send with dynamic method name' do
      code = 'obj.send(user_input)'
      result = evaluator.check(code: code)
      expect(result[:passed]).to be false
      expect(result[:flagged].any? { |f| f[:pattern] == :dynamic_dispatch }).to be true
    end

    it 'returns line numbers for flagged patterns' do
      code = "safe_line = 1\nsystem('bad')\nalso_safe = 2"
      result = evaluator.check(code: code)
      flagged = result[:flagged].first
      expect(flagged[:line]).to eq(2)
    end
  end
end
