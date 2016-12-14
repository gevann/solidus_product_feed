require "spec_helper"

RSpec.describe SolidusProductFeed::TaxRate, type: :model do

  describe "#tax_rate" do
    subject { described_class.new.tax_rate(product) }

    let!(:product) { create :product, name: "Thing", description: "Desc. of thing." }
    let!(:tax_rate_1) { create :tax_rate, tax_category: product.tax_category }
    let!(:tax_rate_2) { create :tax_rate, tax_category: product.tax_category, amount: 0.5 }

    context "when there are tax rates on line items for this product" do
      let(:order) { create :order }
      let(:line_item_rate_1) { create :line_item, product: product, variant: product.master }
      let(:line_items_rate_2) { create_list :line_item, 3, product: product, variant: product.master }
      let!(:adjustment_1) do
        create :tax_adjustment, order: order, adjustable: line_item_rate_1, source: tax_rate_1
      end
      let!(:adjustment_2) {
        line_items_rate_2.map do |line_item_rate_2|
          create :tax_adjustment, order: order, adjustable: line_item_rate_2,
            source: tax_rate_2
        end
      }

      it { is_expected.to eq tax_rate_2.amount * 100.0 }
    end

    context "when there are no tax rates applied to any line item for this product" do
      it { is_expected.to eq tax_rate_1.amount * 100.0 }
    end
  end
end
