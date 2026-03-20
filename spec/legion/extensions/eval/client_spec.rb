# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Client do
  let(:client) { described_class.new }

  it 'includes Evaluation runner' do
    expect(client).to respond_to(:run_evaluation)
    expect(client).to respond_to(:list_evaluators)
  end

  describe '#build_evaluator' do
    it 'is publicly accessible' do
      expect(client).to respond_to(:build_evaluator)
    end

    it 'builds an LlmJudge from a template name' do
      evaluator = client.build_evaluator(:hallucination)
      expect(evaluator).to be_a(Legion::Extensions::Eval::Evaluators::LlmJudge)
    end

    it 'builds a CodeEvaluator when type is :code' do
      evaluator = client.build_evaluator(:custom, { type: :code, checks: [] })
      expect(evaluator).to be_a(Legion::Extensions::Eval::Evaluators::CodeEvaluator)
    end
  end
end
