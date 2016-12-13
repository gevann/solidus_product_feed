module Spree
  class SchemaError < StandardError
    def initialize msg, product
      super("Missing mandatory #{msg}. Skipping feed entry for #{product.inspect}")
    end
  end

  class FeedProductPresenter
    # @!attribute schema
    #   @return [Array <Symbol, Hash>] the nested schema to use in xml generation
    #
    # @!attribute properties
    #   @return [Array <Symbol>] the product properties list to use in accessor creation.
    attr_accessor :schema, :properties
    # Creates FeedProductPresenter for presenting products as items
    # in RSS feed for Google Merchant
    #
    # @param view [ActionView view context] the view being rendered.
    #
    # @param product [Spree::Product] the product to display. It must
    #   have its own landing page, which is why variants are not supported
    #   at this time.
    #
    # @param properties [Array <Symbol>] all of the product data which is
    #   obtained from the product.properties
    def initialize(view, product, properties: nil)

      @view = view
      @product = product
      @schema = [
        :id, :title, :description, :image_link, :price, :availability,
        :identifier_exists, :link, :condition,
        {parent: :shipping, schema: [:price]},
        {parent: :tax, schema: [:rate]},
      ]

      # Automatically include any product_property which defines
      # values for any of the following:
      @properties = [:brand, :gtin, :mpn, :google_product_category,
                     :adult, :multipack, :is_bundle, :energy_efficiency_class,
                     :age_group, :color, :gender, :material, :pattern, :size,
                     :size_type, :size_system, :item_group_id, :product_type,
                     :unit_pricing_measure, :unit_pricing_base_measure]

      # For each property listed, if the product has a property
      # associated with it which matches, create an instance method
      # of the same name which retrieves the property value.
      @properties.each do |prop|
        next unless @product.property(prop.to_s)
        @schema << prop
        self.class.send(:define_method, prop) do
          @product.property(prop.to_s)
        end
      end

      @sale_obj ||= SolidusProductFeed.configuration.sale_class.new
      # Include sale price and effective date if given an object
      # for them in the config or overrides for them found
      # in the products properties.
      if @sale_obj.sale_data_present?(@product) || %w(sale_price_for_feed sale_price_effective_date_for_feed).map { |x| @product.property(x).present? }.all?
        @schema += [:sale_price, :sale_price_effective_date]
      end
    end

    # Creates an <item> RSS feed entry of the
    # product, corresponding with Google's requested schema. If a
    # mandatory element of the schema is missing, a SchemaError is
    # raised, the entire <item> entry for this product is skipped,
    # and an error is logged to the configured log file or STDERR.
    #
    # @param xml [Builder::XmlMarkup]
    # @return String, the xml <item> tag and content for this product.
    def item xml
      @xml ||= xml
      valid = begin
                draw(schema: schema, parent: nil, validate_only: true)
              rescue SchemaError => e
                SolidusProductFeed.logger.warn { e.message }
                false
              end

      if valid
        @xml.item do
          draw(schema: schema, parent: nil)
        end
      end
    end

    private

    # Computes the parameters for an xml tag of <datum>
    #
    # @param entry [Symbol] the name of the xml tag
    #   and instance method name which computes it's contents.
    # @param parent [Symbol] the name of the surrounding tag, or nil
    #   if none.
    # @return [Array <String>] the tag name and content for an
    #   xml tag.
    def tag_params_for parent, entry
      ["g:#{entry}", self.send(scoped_name(parent, entry))]
    end

    # Recursively produces xml tags representing product for
    # an xml feed.
    #
    # @param feed_product [Spree::FeedProductPresenter] the product to display
    # @param schema [Array <Symbol, Hash>] the schema to draw
    # @param parent [:Symbol, nil] the parent tag to nest within.
    # @return [String] the xml formatted string content for this products
    #   <item> tag
    def draw(schema:, parent:, validate_only: false)
      schema.each do |entry|
        if entry.is_a? Symbol
          type, content = tag_params_for(parent, entry)
          @xml.tag! type, content unless validate_only
        else
          if validate_only
            draw(**entry, validate_only: true)
          else
            @xml.tag! "g:#{entry[:parent]}" do
              draw(**entry)
            end
          end
        end
      end
    end

    # Creates scoped method names.
    #
    # @param parent [Symbol] the parent scope
    # @param name [Symbol] the method name
    # @return [Symbol] the fully scoped method name.
    def scoped_name parent, name
      if parent.present?
        "#{parent}_#{name}".to_sym
      else
        name
      end
    end

    # Sets the instance variable @`calling_function_name`
    # to the value of any product property ending in '_for_feed', if it exists, or
    # the value of the block given.
    # Raises a SchemaError if no value found, and returns the value set.
    # Uses the name of the calling function as a prefix, and '_for_feed' as
    # a suffix for the property to look up.
    #
    # @param backup the value to use if no override is found.
    # @raise [SchemaError] if no value is found for the give schema entry.
    # @return the value of @`calling_function_name`.
    def override(&block)
      the_caller = caller_locations[0].label
      val = self.instance_variable_get("@#{the_caller}")
      return val if val.present?
      override_val = @product.property("#{the_caller}_for_feed".to_sym)
      if override_val.present?
        self.instance_variable_set("@#{the_caller}", override_val)
      else
        self.instance_variable_set("@#{the_caller}", block.call)
      end

      val = self.instance_variable_get("@#{the_caller}")
      raise SchemaError.new("#{the_caller}", @product) unless val
      val
    end

    # Gives the formatted price of the product
    #
    # @return [String] the products formatted price.
    def price
      override do
        Spree::Money.new(@product.price)
          .money.format(symbol: false, with_currency: true)
      end
    end

    # Gives the formatted sale_price of the product.
    # Must be configured with an object which responds to #sale_price and #effective_date as
    # Rails.application.config.solidus_product_feed_sale_price_calculator
    #
    # @return [String] the products formatted sale_price.
    def sale_price
      override do
        Spree::Money.new(@sale_obj.price(@product))
          .money.format(symbol: false, with_currency: true)
      end
    end

    # Gives the date range within which the sale price is effective.
    #
    # @return [Date Range] the ISO 8601 standard date range
    def sale_price_effective_date
      override { @sale_obj.effective_date(@product) }
    end

    # Gives the URI of the product
    #
    # @return [String] the uri of the product.
    def link
      override { @view.product_url(@product) }
    end

    # Gives the formatted price of shipping for the product
    #
    # @return [String] the configured base shipping price, or
    #   the minimum shipping available for this product.
    def shipping_price
      override do
        Spree::Money.new(SolidusProductFeed.configuration.shipping_price_class.new.price(@product))
          .money.format(symbol: false, with_currency: true)
      end
    end

    # @return [String] the product sku
    def id
      override { @product.sku }
    end

    # @return [String] the product name
    def title
      override { @product.name }
    end

    # @return [String] the product description
    def description
      override { @product.description }
    end

    # Returns the configured basic condition for products, or
    # this products condition via product.property.
    #
    # @return [String] the product condition.
    def condition
      override { SolidusProductFeed.configuration.base_condition }
    end

    # Computes whether this product has a brand
    # and either, a GTIN number or an MPN number.
    #
    # @return [String] `no`, `yes`
    def identifier_exists
      ( brand? && (gtin? || mpn?) ) ? 'yes' : 'no'
    end

    # Gives the mandatory URL of the image of the product.
    #
    # @return [String, nil] a URL of an image of the product
    def image_link
      override do
        images =
          @product.images.any? ? @product.images : @product.variants.flat_map { |v| v.images }
        images == [] ? nil : images.first.attachment.url(:large)
      end
    end

    # Computes the availability status of the product
    # @return [String] the availability status of the product.
    #   One of `in stock`, `out of stock`.
    def availability
      override { SolidusProductFeed.configuration.availability_class.new.availability(@product) }
    end

    # Returns the most frequently used tax rate for this item. If no tax rate
    # has been applied to the variant, the first tax rate is chosen.
    #
    # @return [BigDecimal] the tax rate in precent.
    def tax_rate
      override { SolidusProductFeed.configuration.tax_rate_class.new.tax_rate(@product) }
    end

    # Computes whether or not a product property for brand is present.
    #
    # @return [TrueClass, FalseClass]
    def brand?
      @product.property('brand').present?
    end

    # Computes where or not a product property for gtin is present.
    #
    # @return [TrueClass, FalseClass]
    def gtin?
      @product.property('gtin').present?
    end

    # Computes where or not a product property for mpn is present.
    #
    # @return [TrueClass, FalseClass]
    def mpn?
      @product.property('mpn').present?
    end

    def sale_price_effective_date?
      @product.property('sale_price_effective_date').present?
    end
  end
end
