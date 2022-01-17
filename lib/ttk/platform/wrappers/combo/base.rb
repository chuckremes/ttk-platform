require "delegate"
require_relative "internal/internal"

module TTK
  module Platform
    module Wrappers
      module Combo
        # Combo::Base is an abstract base class for all single-leg and multi-leg
        # spreads. It sets the basic
        # interface that all subclasses should implement. It cannot be
        # instantiated directly since it is missing many methods that are
        # only implemented by concrete subclasses.
        #
        # The constructor detects the types of legs in the spread and creates
        # an internal Put / Call class. Any methods that are not implemented
        # on the Combo (or its subclass) are delegated to the Put / Call
        # internal class.
        #
        class Base < SimpleDelegator
          ComboFormError = Class.new(StandardError)

          # Assumes that +container+ responds to #order_type and returns
          # a valid value.
          #
          def self.choose_wrapper(container)
            case container.order_type
            when :vertical
              Vertical.new(container)
            when :equity, :equity_option
              Single.new(container)
            else
              raise "Trying to wrap a #{container.order_type}... check it!"
            end
          end

          # Combo class is abstract.
          def initialize(container)
            sanity_check(container)
            @container = if container.put?
              @interior_container = Internal::Puts.new(container)
              super(@interior_container)
            elsif container.call?
              @interior_container = Internal::Calls.new(container)
              super(@interior_container)
            else
              # equity or mixed options container?
              raise "Need to define an equity or mixed options container"
            end
          end

          def spread?
            true
          end

          def vertical?
            false
          end

          def calendar?
            false
          end

          def diagonal?
            false
          end

          def short?
            side == :short
          end

          def long?
            side == :long
          end

          private

          # Make sure this spread is of the proper form
          def sanity_check(container)
            check_leg_count(container)
            check_leg_kind(container)
            check_sides(container)
            check_expiration(container)
            check_strikes(container)
          end
        end
      end
    end
  end
end
