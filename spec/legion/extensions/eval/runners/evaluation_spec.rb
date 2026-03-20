# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Runners::Evaluation do
  let(:host) { Object.new.extend(described_class) }

  describe '#run_evaluation' do
    context 'with code evaluator' do
      let(:inputs) do
        [
          { input: 'test1', output: 'hello 123', expected: nil },
          { input: 'test2', output: 'no number', expected: nil }
        ]
      end

      it 'returns results and summary' do
        result = host.run_evaluation(
          evaluator_name:   'check',
          evaluator_config: {
            type:   :code,
            checks: [{ type: 'regex', pattern: '\\d+', name: 'has_number' }]
          },
          inputs:           inputs
        )
        expect(result[:summary][:total]).to eq(2)
        expect(result[:summary][:passed]).to eq(1)
        expect(result[:summary][:failed]).to eq(1)
        expect(result[:summary][:avg_score]).to eq(0.5)
      end

      it 'includes row_index in each result' do
        result = host.run_evaluation(
          evaluator_name:   'check',
          evaluator_config: { type: :code, checks: [] },
          inputs:           inputs
        )
        expect(result[:results].map { |r| r[:row_index] }).to eq([0, 1])
      end
    end

    context 'with empty inputs' do
      it 'returns zero avg_score' do
        result = host.run_evaluation(
          evaluator_name:   'empty',
          evaluator_config: { type: :code, checks: [] },
          inputs:           []
        )
        expect(result[:summary][:avg_score]).to eq(0.0)
        expect(result[:summary][:total]).to eq(0)
      end
    end

    context 'with unknown evaluator type' do
      it 'raises ArgumentError' do
        expect do
          host.run_evaluation(
            evaluator_name:   'bad',
            evaluator_config: { type: :unknown },
            inputs:           [{ input: 'a', output: 'b' }]
          )
        end.to raise_error(ArgumentError, /unknown evaluator type/)
      end
    end
  end

  describe '#list_evaluators' do
    it 'returns built-in templates' do
      result = host.list_evaluators
      names = result[:evaluators].map { |e| e[:name] }
      expect(names).to include('hallucination', 'relevance', 'toxicity')
    end

    it 'returns all 12 built-in templates' do
      result = host.list_evaluators
      expect(result[:evaluators].size).to eq(12)
    end

    it 'includes category and requires_expected fields' do
      result = host.list_evaluators
      result[:evaluators].each do |tmpl|
        expect(tmpl).to have_key(:category)
        expect(tmpl).to have_key(:requires_expected)
      end
    end

    it 'includes all expected template names' do
      result = host.list_evaluators
      names = result[:evaluators].map { |e| e[:name] }
      expect(names).to contain_exactly(
        'hallucination', 'relevance', 'toxicity',
        'faithfulness', 'qa_correctness', 'sql_generation',
        'code_generation', 'code_readability', 'tool_calling',
        'human_vs_ai', 'rag_relevancy', 'summarization'
      )
    end
  end
end
