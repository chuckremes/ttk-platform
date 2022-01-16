require_relative "write/leg"
require_relative "../../../../../ttk-containers/lib/ttk/containers/legs/shared"

module TTK
  module Platform
    module Order
      # Handles accepting field assignments when building a new order. When reading
      # values, it always reads from itself even if the Order was successfully
      # previewed or placed. Certain fields that are read-only (e.g. fees) are
      # forwarded to the preview/place Response or raise an error if neither exists
      # (which is a bug in the caller code).
      #
      # Class also handles the #preview, #preview_ok?, #preview_error_list, #submit,
      # #submit_ok?, and #submit_error_list methods.
      #
      class Write
        include TTK::Containers::Legs::Order::ComposedMethods
        extend Forwardable
        def_delegators :response,
          :status, :fees, :commission, :placed_time, :execution_time, :preview_time

        ForwardingFailure = Class.new(StandardError)

        private attr_reader :vendor
        attr_reader :legs

        def initialize(vendor:)
          @vendor = vendor
          @preview_response = nil
          @place_response = nil
          set_sensible_defaults
        end

        def preview!
          # @preview_payload is used in #submit! subclasses to streamline
          # generation of the place payload... it's already been built
          # correctly, so minimize changes to it!
          @preview_response, @preview_payload = yield
          @place_response = nil
          !!@preview_response
        end

        def preview_ok?
          true
        end

        def submit!
          # subclass uses @preview_payload to pass to a call inside the block
          @place_response = yield
          @preview_response = nil # remove so that calls to #response pick correctly
          !!@place_response
        end

        def submit_ok?
          true
        end

        def preview_errors
          []
        end

        def submit_errors
          []
        end

        def direction=(value)
          if [:opening, :closing].include?(value)
            # iterate and set legs in subclass
            yield
          else
            raise ArgumentError.new("Argument must be :opening or :closing, received #{value}")
          end
        end

        def direction
          @direction
        end

        def side=(value)
          if [:long, :short].include?(value)
            yield
          else
            raise ArgumentError.new("Argument must be :long or :short, received #{value}")
          end
        end

        def side
          @side
        end

        def market_session=(value)
          return @market_session = value if [:regular, :extended].include?(value)

          raise ArgumentError.new("Argument must be :regular or :extended, received #{value}")
        end

        def market_session
          @market_session
        end

        def price_type=(value)
          return @price_type = value if [:credit, :debit, :even].include?(value)

          raise ArgumentError.new("Argument must be :credit, :debit, :even, received #{value}")
        end

        def price_type
          @price_type
        end

        def quantity=(value)
          if value.is_a?(Integer)
            yield
          else
            raise ArgumentError.new("Argument must be an Integer, received #{value.class}")
          end
        end

        def quantity
          # does the parent match this naming? may need to be #unfilled_quantity
          # # FIXME... not right... see the Shared logic for greatest common factor
          # and see how to call that from here
          @quantity
        end

        def order_term=(value)
          return @order_term = value if [:day, :gtc].include?(value)

          raise ArgumentError.new("Argument must be :day or :gtc, received #{value}")
        end

        def order_term
          @order_term
        end

        def all_or_none=(value)
          return @all_or_none = value if [true, false].include?(value)

          raise ArgumentError.new("Argument must be true or false, received #{value}")
        end

        def all_or_none
          @all_or_none
        end

        def limit_price=(value)
          return @limit_price = value if value.is_a?(Float)

          raise ArgumentError.new("Argument must be a Float, received #{value.class}")
        end

        def limit_price
          # return a default so that Wrapper::Spread calls succeed
          @limit_price || 0.0
        end

        def stop_price=(value)
          return @stop_price = value if value.is_a?(Float)

          raise ArgumentError.new("Argument must be a Float, received #{value.class}")
        end

        def stop_price
          @stop_price
        end

        private

        def response
          @preview_response || @place_response || fail
        end

        def fail
          raise ForwardingFailure.new("Either @preview_response or @place_response must be set. Bug!")
        end

        def set_sensible_defaults
          self.all_or_none = false
          self.order_term = :day
          self.market_session = :regular
          self.stop_price = 0.0
        end
      end
    end
  end
end
