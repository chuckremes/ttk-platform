require_relative "../../../../../../ttk-containers/lib/ttk/containers/product/shared"
require_relative "../../../../../../ttk-containers/lib/ttk/containers/quote/shared"
require_relative "../../../../../../ttk-containers/lib/ttk/containers/leg/shared"

module TTK
  module Platform
    module Order
      class Write
        # Exposes write methods for #unfilled_quantity, #side, and
        # #direction.
        class Leg
          include TTK::Containers::Quote::Forward
          include TTK::Containers::Product::Forward
          include TTK::Containers::Leg::ComposedMethods

          attr_reader :unfilled_quantity, :side, :direction, :product, :quote

          # Need these defined to pass interface conformance but they are never set
          attr_reader :filled_quantity, :price, :stop_price,
            :market_price, :placed_time, :execution_time, :preview_time,
            :leg_status, :leg_id, :fees, :commission

          def initialize(product:, quote:)
            @product = product
            @quote = quote
          end

          def unfilled_quantity=(value)
            @unfilled_quantity = value
          end

          def side=(value)
            @side = value
          end

          def direction=(value)
            @direction = value
          end

          def action
            if opening? && long?
              :buy_to_open
            elsif opening? && short?
              :sell_to_open
            elsif closing? && long?
              :buy_to_close
            elsif closing && short?
              :sell_to_close
            else
              raise "custom error, never get here"
            end
          end
        end
      end
    end
  end
end