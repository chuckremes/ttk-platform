# The abstract interface to all vendor position classes. Each strategy
# knows which vendor(s) it is using, so during strategy setup the
# vendor-specific class is passed to this class. This class delegates
# most work to that vendor class but offers some convenience methods
# that build on top of the baseline logic.
#
module TTK
  module Platform
    module Collections
      class Positions < Collection
        def initialize(vendor_interface:, collection:, meta: {})
          super
        end

        def spreads
          groups = TTK::Containers::Combo::Group.regroup(@collection)
          array = groups.map do |group|
            TTK::Containers::Legs::Classifier::Combo.classify(container: group)
          end

          self.class.new(collection: array.select { |element| element.spread? },
            vendor_interface: interface,
            meta: package_meta)
        end
      end
    end
  end
end
