# frozen_string_literal: true

# The abstract interface to all vendor order and position classes. Each strategy
# knows which vendor(s) it is using, so during strategy setup the
# vendor-specific class is passed to this class. This class "has a"
# vendor class and offers all convenience methods that build on top of the
# baseline vendor collection.
#
# Every method should return a new instance / self so the methods can be chained.
#
module TTK
  module Platform
    module Collections
      class Collection
        include Enumerable

        private attr_reader :interface, :collection

        def initialize(vendor_interface:, collection:, meta: {})
          @interface = vendor_interface
          @collection = collection
          @meta = meta
        end

        def each(&blk)
          @collection.each(&blk)
        end

        def refresh
          @interface.refresh # force vendor to reload
        end

        # Root symbols like "SPY" and "AAPL". Do not use OSI formatted symbols
        # in this call.
        #
        def symbols(*list)
          self.class.new(collection: select { |element| list.include?(element.symbol) },
            vendor_interface: interface,
            meta: package_meta)
        end

        def opening
          self.class.new(collection: select(&:opening?),
            vendor_interface: interface,
            meta: package_meta)
        end

        def closing
          self.class.new(collection: select(&:closing?),
            vendor_interface: interface,
            meta: package_meta)
        end

        def leg_count(count)
          self.class.new(collection: select { |element| element.count == count },
            vendor_interface: interface,
            meta: package_meta)
        end

        # Valid arguments should be symbols and come from this list:
        #   :open
        #   :executed
        #   :cancelled
        #   :cancel_requested
        #   :expired
        #   :rejected
        #   :partial
        #
        def status(*values)
          self.class.new(collection: select { |element| values.include?(element.status) },
            vendor_interface: interface,
            meta: package_meta)
        end

        # Outputs a new TTK::Core::Collection instance where all elements have
        # been grouped into spreads or standalone elements. Anything that can
        # be paired up will be paired.
        #
        def spreads
          # should be implemented by a subclass because determining
          # combo types differs when using positions versus orders
          raise NotImplementedError
        end

        def verticals
          self.class.new(collection: select { |element| element.respond_to?(:vertical?) && element.vertical? },
            vendor_interface: interface,
            meta: package_meta)
        end

        #
        # def by_strike(order: :ascending)
        #   direction = order == :ascending ? 1 : -1
        #
        #   self.class.new(options.sort_by { |element| direction * element.strike })
        # end

        def ascending(field: :execution_time)
          sort_by_field(field: field)
        end

        def descending(field: :execution_time)
          sort_by_field(field: field, order: -1)
        end

        def sort_by_field(field:, order: 1)
          self.class.new(collection: sort_by { |element| order * element.send(field) },
            vendor_interface: interface,
            meta: package_meta)
        end

        # Time is inclusive, that is it includes the border value
        #
        # Sometimes a vendor records a weird time on their position. For example, ETrade
        # records a position only as a date, so the time is "as of" midnight AM of the
        # day the order executed. Therefore, on a "time scale" the position is younger
        # than the executed order! So, we allow for date matching too to assist with
        # this case.
        #
        def before(time:, field:, date_granularity: false)
          comparator = date_granularity ? Time.new(time.year, time.month, time.day) : time

          array = select do |element|
            field_value = element.send(field)
            adj_value = if date_granularity
              Time.new(field_value.year, field_value.month,
                field_value.day)
            else
              field_value
            end
            adj_value <= comparator
          end
          self.class.new(collection: array,
            vendor_interface: interface,
            meta: package_meta)
        end

        # Time is exclusive, that is it does NOT include the border value
        def after(time:, field:, date_granularity: false)
          comparator = date_granularity ? Time.new(time.year, time.month, time.day) : time

          array = select do |element|
            field_value = element.send(field)
            adj_value = if date_granularity
              Time.new(field_value.year, field_value.month,
                field_value.day)
            else
              field_value
            end
            adj_value > comparator
          end
          self.class.new(collection: array,
            vendor_interface: interface,
            meta: package_meta)
        end

        def shorts
          self.class.new(collection: select(&:short?),
            vendor_interface: interface,
            meta: package_meta)
        end

        def longs
          self.class.new(collection: select(&:longs),
            vendor_interface: interface,
            meta: package_meta)
        end

        def puts
          self.class.new(collection: select(&:put?),
            vendor_interface: interface,
            meta: package_meta)
        end

        def options
          self.class.new(collection: equity_options + future_options,
            vendor_interface: interface,
            meta: package_meta)
        end

        def equity_options
          self.class.new(collection: select(&:equity_option?),
            vendor_interface: interface,
            meta: package_meta)
        end

        def future_options
          # not implemented yet
          self.class.new(collection: [],
            vendor_interface: interface,
            meta: package_meta)
        end

        def equities
          self.class.new(collection: select(&:equity?),
            vendor_interface: interface,
            meta: package_meta)
        end

        def +(other)
          self.class.new(collection: collection + other.to_a,
            vendor_interface: interface,
            meta: package_meta)
        end

        def package_meta
          {}
        end
      end
    end
  end
end
