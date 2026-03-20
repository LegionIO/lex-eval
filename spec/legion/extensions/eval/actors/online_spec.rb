# frozen_string_literal: true

unless defined?(Legion::Extensions::Actors::Subscription)
  module Legion
    module Extensions
      module Actors
        class Subscription # rubocop:disable Lint/EmptyClass
        end
      end
    end
  end

  $LOADED_FEATURES << 'legion/extensions/actors/subscription'
end

require 'legion/extensions/eval/actors/online'

RSpec.describe Legion::Extensions::Eval::Actor::Online do
  subject(:actor) { described_class.new }

  describe 'constants' do
    it 'defines EXCHANGE' do
      expect(described_class::EXCHANGE).to eq('llm.response')
    end

    it 'defines QUEUE' do
      expect(described_class::QUEUE).to eq('eval.online')
    end
  end

  describe '#runner_class' do
    it 'returns the Online runner module' do
      expect(actor.runner_class).to eq(Legion::Extensions::Eval::Runners::Online)
    end
  end

  describe '#runner_function' do
    it 'returns evaluate_response' do
      expect(actor.runner_function).to eq('evaluate_response')
    end
  end

  describe '#check_subtask?' do
    it 'returns false' do
      expect(actor.check_subtask?).to be false
    end
  end

  describe '#generate_task?' do
    it 'returns false' do
      expect(actor.generate_task?).to be false
    end
  end

  describe '#use_runner?' do
    it 'returns false' do
      expect(actor.use_runner?).to be false
    end
  end

  describe '#enabled?' do
    context 'when transport is unavailable' do
      it 'returns false' do
        hide_const('Legion::Transport') if defined?(Legion::Transport)
        expect(actor.enabled?).to be false
      end
    end

    context 'when transport is available' do
      it 'returns true when online is enabled' do
        stub_const('Legion::Transport', Module.new)
        expect(actor.enabled?).to be true
      end
    end

    context 'when online is disabled via settings' do
      before do
        stub_const('Legion::Transport', Module.new)
        stub_const('Legion::Settings', Module.new do
          def self.dig(*_keys)
            false
          end
        end)
      end

      it 'returns false' do
        expect(actor.enabled?).to be false
      end
    end
  end
end
