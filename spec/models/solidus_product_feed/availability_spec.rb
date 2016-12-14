require "spec_helper"

RSpec.describe SolidusProductFeed::Availability, type: :model do
  subject { described_class.new.availability(product) }

  context "when count on hand is 0, and product is not backorderable" do
    let!(:product) { create :product_not_backorderable }
    before do
      product.stock_items.first.reduce_count_on_hand_to_zero
    end
    it { is_expected.to eq 'out of stock' }
  end

  context "when product count on hand is > 0" do
    let!(:product) { create :product_in_stock }
    it { is_expected.to eq 'in stock' }
  end

  context "when count on hand is 0, and product is backorderable" do
    let!(:product) { create :product }
    it { is_expected.to eq 'in stock' }
  end
end
