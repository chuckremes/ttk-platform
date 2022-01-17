module TTK
  module Platform
    module Wrappers
      module Combo
        class Vertical < Base

          # Should output this format:
          # Now | Action | Quantity | Body OSI / Wing OSI | Price | Order Term
          #     | Action | Quantity | Body OSI            | Price | Order Term
          #     | Action | Quantity | Wing OSI            | Price | Order Term
          def pretty_print
            separator = ' | '
            now = Time.now.strftime("%Y%m%d-%H:%M:%S.L").rjust(21).ljust(22)
            action = self.action.to_s.rjust(12).ljust(13)
            quantity = self.quantity.to_s.rjust(8).ljust(9)
            name = body_leg.osi.rjust(21).ljust(22) + " / " + wing_leg.osi.rjust(21).ljust(22)
            price = limit_price.to_s.rjust(5).ljust(6)
            term = order_term.to_s.rjust(10).ljust(10)
            puts [now, action, quantity, name, price, term].join(separator)
            legs.each(&:pretty_print)
          end

          def vertical?
            true
          end

          def strike
            # Strike price of the body option in the spread. We define that as the
            # highest strike for a put spread and the lowest strike for a call spread.
            body_strike
          end

          def expiration_date
            # verticals only have one expiration
            legs[0].expiration.date
          end

          # FIXME: need tests to confirm this is always part of interface
          def side
            # side is determined by the side of the body strike
            legs.find { |l| l.strike == body_strike }.side
          end

          # FIXME: need tests to confirm this is always part of interface
          def direction
            # direction is determined by the side of the body strike
            legs.find { |l| l.strike == body_strike }.direction
          end

          def unit_price
            limit_price / filled_quantity
          end

          private

          def check_leg_count(container)
            return if container.count == 2
            raise ComboFormError.new("Too many legs! #{container.legs.each(&:nice_print)}")
          end

          def check_leg_kind(container)
            return if container.put? || container.call?
            raise ComboFormError.new("Should be a straddle! #{container.legs.each(&:nice_print)}")
          end

          def check_sides(container)
            return
          end

          def check_expiration(container)
            # return if container.map(:expiration_date).uniq.count == 1
            return if container.legs.map(&:expiration).map(&:date).uniq.count == 1
            raise ComboFormError.new("Should be a calendar / diagonal! #{container.legs.each(&:nice_print)}")
          end

          def check_strikes(container)
            return if container.legs.map(&:strike).uniq.count == 2
            raise ComboFormError.new("Should be a calendar! #{container.legs.each(&:nice_print)}")
          end
        end
      end
    end
  end
end
