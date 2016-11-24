module Spree
  class SchemaError < StandardError
    def initialize msg, model
      super("Missing mandatory #{msg}. Skipping feed entry for #{model.inspect}")
    end
  end

  class BaseXmlPresenter
    # Creates FeedProductPresenter for presenting products as items
    # in RSS feed for Google Merchant
    #
    # @param view [ActionView view context] the view being rendered.
    #
    # @param model [Spree::Product] the model to display. It must
    #   have its own landing page, which is why variants are not supported
    #   at this time.
    #
    # @param properties [Array <Symbol>] all of the model data which is
    #   obtained from the model.properties
    def initialize(view, model)
      @view = view
      @model = model

      # For each property listed, if the model has a property
      # associated with it which matches, create an instance method
      # of the same name which retrieves the property value.
      @properties.each do |prop|
        next unless @model.property(prop.to_s)
        @schema << prop
        self.class.send(:define_method, prop) do
          @model.property(prop.to_s)
        end
      end
    end

    # @!attribute schema
    #   @return [Array <Symbol, Hash>] the nested schema to use in xml generation
    #
    # @!attribute properties
    #   @return [Array <Symbol>] the model properties list to use in accessor creation.
    attr_accessor :schema, :properties

    # Creates an <item> RSS feed entry of the
    # model, corresponding with Google's requested schema. If a
    # mandatory element of the schema is missing, a SchemaError is
    # raised, the entire <item> entry for this model is skipped,
    # and an error is logged to the configured log file or STDERR.
    #
    # @param xml [Builder::XmlMarkup]
    # @return String, the xml <item> tag and content for this model.
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

    # Recursively produces xml tags representing model for
    # an xml feed.
    #
    # @param schema [Array <Symbol, Hash>] the schema to draw
    # @param parent [:Symbol, nil] the parent tag to nest within.
    # @param validate_only [true, false] the parent tag to nest within.
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
  end
end
