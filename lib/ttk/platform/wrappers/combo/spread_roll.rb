module TTK
  module Platform
    module Wrappers
      module Combo
        class SpreadRoll < Calendar

          # Returns the spread that was closed in this roll
          def closing_spread
            spread_legs = legs.select { |l| l.expiration_date == min_expiration }
            # add these legs to a container
            container = TTK::Core::Combo::PositionContainer.new(spread_legs)
            Vertical.new(container)
          end

          def opening_spread
            spread_legs = legs.select { |l| l.expiration_date == max_expiration }
            # add these legs to a container
            container = TTK::Core::Combo::PositionContainer.new(spread_legs)
            Vertical.new(container)
          end

          private

          def check_leg_count(container)
            return if container.count == 4
            raise ComboFormError.new("Too many legs! #{container.legs.each(&:nice_print)}")
          end

          def check_sides(container)
            return
          end

          def check_strikes(container)
            return if container.strikes.uniq.count >= 2
            raise ComboFormError.new("Should be a calendar! #{container.legs.each(&:nice_print)}")
          end
        end
      end
    end
  end
end
