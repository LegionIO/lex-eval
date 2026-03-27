# frozen_string_literal: true

require 'spec_helper'

# CodeReviewSubscriber requires Legion::Extensions::Actors::Subscription (LegionIO runtime).
# In standalone gem specs the base class is unavailable, so the actor file early-returns.
RSpec.describe 'Legion::Extensions::Eval::Actor::CodeReviewSubscriber' do
  it 'is not loaded without the LegionIO runtime' do
    expect(defined?(Legion::Extensions::Eval::Actor::CodeReviewSubscriber)).to be_falsey
  end
end
