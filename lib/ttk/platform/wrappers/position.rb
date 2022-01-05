# for ComposedMethods
# temporary until ttk-containers is made into a real gem
require_relative "../../../../../ttk-containers/lib/ttk/containers/legs/shared"
require "delegate"

module TTK
  module Platform
    module Wrappers
      # Receives an instance of TTK::Containers::Legs::Position and delegates all
      # methods to it.
      #
      class Position < SimpleDelegator
        def update_position(new_container)
          # add sanity checks here maybe?
          __setobj__(new_container)
        end
      end
    end
  end
end
