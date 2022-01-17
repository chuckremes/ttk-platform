module TTK
  module Platform
    module Wrappers
      module Combo
        class Calendar < Diagonal
          def check_strikes(container)
            return if container.legs.map(&:strike).uniq.count == 1
            raise ComboFormError.new("Should be a diagonal! #{container.legs.each(&:nice_print)}")
          end
        end
      end
    end
  end
end
