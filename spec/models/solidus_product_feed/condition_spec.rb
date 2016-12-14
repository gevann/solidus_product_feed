require 'spec_helper'

RSpec.describe SolidusProductFeed::Condition, type: :model do
  let!(:product) { create :product }
  subject { described_class.new.condition(product) }

  it "defaults to 'new'" do
    expect(subject).to eq 'new'
  end

  context "when base_condition is configured" do
    before { SolidusProductFeed.configuration.base_condition = 'base_condition' }
    it "uses the configured base_condition" do
      expect(subject).to eq 'base_condition'
    end

    context "when condition object returns non-nil condition" do
      it "uses the condition objects value" do
        allow_any_instance_of(SolidusProductFeed::Condition).to receive(:get_condition)
          .and_return('condition_from_obj')
        expect(subject).to eq 'condition_from_obj'
      end
    end
  end

end
