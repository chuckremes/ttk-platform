module TTK
  module Platform
    module Collections
      # Contains all chains across all symbols.
      #
      class Chains < Collection
        def initialize(vendor_interface:, collection:, meta: {})
          super(vendor_interface: vendor_interface, collection: collection, meta: meta)

          @collection ||= {}
          @min_dte = meta[:min_dte] || 0
          @max_dte = meta[:max_dte] || Float::INFINITY
        end

        def symbol(symbol)
          unless collection.key?(symbol)
            expirations = interface.option_expirations(symbol).select { |e| e.dte.between?(min_dte, max_dte) }
            collection[symbol] = interface.option_chains(symbol, expirations)
          end

          TTK::Platform::Collections::ChainGroup.new(vendor_interface: nil,
                                                     collection: collection[symbol],
                                                     meta: package_meta)
        end

        private

        attr_reader :min_dte, :max_dte
      end
    end
  end
end
