module TTK
  module Platform
    module Wrappers
      module Combo
        class Diagonal < Vertical
          def check_expiration(container)
            return if container.legs.map(&:expiration_date).map(&:date).uniq.count == 2
            raise ComboFormError.new("Should be a calendar / diagonal! #{container.inspect}")
          end
        end
      end
    end
  end
end
