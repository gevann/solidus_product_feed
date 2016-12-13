module SolidusProductFeed
  class Sale
    # @param product [Spree::Product] the product to calculate the tax rate for.
    # @return [FixNum] the sale price of the product, or nil if no sale.
    def price(product); nil; end

    # @param product [Spree::Product] the product to calculate the tax rate for.
    # @return [Date Range] the ISO 8601 standard date range, or nil if no sale.
    def effective_date(product); nil; end

    # @return [Boolean] whether or not both #price and #effective_date return
    # non-nil values.
    def sale_data_present?(product)
      !!(price(product) && effective_date(product))
    end
  end
end
