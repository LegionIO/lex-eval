# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Evaluators::LlmJudge do
  let(:evaluator) do
    described_class.new(name: 'test_judge', config: {
                          template:  'Rate this: {{input}} -> {{output}} (expected: {{expected}})',
                          scale:     10,
                          threshold: 0.7
                        })
  end

  let(:llm_response) { double('response', content: 'Score: 8/10. Good output.') }

  before do
    stub_const('Legion::LLM', Class.new { def self.chat(**); end })
    allow(Legion::LLM).to receive(:chat).and_return(llm_response)
  end

  describe '#evaluate' do
    it 'returns a passing score when above threshold' do
      result = evaluator.evaluate(input: 'question', output: 'answer', expected: 'answer')
      expect(result[:score]).to eq(0.8)
      expect(result[:passed]).to be true
    end

    it 'extracts score from LLM response' do
      allow(llm_response).to receive(:content).and_return('Rating: 3/10. Poor.')
      result = evaluator.evaluate(input: 'q', output: 'a')
      expect(result[:score]).to eq(0.3)
      expect(result[:passed]).to be false
    end

    it 'defaults to 0.5 when no score found' do
      allow(llm_response).to receive(:content).and_return('No numeric rating here.')
      result = evaluator.evaluate(input: 'q', output: 'a')
      expect(result[:score]).to eq(0.5)
    end

    it 'handles LLM errors gracefully' do
      allow(Legion::LLM).to receive(:chat).and_raise(StandardError, 'timeout')
      result = evaluator.evaluate(input: 'q', output: 'a')
      expect(result[:score]).to eq(0.0)
      expect(result[:passed]).to be false
      expect(result[:explanation]).to include('timeout')
    end

    it 'renders template with input, output, and expected' do
      evaluator.evaluate(input: 'my_input', output: 'my_output', expected: 'my_expected')
      expect(Legion::LLM).to have_received(:chat).with(
        message: 'Rate this: my_input -> my_output (expected: my_expected)',
        intent:  { capability: :reasoning }
      )
    end
  end

  context 'with structured output (function calling)' do
    let(:structured_result) do
      { score: 0.85, passed: true, explanation: 'Well grounded.', evidence: ['quote 1'] }
    end

    before do
      stub_const('Legion::LLM', Class.new do
        def self.chat(**); end
        def self.structured(**); end
      end)
      allow(Legion::LLM).to receive(:respond_to?).and_call_original
      allow(Legion::LLM).to receive(:structured).and_return(structured_result)
    end

    it 'uses structured output when available' do
      result = evaluator.evaluate(input: 'q', output: 'a')
      expect(result[:score]).to eq(0.85)
      expect(result[:passed]).to be true
      expect(result[:explanation]).to eq('Well grounded.')
      expect(result[:evidence]).to eq(['quote 1'])
    end

    it 'passes JUDGE_SCHEMA to structured call' do
      evaluator.evaluate(input: 'q', output: 'a')
      expect(Legion::LLM).to have_received(:structured).with(
        hash_including(schema: Legion::Extensions::Eval::Evaluators::LlmJudge::JUDGE_SCHEMA)
      )
    end
  end

  context 'structured output fallback to regex' do
    before do
      stub_const('Legion::LLM', Class.new do
        def self.chat(**); end
        def self.structured(**); end
      end)
      allow(Legion::LLM).to receive(:respond_to?).and_call_original
      allow(Legion::LLM).to receive(:structured).and_raise(StandardError, 'structured failed')
      allow(Legion::LLM).to receive(:chat).and_return(llm_response)
    end

    it 'falls back to regex extraction' do
      result = evaluator.evaluate(input: 'q', output: 'a')
      expect(result[:score]).to eq(0.8)
      expect(result[:passed]).to be true
    end
  end
end
