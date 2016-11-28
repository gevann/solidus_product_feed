module Spree
  class FeedProductPresenter < BaseXmlPresenter
    def initialize(view, model)
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
      super
    end

    protected
    # Gives the formatted price of the model
    #
    # @return [String] the products formatted price.
    def price
      raise SchemaError.new('price', @model) unless @model.price
      @price ||= Spree::Money.new(@model.price)
      @price.money.format(symbol: false, with_currency: true)
    end

    # Gives the URI of the model
    #
    # @return [String] the uri of the model.
    def link
      @product_url ||= @view.product_url(@model)
      raise SchemaError.new('link', @model) unless @product_url.present?
      @product_url
    end

    # Gives the formatted price of shipping for the model
    #
    # @return [String] the configured base shipping price, or
    #   the minimum shipping available for this model.
    def shipping_price
      @shipping_price ||=
        if bsp = Rails.configuration.try(:base_shipping_price)
          Spree::Money.new(bsp)
        else
          Spree::Money.new(
            @model.shipping_category.shipping_methods
            .flat_map(&:shipping_rates)
            .sort_by(&:cost)
            .first
            .cost)
        end
      raise SchemaError unless @shipping_price.present?
      @shipping_price.money.format(symbol: false, with_currency: true)
    end

    # @return [String] the product sku
    def id
      @id ||= @model.sku
      raise SchemaError.new('id', @model) unless @id
      @id
    end

    # @return [String] the model name
    def title
      @title ||= @model.name
      raise SchemaError.new('title', @model) unless @title.present?
      @title
    end

    # @return [String] the product description
    def description
      @description ||= @model.description
      raise SchemaError.new('description', @model) unless @description.present?
      @description
    end

    # Returns the configured basic condition for products, or
    # this products condition via product.property.
    #
    # @return [String] the product condition.
    def condition
      @condition ||=
        Rails.configuration.try(:base_product_condition) || @model.property('condition') || 'new'
      raise SchemaError.new('condition', @model) unless @condition.present?
      @condition
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
      @images ||= @model.images.any? ? @model.images : @model.variants.flat_map { |v| v.images }
      raise SchemaError.new('image link', @model) unless @images.length > 0
      @image_link ||= @images.first.attachment.url(:large)
      @image_link
    end

    # Computes the availability status of the product
    # @return [String] the availability status of the product.
    #   One of `in stock`, `out of stock`.
    def availability
      @availability ||= @model.stock_items.any?(&:available?) ? 'in stock' : 'out of stock'
      raise SchemaError.new('availability', @model) unless @availability.present?
      @availability
    end

    # Returns the most frequently used tax rate for this item. If no tax rate
    # has been applied to the variant, the first tax rate is chosen.
    #
    # @return [BigDecimal] the tax rate in precent.
    def tax_rate
      rates = Spree::TaxRate.joins(:adjustments)
        .joins('INNER JOIN spree_line_items '\
        'ON spree_adjustments.adjustable_id = spree_line_items.id '\
        'AND spree_adjustments.adjustable_type = \'Spree::LineItem\'')
        .where('spree_line_items.variant_id = ?', @model.master.id)
        .group('spree_tax_rates.id')

      @tax_rate ||=
        if rates.present?
          tr_id = rates.count.map(&:flatten).sort_by { |id, count| -count }.first.first
          Spree::TaxRate.find(tr_id).amount * 100.0
        else
          @model.master.tax_category.tax_rates.first.amount * 100.0
        end
      raise SchemaError.new('tax rate', @model) unless @tax_rate.present?
      @tax_rate
    end

    # Computes whether or not a product property for brand is present.
    #
    # @return [TrueClass, FalseClass]
    def brand?
      @model.property('brand').present?
    end

    # Computes where or not a product property for gtin is present.
    #
    # @return [TrueClass, FalseClass]
    def gtin?
      @model.property('gtin').present?
    end

    # Computes where or not a product property for mpn is present.
    #
    # @return [TrueClass, FalseClass]
    def mpn?
      @model.property('mpn').present?
    end
  end
end
