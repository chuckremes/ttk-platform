require "delegate"

# Takes an array of Core::Options::Option or a duck-typed equivalent from
# a vendor (likely) and does operations on them.
#
module TTK
  module Platform
    module Collections
      # Contains all of the chains for a given symbol.
      #
      class ChainGroup < Collection
        def dte(min: nil, max: nil, exact: nil)
          if exact
            min = max = exact
          end

          min ||= 0
          max ||= Float::INFINITY
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.dte.between?(min, max) })
        end

        def puts
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.put? })
        end

        def calls
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.call? })
        end

        def delta(min: nil, max: nil)
          # always use absolute value of delta
          min = min.abs || 0
          max = max.abs || Float::INFINITY
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.delta.abs.between?(min, max) })
        end

        # Find all options between min and max and keep only those with the highest
        # DTE.
        #
        def max_dte(min: nil, max: nil)
          min ||= 0
          max ||= Float::INFINITY
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: select_field_range(field: :dte, boundary: :max))
        end

        def min_dte(min: nil, max: nil)
          min ||= 0
          max ||= Float::INFINITY
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: select_field_range(field: :dte, boundary: :min))
        end

        # Used to find closest to ATM. Should likely only be called on a chain
        # that has already filtered out all but the desired expiration, put/call
        # type, etc. Makes little sense to call this on a chain with multiple
        # expirations in it.
        #
        # Returns a Quote instance!
        #
        def max_extrinsic
          # should get back an array with a single element but there
          # could be cases (high IV stocks) where multiple strikes have
          # the same extrinsic to within a penny... sigh
          array = select_field_range(field: :extrinsic, boundary: :max)

          # not all option strikes exist, so this can return nil
          array[0]
        end

        def max_delta
          array = select_field_range(field: :delta, boundary: :max)
          array[0]
        end

        def min_delta
          array = select_field_range(field: :delta, boundary: :min)
          array[0]
        end

        def strikes_at(price)
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.strike == price })
        end

        def strikes_above(price)
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.strike > price })
        end

        def strikes_below(price)
          self.class.new(vendor_interface: interface,
            meta: package_meta,
            collection: collection.select { |o| o.strike < price })
        end

        # FIXME: rewrite this as individual methods and then see how to refactor
        # i find the current solution to be brittle
        def select_field_range(field:, boundary:)
          # tricky... the Quote classes generally aren't Comparable because the
          # field we want to use for that comparison may change over time. We may
          # want to compare by strike, delta, extrinsic or some other field. So,
          # we have a temporary Comparator class that wraps the Quote instance and
          # allows us to set the specific field we want for comparison. Clever?
          # Let's us dynamically change fields per call.
          selected_value = collection.uniq { |o| o.send(field) }
            .map { |o| Comparator.new(o, field: field) }
            .send(boundary)
                             &.send(field)
          # STDERR.puts "select_field_range, field: #{field}, boundary: #{boundary}, value: #{selected_value}"
          collection.select { |o| o.send(field) == selected_value }
        end

        # Simple wrapper class that allows us to designate the field to use
        # for Comparable so we can sort and use other Enumerable methods.
        #
        class Comparator < SimpleDelegator
          include Comparable

          def initialize(parent, field:)
            @field = field
            super(parent)
          end

          def <=>(other)
            send(@field) <=> other.send(@field)
          end
        end
      end
    end
  end
end
