module SolidusProductFeed
  class ShippingPrice
    def price(product)
      product.shipping_category.shipping_methods
        .flat_map(&:shipping_rates)
        .sort_by(&:cost)
        .first
        .cost
    end
  end
end
