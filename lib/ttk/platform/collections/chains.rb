module TTK
  module Platform
    module Collections
      # Contains all chains across all symbols.
      #
      class Chains < Collection
        def initialize(vendor_interface:, collection:, quotes:, meta: {})
          super(vendor_interface: vendor_interface, collection: collection, meta: meta)

          @quotes = quotes
          @collection ||= {}
          @min_dte = meta[:min_dte] || 0
          @max_dte = meta[:max_dte] || Float::INFINITY
        end

        def symbol(symbol)
          unless collection.key?(symbol)
            expirations = interface.option_expirations(symbol).select { |e| e.dte.between?(min_dte, max_dte) }

            # wrap them as Quotes here!
            collection[symbol] = interface.option_chains(symbol, expirations).map do |q|
              # +q+ here should be a TTK::<Vendor::Market::Containers::Response instance
              TTK::Platform::Wrappers::Quote.choose_type(q)
            end
          end

          TTK::Platform::Collections::ChainGroup.new(vendor_interface: nil,
                                                     collection: collection[symbol],
                                                     meta: package_meta,
                                                     quotes: @quotes)
        end

        private

        attr_reader :min_dte, :max_dte
      end
    end
  end
end
