# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Runners::Online do
  let(:host) do
    Object.new.tap do |obj|
      obj.extend(Legion::Extensions::Eval::Runners::Evaluation)
      obj.extend(described_class)
    end
  end

  let(:response) { { input: 'What is 2+2?', output: 'The answer is 4.' } }

  describe '#evaluate_response' do
    context 'when sampled in (sample_rate 1.0)' do
      before do
        allow(host).to receive(:run_evaluation).and_return(
          { summary: { avg_score: 0.9 } }
        )
      end

      it 'returns evaluated: true' do
        result = host.evaluate_response(response: response, evaluators: ['toxicity'], sample_rate: 1.0)
        expect(result[:evaluated]).to be true
      end

      it 'returns sampled: true' do
        result = host.evaluate_response(response: response, evaluators: ['toxicity'], sample_rate: 1.0)
        expect(result[:sampled]).to be true
      end

      it 'returns scores keyed by evaluator name' do
        result = host.evaluate_response(response: response, evaluators: ['toxicity'], sample_rate: 1.0)
        expect(result[:scores]).to have_key(:toxicity)
        expect(result[:scores][:toxicity]).to eq(0.9)
      end

      it 'runs multiple evaluators' do
        allow(host).to receive(:run_evaluation).and_return(
          { summary: { avg_score: 0.8 } }
        )
        result = host.evaluate_response(
          response:    response,
          evaluators:  %w[toxicity hallucination],
          sample_rate: 1.0
        )
        expect(result[:scores].keys).to contain_exactly(:toxicity, :hallucination)
      end
    end

    context 'when sampled out (sample_rate 0.0)' do
      it 'returns evaluated: false with reason :sampled_out' do
        result = host.evaluate_response(response: response, evaluators: ['toxicity'], sample_rate: 0.0)
        expect(result[:evaluated]).to be false
        expect(result[:reason]).to eq(:sampled_out)
        expect(result[:sampled]).to be false
      end
    end

    context 'when evaluators defaults from settings' do
      before do
        stub_const('Legion::Settings', Module.new do
          def self.dig(*_keys)
            %w[toxicity]
          end
        end)
        allow(host).to receive(:run_evaluation).and_return(
          { summary: { avg_score: 0.7 } }
        )
      end

      it 'uses configured evaluators when none passed' do
        result = host.evaluate_response(response: response, sample_rate: 1.0)
        expect(result[:evaluated]).to be true
        expect(result[:scores]).to have_key(:toxicity)
      end
    end

    context 'when Legion::Settings is not defined' do
      before do
        hide_const('Legion::Settings') if defined?(Legion::Settings)
        allow(host).to receive(:run_evaluation).and_return(
          { summary: { avg_score: 0.5 } }
        )
      end

      it 'falls back to default evaluators' do
        result = host.evaluate_response(response: response, sample_rate: 1.0)
        expect(result[:evaluated]).to be true
        expect(result[:scores]).to have_key(:toxicity)
      end
    end

    context 'when an evaluator raises an error' do
      before do
        allow(host).to receive(:run_evaluation).and_raise(StandardError, 'LLM unavailable')
      end

      it 'returns nil score for the failing evaluator' do
        result = host.evaluate_response(response: response, evaluators: ['toxicity'], sample_rate: 1.0)
        expect(result[:evaluated]).to be true
        expect(result[:scores][:toxicity]).to be_nil
      end
    end

    context 'when a top-level error occurs' do
      before do
        allow(host).to receive(:configured_evaluators).and_raise(RuntimeError, 'catastrophic')
      end

      it 'returns evaluated: false with error key' do
        result = host.evaluate_response(response: response, sample_rate: 1.0)
        expect(result[:evaluated]).to be false
        expect(result[:reason]).to eq(:error)
        expect(result[:error]).to include('catastrophic')
      end
    end
  end
end
