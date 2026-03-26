# frozen_string_literal: true

require 'spec_helper'

require 'legion/extensions/eval/actors/code_review_subscriber'

RSpec.describe Legion::Extensions::Eval::Actor::CodeReviewSubscriber do
  let(:actor_instance) do
    obj = Object.new
    obj.extend(described_class)
    obj
  end

  describe '#action' do
    let(:payload) do
      {
        generation_id: 'gen_123',
        runner_code:   'module Legion; module Generated; def self.greet; end; end; end',
        spec_code:     '',
        context:       {}
      }
    end

    before do
      allow(Legion::Settings).to receive(:dig).and_return(nil)
      allow(Legion::Settings).to receive(:dig).with(:codegen, :self_generate, :validation).and_return({
                                                                                                        syntax_check: true,
                                                                                                        run_specs:    false,
                                                                                                        llm_review:   false,
                                                                                                        quality_gate: { enabled: false }
                                                                                                      })
    end

    it 'calls CodeReview.review_generated' do
      expect(Legion::Extensions::Eval::Runners::CodeReview).to receive(:review_generated).and_call_original
      actor_instance.action(payload)
    end

    it 'returns review result' do
      result = actor_instance.action(payload)
      expect(result).to have_key(:passed)
      expect(result).to have_key(:verdict)
    end
  end
end
