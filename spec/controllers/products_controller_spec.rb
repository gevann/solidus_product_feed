require 'spec_helper'

describe Spree::ProductsController, type: :controller do
  render_views

  context "GET #index" do
    subject { spree_get :index, format: 'rss' }

    let!(:product) { create :product, name: "2 Hams", price: 20.00 }

    it { is_expected.to have_http_status :ok }

    it { is_expected.to render_template 'spree/products/index' }

    it 'returns the correct content type' do
      subject
      expect(response.content_type).to eq 'application/rss+xml'
    end
  end
end
