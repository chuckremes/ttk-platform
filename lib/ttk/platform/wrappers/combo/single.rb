module TTK
  module Platform
    module Wrappers
      module Combo
        class Single < Base
          def spread?
            false
          end

          def bid
            body_leg.bid
          end

          def ask
            body_leg.ask
          end

          def strike
            body_leg.strike
          end

          def expiration_date
            body_leg.expiration_date
          end

          def side
            body_leg.side
          end

          def direction
            body_leg.direction
          end

          def unit_price
            limit_price / filled_quantity
          end

          private

          def check_leg_count(container)
            return if container.count == 1
            raise ComboFormError.new("Too many legs! #{container.legs.each(&:nice_print)}")
          end

          def check_leg_kind(container)
            return if container.put? || container.call?
            raise ComboFormError.new("Should be a straddle! #{container.legs.each(&:nice_print)}")
          end

          def check_sides(container)
          end

          def check_expiration(container)
            return if container.legs.map(&:expiration).map(&:date).uniq.count == 1
            raise ComboFormError.new("Should be a calendar / diagonal! #{container.legs.each(&:nice_print)}")
          end

          def check_strikes(container)
            return if container.legs.map(&:strike).uniq.count == 1
            raise ComboFormError.new("Should be a vertical! #{container.legs.each(&:nice_print)}")
          end
        end
      end
    end
  end
end
