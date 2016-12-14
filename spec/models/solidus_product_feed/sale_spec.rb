require 'spec_helper'

RSpec.describe SolidusProductFeed::Sale, type: :model do
  let!(:product) { create :product }
  let!(:sale) { described_class.new }

  describe "#price" do
    subject { sale.price(product) }
    it { is_expected.to be_nil }
  end

  describe "#effective_date" do
    subject { sale.effective_date(product) }
    it { is_expected.to be_nil }
  end

  describe "#sale_data_present?" do
    subject { sale.sale_data_present?(product) }
    it { is_expected.to eq false }

    context "when price is non-nil" do
      it "returns false if effective-date is missing" do
        allow_any_instance_of(SolidusProductFeed::Sale).to receive(:price).and_return(99)
        expect(subject).to eq false
      end
    end

    context "when effective_date is non-nil" do
      it "returns false if price is missing" do
        allow_any_instance_of(SolidusProductFeed::Sale).to receive(:effective_date)
          .and_return("2000-01-01/2222-12-12")
        expect(subject).to eq false
      end
    end

    context "when both #price and #effective_date return non-nil" do
      it "returns true" do
        allow_any_instance_of(SolidusProductFeed::Sale).to receive(:price).and_return(99)
        allow_any_instance_of(SolidusProductFeed::Sale).to receive(:effective_date)
          .and_return("2000-01-01/2222-12-12")
        expect(subject).to eq true
      end
    end

  end
end
