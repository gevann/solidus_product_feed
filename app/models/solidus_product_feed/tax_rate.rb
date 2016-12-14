module SolidusProductFeed
  class TaxRate

    # Calculates the most commonly applied tax rate to the given product, if any.
    # If none have yet to be applied, returns the first tax rate available to
    # this product.
    #
    # @param product [Spree::Product] the product to calculate the tax rate for.
    # @return [FixNum] the tax rate as a percentage.
    def tax_rate(product)
      rates = Spree::TaxRate.joins(:adjustments)
        .joins("INNER JOIN spree_line_items "\
      "ON spree_adjustments.adjustable_id = spree_line_items.id "\
      "AND spree_adjustments.adjustable_type = 'Spree::LineItem'")
        .where("spree_line_items.variant_id = ?", product.master.id)
        .group("spree_tax_rates.id")

        if rates.present?
          tr_id = rates.count.map(&:flatten).sort_by { |id, count| -count }.first.first
          Spree::TaxRate.find(tr_id).amount * 100.0
        else
          tr = product.master.tax_category.tax_rates.first
          tr.amount * 100.0 if tr.present?
        end
    end
  end
end
