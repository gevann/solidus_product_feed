module SolidusProductFeed
  class Condition

    # Calculates the condition of a product, falling back
    # to the configured base condition.
    #
    # @return [String] the condition of the product.
    def condition(product)
      get_condition(product) || SolidusProductFeed.configuration.base_condition
    end

    private

    # Calculates the condition of the product.
    #
    # @return [String] the calculated condition of product, or
    #   nil if none available.
    def get_condition(product)
      nil
    end

  end
end
