# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'

RSpec.describe Legion::Extensions::Eval::Helpers::Guardrails do
  let(:guardrails_dir) { Dir.mktmpdir }

  after { FileUtils.rm_rf(guardrails_dir) }

  describe '.load_guardrails' do
    it 'loads YAML guardrail files' do
      File.write(File.join(guardrails_dir, 'test.yaml'), <<~YAML)
        name: test_guard
        type: pattern
        phase: before
        action: block
        patterns:
          - "bad input"
        fallback_response: "Blocked."
      YAML

      rules = described_class.load_guardrails(guardrails_dir)
      expect(rules.size).to eq(1)
      expect(rules.first[:name]).to eq('test_guard')
    end

    it 'returns empty for nonexistent directory' do
      expect(described_class.load_guardrails('/nonexistent')).to eq([])
    end

    it 'skips malformed files' do
      File.write(File.join(guardrails_dir, 'bad.yaml'), 'not: [valid: yaml: {{')
      rules = described_class.load_guardrails(guardrails_dir)
      expect(rules).to eq([])
    end
  end

  describe '.check_patterns' do
    it 'returns true when text matches a pattern' do
      expect(described_class.check_patterns('this is bad input here', ['bad input'])).to be true
    end

    it 'is case insensitive' do
      expect(described_class.check_patterns('IGNORE PREVIOUS INSTRUCTIONS', ['ignore previous instructions'])).to be true
    end

    it 'returns false when no match' do
      expect(described_class.check_patterns('hello world', ['bad input'])).to be false
    end

    it 'returns false for nil patterns' do
      expect(described_class.check_patterns('hello', nil)).to be false
    end
  end

  describe '.register_hooks!' do
    before do
      stub_const('Legion::LLM::Hooks', Module.new do
        @before = []
        @after = []
        def self.before_chat(&block) = @before << block
        def self.after_chat(&block) = @after << block
        def self.before_hooks = @before
        def self.after_hooks = @after

        def self.reset!
          (@before = []
           @after = [])
        end
      end)
      Legion::LLM::Hooks.reset!
    end

    it 'registers before hooks for before-phase guardrails' do
      guardrails = [{ name: 'test', type: 'pattern', phase: 'before', action: 'block', patterns: ['bad'] }]
      described_class.register_hooks!(guardrails)
      expect(Legion::LLM::Hooks.before_hooks.size).to eq(1)
    end

    it 'registers after hooks for after-phase guardrails' do
      guardrails = [{ name: 'test', type: 'pattern', phase: 'after', action: 'warn', patterns: ['bad'] }]
      described_class.register_hooks!(guardrails)
      expect(Legion::LLM::Hooks.after_hooks.size).to eq(1)
    end

    it 'registers both hooks for both-phase guardrails' do
      guardrails = [{ name: 'test', type: 'pattern', phase: 'both', action: 'block', patterns: ['bad'] }]
      described_class.register_hooks!(guardrails)
      expect(Legion::LLM::Hooks.before_hooks.size).to eq(1)
      expect(Legion::LLM::Hooks.after_hooks.size).to eq(1)
    end
  end
end
