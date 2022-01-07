require 'delegate'

# Combo is an abstract base class for all single-leg and multi-leg
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
module TTK
  module Platform
    module Wrappers
      class Spread < SimpleDelegator
        SpreadFormError = Class.new(StandardError)

        # Private internal class(es) that contain all of the legs.
        # Parent / outer classes delegate all unknown methods to
        # these classes. Puts and Calls are handled differently
        # which is why these classes exist, otherwise we'd have had
        # PutSpread and CallSpread instead of just Vertical which
        # behaves correctly regardless of what options it contains.
        # Simpler to use though this may appear more complex behind
        # the scenes.
        #
        # The +container+ is assumed to be a type of TTK::Containers::Legs
        #
        class Base < SimpleDelegator
          def initialize(container)
            @container = container
            super(container)
          end

          def body_leg
            legs.find { |l| l.strike == body_strike }
          end

          alias_method :anchor_leg, :body_leg

          def wing_leg
            legs.find { |l| l.strike == wing_strike }
          end

          def min_expiration
            expiration_dates.min
          end

          def max_expiration
            expiration_dates.max
          end

          # Bid is the bid of the the more ATM strike minus the ask
          # of the more OTM strike.
          def bid
            body_leg.bid - wing_leg.ask
          end

          # Ask is the ask of the more ATM strike minus the bid of
          # the more OTM strike.
          def ask
            body_leg.ask - wing_leg.bid
          end

          def midpoint
            ((bid + ask) / 2.0).round(2, half: :down)
          end

          def nice_print
            separator = ' | '
            now = Time.now.strftime("%Y%m%d-%H:%M:%S.%L").rjust(21).ljust(22)
            action = self.sides.first.to_s.rjust(12).ljust(13)
            quantity = self.quantity.to_s.rjust(8).ljust(9)
            name = self.body_leg.osi.rjust(21).ljust(22) + " / " + wing_leg.osi.rjust(21).ljust(22)
            price = self.limit_price.to_s.rjust(5).ljust(6)
            term = self.order_term.to_s.rjust(10).ljust(10)
            puts [now, action, quantity, name, price, term].join(separator)
            legs.each(&:nice_print)
            nil
          end

          # ######### Greeks ##########
          # These are additive in a spread. Each leg should have
          # greeks from a quote. If no quote is available, should
          # fail gracefully with zeros or something.
          #
          # Aggregation happens on the vendor container, not here.

        end

        class Puts < Base
          def body_strike
            map(:strike).max
          end

          alias_method :anchor_strike, :body_strike

          def wing_strike
            map(:strike).min
          end

          # Using the current value of the spread plus the greeks, guess
          # what the spread price will be at the give +price+ of the
          # underlying.
          #
          def project_price_at(underlying:, target:, debug: false)
            difference = (underlying - target)
            spread_delta = delta
            spread_gamma = gamma

            integral = (difference / 1).to_i
            mantissa = difference % 1.0
            total = 0.0
            STDERR.puts "difference".rjust(10).ljust(11) +
                          "delta".rjust(7).ljust(8) +
                          "gamma".rjust(7).ljust(8) +
                          "integral".rjust(8).ljust(9) +
                          "mantissa".rjust(8).ljust(9) if debug
            STDERR.puts difference.round(2).to_s.rjust(10).ljust(11) +
                          spread_delta.round(2).to_s.rjust(7).ljust(8) +
                          spread_gamma.round(2).to_s.rjust(7).ljust(8) +
                          integral.round(2).to_s.rjust(8).ljust(9) +
                          mantissa.round(2).to_s.rjust(8).ljust(9) if debug

            # accumulate the delta for each $1 difference in cost
            # if moving *down* towards ATM, then delta should get bigger so add in gamma for
            # each $1 move
            integral.abs.times do
              spread_delta = difference.positive? ? (spread_delta - spread_gamma) : (spread_delta + spread_gamma)
              total += spread_delta
            end

            # account for the fractional dollar by adding those cents to the total
            total += (spread_delta * mantissa)

            # if spread is moving more towards ITM, we'll want this to be a positive number
            # if spread moving more towards OTM, we'll want it to be negative so price is smaller
            total = difference.positive? ? total : total * -1
            STDERR.puts "total".rjust(7).ljust(8) +
                          "mid".rjust(7).ljust(8) +
                          "sum".rjust(7).ljust(8) if debug
            STDERR.puts total.round(2).to_s.rjust(7).ljust(8) +
                          midpoint.round(2).to_s.rjust(7).ljust(8) +
                          (midpoint + total).round(2).to_s.rjust(7).ljust(8) if debug

            midpoint + total
          rescue => e
            binding.pry
          end

        end

        class Calls < Base
          def body_strike
            map(:strike).min
          end

          alias_method :anchor_strike, :body_strike

          def wing_strike
            map(:strike).max
          end
        end

        # Spread class is abstract.
        def initialize(container)
          sanity_check(container)
          if container.put?
            super(Puts.new(container))
          elsif container.call?
            super(Calls.new(container))
          else
            # equity container?
            raise "Need to define an equity container"
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
          :short == side
        end

        def long?
          :long == side
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

      class Single < Spread

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

        def unit_price
          limit_price / filled_quantity
        end

        private

        def check_leg_count(container)
          return if container.count == 1
          raise SpreadFormError.new("Too many legs! #{container.legs.each(&:nice_print)}")
        end

        def check_leg_kind(container)
          return if container.put? || container.call?
          raise SpreadFormError.new("Should be a straddle! #{container.legs.each(&:nice_print)}")
        end

        def check_sides(container)
          side =  container.map(:side)
          return unless [:long, :short].include?(side)
          raise SpreadFormError.new("Not a real order with same sides! #{container.legs.each(&:nice_print)}")
        end

        def check_expiration(container)
          return if container.map(:expiration_date).uniq.count == 1
          raise SpreadFormError.new("Should be a calendar / diagonal! #{container.legs.each(&:nice_print)}")
        end

        def check_strikes(container)
          return if container.map(:strike).uniq.count == 1
          raise SpreadFormError.new("Should be a vertical! #{container.legs.each(&:nice_print)}")
        end
      end

      # Concrete subclass implementing logic for Vertical spreads.
      #
      class Vertical < Spread
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
          legs[0].expiration_date
        end

        def side
          # long/short is determined by the side of the body strike
          legs.find { |l| l.strike == body_strike }.side
        end

        def unit_price
          limit_price / filled_quantity
        end

        private

        def check_leg_count(container)
          return if container.count == 2
          raise SpreadFormError.new("Too many legs! #{container.legs.each(&:nice_print)}")
        end

        def check_leg_kind(container)
          return if container.put? || container.call?
          raise SpreadFormError.new("Should be a straddle! #{container.legs.each(&:nice_print)}")
        end

        def check_sides(container)
          return if container.map(:side).sort == [:long, :short]
          raise SpreadFormError.new("Not a real spread with same sides! #{container.legs.each(&:nice_print)}")
        end

        def check_expiration(container)
          return if container.map(:expiration_date).uniq.count == 1
          raise SpreadFormError.new("Should be a calendar / diagonal! #{container.legs.each(&:nice_print)}")
        end

        def check_strikes(container)
          return if container.map(:strike).uniq.count == 2
          raise SpreadFormError.new("Should be a calendar! #{container.legs.each(&:nice_print)}")
        end
      end

      class Diagonal < Vertical
        def check_expiration(container)
          return if container.expiration_dates.uniq.count == 2
          raise SpreadFormError.new("Should be a calendar / diagonal! #{container.inspect}")
        end
      end

      class Calendar < Diagonal

        def check_strikes(container)
          return if container.strikes.uniq.count == 1
          raise SpreadFormError.new("Should be a diagonal! #{container.legs.each(&:nice_print)}")
        end
      end

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
          raise SpreadFormError.new("Too many legs! #{container.legs.each(&:nice_print)}")
        end

        def check_sides(container)
          return if container.sides.sort == [:long, :long, :short, :short]
          raise SpreadFormError.new("Not a real spread with same sides! #{container.legs.each(&:nice_print)}")
        end

        def check_strikes(container)
          return if container.strikes.uniq.count >= 2
          raise SpreadFormError.new("Should be a calendar! #{container.legs.each(&:nice_print)}")
        end
      end
    end
  end
end
