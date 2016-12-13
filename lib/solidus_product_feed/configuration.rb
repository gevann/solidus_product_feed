module SolidusProductFeed

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.config(&_block)
    yield(configuration)
  end

  class Configuration
    # Allows providing your own class for calculating shipping price.
    #
    # @!attribute [rw] shipping_price_class
    # @return [Class] a class with the same public interfaces
    #   as SolidusProductFeed::ShippingPrice.
    attr_writer :shipping_price_class
    attr_writer :tax_rate_class
    attr_writer :base_condition

    def shipping_price_class
      @shipping_price_class ||= '::SolidusProductFeed::ShippingPrice'
      @shipping_price_class.constantize
    end

    def tax_rate_class
      @tax_rate_class ||= '::SolidusProductFeed::TaxRate'
      @tax_rate_class.constantize
    end

    def base_condition
      @base_condition ||= "new"
      @base_condition
    end
  end
end
