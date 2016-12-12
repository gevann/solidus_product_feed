module SolidusProductFeed

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.config
    yield(configuration)
  end

  class Configuration
    # Allows providing your own class for calculating shipping price.
    #
    # @!attribute [rw] shipping_price_class
    # @return [Class] a class with the same public interfaces
    #   as SolidusProductFeed::ShippingPrice.
    attr_writer :shipping_price_class

    def shipping_price_class
      @shipping_price_class ||= '::SolidusProductFeed::ShippingPrice'
      @shipping_price_class.constantize
    end
  end
end
