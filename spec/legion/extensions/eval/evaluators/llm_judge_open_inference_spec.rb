# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'LlmJudge OpenInference instrumentation' do
  let(:config) { { name: 'hallucination', type: :llm_judge, template: 'Evaluate {{output}}', threshold: 0.5 } }
  let(:evaluator) { Legion::Extensions::Eval::Evaluators::LlmJudge.new(name: 'hallucination', config: config) }

  before do
    stub_const('Legion::Telemetry::OpenInference', Module.new do
      def self.open_inference_enabled?
        true
      end

      def self.evaluator_span(**)
        yield(nil)
      end
    end)

    stub_const('Legion::LLM', Class.new do
      def self.structured(**)
        { score: 0.85, passed: true, explanation: 'Good.', evidence: [] }
      end

      def self.respond_to_missing?(name, *)
        name == :structured || super
      end
    end)
    allow(Legion::LLM).to receive(:respond_to?).and_call_original
  end

  it 'wraps evaluate in evaluator_span' do
    expect(Legion::Telemetry::OpenInference).to receive(:evaluator_span)
      .with(hash_including(template: 'hallucination'))
      .and_yield(nil)

    evaluator.evaluate(input: 'q', output: 'a')
  end

  it 'works without OpenInference loaded' do
    hide_const('Legion::Telemetry::OpenInference')
    result = evaluator.evaluate(input: 'q', output: 'a')
    expect(result[:score]).to eq(0.85)
  end
end
