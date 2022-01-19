require "delegate"

module TTK
  module Platform
    module Wrappers
      module Combo
        module Internal
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
            attr_reader :container

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

            # when difference is positive, we are moving OTM
            # when difference is negative, we are moving ITM
            def project_price_at(difference:, debug: false)
              spread_delta = delta.abs
              spread_gamma = gamma.abs

              integral = (difference.abs / 1).to_i

              # must use absolute value so signs are aligned;
              # to see why, do -0.102 % 1.0 vs -0.102 % -1.0
              mantissa = difference.abs % 1.0
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
              # If difference is positive, then current price is OTM moving towards ATM when
              # difference is 0. Delta and gamma should be growing toward ATM, so accumulate larger values.
              # If difference is negative, then current price is ITM and moving towards ATM
              # when difference is 0. Delta and gamma should shrink toward ATM.
              # this gamma model is weak as it's using a fixed 10%
              integral.abs.times do
                spread_delta = difference.positive? ? (spread_delta + spread_gamma) : (spread_delta - spread_gamma)
                spread_gamma = difference.positive? ? (spread_gamma + (spread_gamma * 0.1)) : (spread_gamma - (spread_gamma * 0.1))
                total += spread_delta
              end

              # account for the fractional dollar by adding those cents to the total
              total += (spread_delta * mantissa)

              # If difference is positive, we are OTM and we want the total to be a positive
              # number
              # If difference is negative, we are ITM and we want the total to be negative
              # as it approaches target
              total = difference.positive? ? total : -total
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
              legs.map(&:strike).max
            end

            alias_method :anchor_strike, :body_strike

            def wing_strike
              legs.map(&:strike).min
            end

            # Using the current value of the spread plus the greeks, guess
            # what the spread price will be at the give +price+ of the
            # underlying.
            #
            def project_price_at(underlying:, target:, debug: false)
              # when difference is positive, we are moving OTM
              # when difference is negative, we are moving ITM
              difference = (underlying - target)
              super(difference: difference, debug: debug)
            end
          end

          class Calls < Base
            def body_strike
              legs.map(&:strike).min
            end

            alias_method :anchor_strike, :body_strike

            def wing_strike
              legs.map(&:strike).max
            end

            # Using the current value of the spread plus the greeks, guess
            # what the spread price will be at the give +price+ of the
            # underlying.
            #
            def project_price_at(underlying:, target:, debug: false)
              # when difference is positive, we are moving OTM
              # when difference is negative, we are moving ITM
              difference = (target - underlying)
              super(difference: difference, debug: debug)
            end
          end
        end
      end
    end
  end
end

