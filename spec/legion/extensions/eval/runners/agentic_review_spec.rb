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

  describe '#review_experiment' do
    context 'when output_a scores higher' do
      before do
        call_count = 0
        allow(Legion::LLM).to receive(:structured) do
          call_count += 1
          if call_count == 1
            { confidence: 0.9, recommendation: 'approve', issues: [], explanation: 'Excellent.' }
          else
            { confidence: 0.6, recommendation: 'revise', issues: [], explanation: 'Decent.' }
          end
        end
      end

      it 'declares output_a as winner' do
        result = host.review_experiment(input: 'q', output_a: 'good answer', output_b: 'ok answer')
        expect(result[:winner]).to eq(:a)
        expect(result[:reviewed]).to be true
      end

      it 'calculates positive delta' do
        result = host.review_experiment(input: 'q', output_a: 'good', output_b: 'ok')
        expect(result[:delta]).to eq(0.3)
      end
    end

    context 'when output_b scores higher' do
      before do
        call_count = 0
        allow(Legion::LLM).to receive(:structured) do
          call_count += 1
          if call_count == 1
            { confidence: 0.5, recommendation: 'revise', issues: [], explanation: 'Weak.' }
          else
            { confidence: 0.85, recommendation: 'approve', issues: [], explanation: 'Strong.' }
          end
        end
      end

      it 'declares output_b as winner' do
        result = host.review_experiment(input: 'q', output_a: 'weak', output_b: 'strong')
        expect(result[:winner]).to eq(:b)
        expect(result[:reviewed]).to be true
      end

      it 'calculates negative delta' do
        result = host.review_experiment(input: 'q', output_a: 'weak', output_b: 'strong')
        expect(result[:delta]).to eq(-0.35)
      end
    end

    context 'when scores are within 0.05 of each other' do
      before do
        call_count = 0
        allow(Legion::LLM).to receive(:structured) do
          call_count += 1
          if call_count == 1
            { confidence: 0.8, recommendation: 'approve', issues: [], explanation: 'Good.' }
          else
            { confidence: 0.78, recommendation: 'approve', issues: [], explanation: 'Good too.' }
          end
        end
      end

      it 'declares a tie' do
        result = host.review_experiment(input: 'q', output_a: 'answer a', output_b: 'answer b')
        expect(result[:winner]).to eq(:tie)
        expect(result[:reviewed]).to be true
      end
    end

    context 'when both reviews are included in the result' do
      before do
        call_count = 0
        allow(Legion::LLM).to receive(:structured) do
          call_count += 1
          if call_count == 1
            { confidence: 0.9, recommendation: 'approve', issues: [], explanation: 'A is great.' }
          else
            { confidence: 0.6, recommendation: 'revise', issues: [], explanation: 'B is ok.' }
          end
        end
      end

      it 'includes review_a and review_b in result' do
        result = host.review_experiment(input: 'q', output_a: 'a', output_b: 'b')
        expect(result[:review_a]).to include(confidence: 0.9, explanation: 'A is great.')
        expect(result[:review_b]).to include(confidence: 0.6, explanation: 'B is ok.')
      end
    end

    context 'when review_output raises an error' do
      before do
        allow(host).to receive(:review_output).and_raise(StandardError, 'LLM unavailable')
      end

      it 'returns reviewed: false with reason' do
        result = host.review_experiment(input: 'q', output_a: 'a', output_b: 'b')
        expect(result[:reviewed]).to be false
        expect(result[:reason]).to include('experiment error')
        expect(result[:reason]).to include('LLM unavailable')
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
