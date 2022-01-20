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
          :leg_status, :fees, :commission, :placed_time, :execution_time, :preview_time,
          :order_id, :preview_id

        ForwardingFailure = Class.new(StandardError)
        MissingLegs = Class.new(StandardError)

        # Called when we receive an existing open order from the vendor API.
        # We want to use that Response so we take its #legs and then assign
        # the order values to this new order value. The returned instance is
        # now ready for further price modification and resubmission.
        #
        def self.from_existing_order(vendor:, response:)
          instance = choose_type(response).new(vendor: vendor, legs: response.legs)

          # now set the values from the open order
          instance.all_or_none = response.all_or_none
          instance.order_term = response.order_term
          instance.market_session = response.market_session
          instance.quantity = response.unfilled_quantity
          instance.price_type = response.price_type
          instance.limit_price = response.limit_price
          instance.stop_price = response.stop_price
          instance.direction = response.action =~ /open/i ? :opening : :closing
          instance.side = response.action =~ /buy/i ? :long : :short
          instance.order_id = response.order_id
          instance
        end

        def self.choose_type(response)
          case response.order_type
          when :vertical
            Vertical
          else
            raise "Need to define #{response.order_type} Write subclass"
          end
        end

        private attr_reader :vendor

        def initialize(vendor:, legs:)
          @vendor = vendor
          @preview_response = nil
          @place_response = nil
          self.legs = legs # makes sure legs are sorted correctly via ComposedMethods
          @unsubmitted = true
          set_sensible_defaults
        end

        def legs
          # When instance is originally set, we use the legs passed in. For a new order
          # (e.g. Vertical) this will be the body + wing. For an existing open order, this
          # will be Response#legs. Once we start to preview or place a new/change to the
          # order, then we prefer to use those new response legs over what we initialized
          # this class with.
          if @preview_response.respond_to?(:legs)
            puts "Forwarding to preview legs" if $GREEKS
            @preview_response.legs
          elsif @place_response.respond_to?(:legs)
            puts "Forwarding to place legs" if $GREEKS
            @place_response.legs
          elsif !!@legs
            puts "Forwarding to init @legs" if $GREEKS
            @legs
          else
            raise MissingLegs.new
          end
        end

        def preview!
          # @preview_payload is used in #submit! subclasses to streamline
          # generation of the place payload... it's already been built
          # correctly, so minimize changes to it!
          @preview_response, @preview_payload = yield
          @place_response = nil
          @unsubmitted = false
          !!@preview_response
        end

        def preview_ok?
          true
        end

        def submit!
          # subclass uses @preview_payload to pass to a call inside the block
          @place_response = yield
          @preview_response = nil # remove so that calls to #response pick correctly
          @order_id = @place_response.order_id
          @unsubmitted = false
          !!@place_response
        end

        def submit_ok?
          true
        end

        # Returns true when the order has not been previewed or placed yet.
        # False otherwise.
        #
        def unsubmitted?
          @unsubmitted
        end

        def preview_errors
          []
        end

        def submit_errors
          []
        end

        def status
          :open # how could it be anything else?
        end

        def order_id=(value)
          @order_id = value
        end

        def order_id
          # if set, then this instance was built from an existing Response
          # if not set, then #super executes the forwarding #def_delegators
          # logic and forwards to an internal Response
          if @order_id
            @order_id
          elsif response.respond_to?(:order_id)
            super
          end
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
          # calls the ComposedMethod included here
          unfilled_quantity
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
          return @limit_price = value.to_f if value.is_a?(Float) || value.is_a?(Integer)

          raise ArgumentError.new("Argument must be a Float, received #{value.class}")
        end

        def limit_price
          # return a default so that Wrapper::Spread calls succeed
          @limit_price || 0.0
        end

        def stop_price=(value)
          return @stop_price = value.to_f if value.is_a?(Float) || value.is_a?(Integer)

          raise ArgumentError.new("Argument must be a Float, received #{value.class}")
        end

        def stop_price
          @stop_price
        end

        private

        def response
          if @preview_response
            puts "Forwarding to preview response" if $GREEKS
            @preview_response
          elsif @place_response
            puts "Forwarding to place response" if $GREEKS
            @place_response
          end
          # @preview_response || @place_response || fail
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
