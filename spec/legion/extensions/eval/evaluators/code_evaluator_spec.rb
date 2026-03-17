# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Evaluators::CodeEvaluator do
  describe '#evaluate' do
    context 'with regex and keyword checks' do
      let(:evaluator) do
        described_class.new(name: 'test', config: {
                              checks: [
                                { type: 'regex', pattern: '\\d+', name: 'has_number' },
                                { type: 'keyword_contains', keywords: ['hello'], name: 'has_hello' }
                              ]
                            })
      end

      it 'passes when all checks pass' do
        result = evaluator.evaluate(input: 'test', output: 'hello 123')
        expect(result[:passed]).to be true
        expect(result[:score]).to eq(1.0)
      end

      it 'fails with correct failure list' do
        result = evaluator.evaluate(input: 'test', output: 'no greeting 123')
        expect(result[:passed]).to be false
        expect(result[:failures]).to include('has_hello')
        expect(result[:score]).to eq(0.5)
      end

      it 'reports all failures' do
        result = evaluator.evaluate(input: 'test', output: 'nothing here')
        expect(result[:passed]).to be false
        expect(result[:failures]).to contain_exactly('has_number', 'has_hello')
        expect(result[:score]).to eq(0.0)
      end
    end

    context 'with length checks' do
      let(:evaluator) do
        described_class.new(name: 'length', config: {
                              checks: [
                                { type: 'min_length', length: 5, name: 'min_5' },
                                { type: 'max_length', length: 20, name: 'max_20' }
                              ]
                            })
      end

      it 'passes within bounds' do
        result = evaluator.evaluate(input: 'test', output: 'hello world')
        expect(result[:passed]).to be true
      end

      it 'fails below minimum' do
        result = evaluator.evaluate(input: 'test', output: 'hi')
        expect(result[:passed]).to be false
        expect(result[:failures]).to include('min_5')
      end
    end

    context 'with json_valid check' do
      let(:evaluator) do
        described_class.new(name: 'json', config: {
                              checks: [{ type: 'json_valid', name: 'valid_json' }]
                            })
      end

      it 'passes for valid JSON' do
        result = evaluator.evaluate(input: 'test', output: '{"key": "value"}')
        expect(result[:passed]).to be true
      end

      it 'fails for invalid JSON' do
        result = evaluator.evaluate(input: 'test', output: 'not json')
        expect(result[:passed]).to be false
      end
    end

    context 'with no checks' do
      let(:evaluator) { described_class.new(name: 'empty', config: {}) }

      it 'returns perfect score' do
        result = evaluator.evaluate(input: 'test', output: 'anything')
        expect(result[:score]).to eq(1.0)
        expect(result[:passed]).to be true
      end
    end
  end
end
