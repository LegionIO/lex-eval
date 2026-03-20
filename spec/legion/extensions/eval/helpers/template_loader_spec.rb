# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Helpers::TemplateLoader do
  let(:loader) { described_class.new }

  describe '#load_template' do
    context 'without lex-prompt' do
      it 'loads from bundled YAML' do
        result = loader.load_template('hallucination')
        expect(result[:name]).to eq('hallucination')
        expect(result[:template]).to be_a(String)
        expect(result[:threshold]).to be_a(Numeric)
      end

      it 'returns nil for unknown template' do
        expect(loader.load_template('nonexistent')).to be_nil
      end
    end

    context 'with lex-prompt available' do
      let(:prompt_client) { double('prompt_client') }

      before do
        allow(loader).to receive(:prompt_client).and_return(prompt_client)
        allow(loader).to receive(:prompt_client_available?).and_return(true)
      end

      it 'loads from lex-prompt when available' do
        allow(prompt_client).to receive(:get_prompt).and_return(
          { name: 'eval.hallucination', template: 'custom prompt', version: 2 }
        )
        result = loader.load_template('hallucination')
        expect(result[:template]).to eq('custom prompt')
      end

      it 'falls back to YAML when lex-prompt returns error' do
        allow(prompt_client).to receive(:get_prompt).and_return({ error: 'not_found' })
        result = loader.load_template('hallucination')
        expect(result[:name]).to eq('hallucination')
      end
    end
  end

  describe '#list_templates' do
    it 'returns all 12 bundled templates' do
      result = loader.list_templates
      expect(result.size).to eq(12)
    end
  end

  describe '#seed_prompts' do
    let(:prompt_client) { double('prompt_client') }

    before do
      allow(loader).to receive(:prompt_client).and_return(prompt_client)
      allow(loader).to receive(:prompt_client_available?).and_return(true)
    end

    it 'creates prompts in lex-prompt for all templates' do
      allow(prompt_client).to receive(:get_prompt).and_return({ error: 'not_found' })
      allow(prompt_client).to receive(:create_prompt).and_return({ created: true })
      allow(prompt_client).to receive(:tag_prompt).and_return({ tagged: true })

      loader.seed_prompts
      expect(prompt_client).to have_received(:create_prompt).exactly(12).times
    end

    it 'skips templates that already exist in lex-prompt' do
      allow(prompt_client).to receive(:get_prompt).and_return({ name: 'existing', template: 'x' })

      loader.seed_prompts
      expect(prompt_client).not_to have_received(:create_prompt) if prompt_client.respond_to?(:create_prompt)
    end
  end
end
