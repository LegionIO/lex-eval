# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Runners::AgenticReview do
  let(:host) { Object.new.extend(described_class) }

  before do
    stub_const('Legion::LLM', Class.new do
      def self.structured(**); end

      def self.respond_to_missing?(name, *)
        name == :structured || super
      end
    end)
  end

  describe '#review_output' do
    let(:review_result) do
      { confidence: 0.92, recommendation: 'approve',
        issues: [], explanation: 'Output is well-structured.' }
    end

    before { allow(Legion::LLM).to receive(:structured).and_return(review_result) }

    it 'returns review with confidence and recommendation' do
      result = host.review_output(input: 'question', output: 'answer')
      expect(result[:confidence]).to eq(0.92)
      expect(result[:recommendation]).to eq('approve')
    end

    it 'uses custom review prompt when provided' do
      host.review_output(input: 'q', output: 'a', review_prompt: 'Be strict.')
      expect(Legion::LLM).to have_received(:structured).with(
        hash_including(message: include('Be strict.'))
      )
    end
  end

  describe '#review_with_escalation' do
    context 'high confidence (> 0.9)' do
      before do
        allow(Legion::LLM).to receive(:structured).and_return(
          { confidence: 0.95, recommendation: 'approve', issues: [], explanation: 'Good.' }
        )
      end

      it 'auto-approves' do
        result = host.review_with_escalation(input: 'q', output: 'a')
        expect(result[:action]).to eq(:auto_approve)
        expect(result[:escalated]).to be false
      end
    end

    context 'medium confidence (0.6-0.9)' do
      before do
        allow(Legion::LLM).to receive(:structured).and_return(
          { confidence: 0.75, recommendation: 'revise',
            issues: [{ severity: 'minor', description: 'typo' }], explanation: 'Mostly fine.' }
        )
      end

      it 'escalates to light review' do
        result = host.review_with_escalation(input: 'q', output: 'a')
        expect(result[:action]).to eq(:light_review)
        expect(result[:escalated]).to be true
        expect(result[:priority]).to eq(:low)
      end
    end

    context 'low confidence (< 0.6)' do
      before do
        allow(Legion::LLM).to receive(:structured).and_return(
          { confidence: 0.3, recommendation: 'reject',
            issues: [{ severity: 'critical', description: 'wrong' }], explanation: 'Bad.' }
        )
      end

      it 'escalates to full review' do
        result = host.review_with_escalation(input: 'q', output: 'a')
        expect(result[:action]).to eq(:full_review)
        expect(result[:escalated]).to be true
        expect(result[:priority]).to eq(:high)
      end
    end
  end

  describe '#review_output error handling' do
    before do
      allow(Legion::LLM).to receive(:structured).and_raise(StandardError, 'LLM unavailable')
    end

    it 'returns error hash on failure' do
      result = host.review_output(input: 'q', output: 'a')
      expect(result[:confidence]).to eq(0.0)
      expect(result[:recommendation]).to eq('reject')
      expect(result[:explanation]).to include('LLM unavailable')
    end
  end
end
