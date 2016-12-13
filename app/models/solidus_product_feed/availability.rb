module SolidusProductFeed
  class Availability

    # Returns 'in stock' if any of the product's stock items are available,
    # otherwise returns 'out of stock'.
    #
    # @param product [Spree::Product] the product to check availability for
    #
    # @return [String] the availability of the product. One of 'in stock',
    #   'out of stock', 'preorder'
    def availability(product)
      product.stock_items.any?(&:available?) ? 'in stock' : 'out of stock'
    end
  end
end
