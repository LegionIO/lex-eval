# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::Eval::Client do
  it 'includes Evaluation runner' do
    client = described_class.new
    expect(client).to respond_to(:run_evaluation)
    expect(client).to respond_to(:list_evaluators)
  end
end
