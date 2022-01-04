
# The abstract interface to all vendor order classes. Each strategy
# knows which vendor(s) it is using, so during strategy setup the
# vendor-specific class is passed to this class. This class delegates
# most work to that vendor class but offers some convenience methods
# that build on top of the baseline logic.
#
module TTK
  module Platform
    module Collections
      class Orders < Collection
        def initialize(vendor_interface:, collection:, meta: {})
          super
          @pending_cancels = @meta[:pending_cancels] || {}
        end

        def spreads
          array = map do |order|
            # In the future, may want to pass through the actual vendors
            # classification if a) they provide one, and b) it is correct.
            # By using nil we force the classification logic to exhaustively
            # work through the possibilities.
            TTK::Core::Combo.classify(container: order)
          end

          self.class.new(collection: array, vendor_interface: interface, meta: package_meta)
        end

        def find_by_order_id(order_id)
          find { |o| o.order_id == order_id }
        end

        def new_vertical_spread(body_leg:, wing_leg:)
          container = @collection.new_vertical_spread(body_leg: body_leg, wing_leg: wing_leg)
          # binding.pry
          TTK::Core::Combo::Spread::Vertical.new(container)
        end

        # Takes a request to cancel an order and submits it. If there is already a pending
        # submitted cancel, log it.
        #
        def cancel(order, reason)
          cleanup_confirmed_cancels
          return unless order

          if @pending_cancels.key?(order.order_id)
            STDERR.puts "cancel, found a pending cancel for order_id #{order.order_id}"
          else
            STDERR.puts "cancel, cancelling order_id #{order.order_id}"
            @pending_cancels[order.order_id] = true
            order.cancel(reason: reason)
          end
        rescue TTK::ETrade::Errors::PendingCancelForOrderAlready
          STDERR.puts "Attempt to cancel order_id [#{order.order_id}] with cancel pending"
          pp @pending_cancels
        end

        # Check the canonical list of orders to see if any orders marked as pending cancel
        # have been completed. If so, remove from list.
        #
        def cleanup_confirmed_cancels
          cancelled = collection.status(:canceled).map { |o| o.order_id }
          @pending_cancels.delete_if { |order_id, _| cancelled.include?(order_id) }

          nil
        end

        def package_meta
          {
            pending_cancels: @pending_cancels
          }.merge(super)
        end
      end
    end
  end
end
