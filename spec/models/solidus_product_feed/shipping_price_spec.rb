require "spec_helper"

RSpec.describe SolidusProductFeed::ShippingPrice, type: :model do
  let!(:product) do
    create :product,
      name: "2 Hams 20 Dollars",
      description: "As seen on TV!"
  end
  let!(:shipping_method_1) { create :shipping_method }
  let!(:shipping_rate_1) do
    create :shipping_rate, cost: 11.1, shipping_method: shipping_method_1
  end

  describe "#price" do
    subject { SolidusProductFeed::ShippingPrice.new.price(product) }
    it { is_expected.to eq 11.1 }
    context "with more than one shipping method available" do
      let!(:cheapest_shipping_method) { create :free_shipping_method }
      let!(:cheapest_shipping_rate) do
        create :shipping_rate, cost: 0.0, shipping_method: cheapest_shipping_method
      end
      it { is_expected.to eq 0.0 }
    end
  end
end
