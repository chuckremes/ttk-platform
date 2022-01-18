#
# Reopens the Helper module from ttk-containers and adds more convenience
# methods for supporting testing.
#
require_relative "../../../../../ttk-containers/lib/ttk/containers/rspec"

module Helper
  # Makes a TTK::Container::Legs::Position::Example with two Put legs.
  # By default, strikes are 10 points apart. The +side+ makes it either
  # a bear spread; switching to :short makes it a bull spread.
  #
  def make_put_vertical_position(side: :long, quantity: 1, strike: 100, underlying_last: strike - 1)
    legs = make_put_vertical_position_legs(side: side, quantity: quantity, strike: strike)
    TTK::Platform::Wrappers::Combo::Vertical.new(legs)
  end

  def make_put_vertical_position_legs(side: :long, quantity: 1, strike: 100, underlying_last: strike - 1)
    side1, side2 = side == :long ? [:long, :short] : [:short, :long]

    legs = [make_option_leg(callput: :put, side: side2, strike: strike - 10, filled_quantity: quantity, leg_id: 1),
            make_option_leg(callput: :put, side: side1, strike: strike,  filled_quantity: quantity, leg_id: 2)]
    TTK::Containers::Legs::Position::Example.new(legs: legs)
  end

  def make_call_vertical_position(side: :long, quantity: 1, strike: 100, underlying_last: strike - 1)
    legs = make_call_vertical_position_legs(side: side, quantity: quantity, strike: strike)
    TTK::Platform::Wrappers::Combo::Vertical.new(legs)
  end

  def make_call_vertical_position_legs(side: :long, quantity: 1, strike: 100, underlying_last: strike - 1)
    side1, side2 = side == :long ? [:long, :short] : [:short, :long]

    legs = [make_option_leg(callput: :call, side: side1, strike: strike - 10, filled_quantity: quantity, leg_id: 1,
      underlying_last: underlying_last),
            make_option_leg(callput: :call, side: side2, strike: strike,  filled_quantity: quantity, leg_id: 2,
              underlying_last: underlying_last)]
    TTK::Containers::Legs::Position::Example.new(legs: legs)
  end

  def make_put_single_position(side: long, quantity: 1, strike: 100)
    leg = make_option_leg(callput: :put, side: side, strike: strike, filled_quantity: quantity, leg_id: 1)
    TTK::Platform::Wrappers::Single.new(
      TTK::Containers::Legs::Position::Example.new(legs: [leg]))
  end

  def make_call_single_position(side: long, quantity: 1, strike: 100)
    leg = make_option_leg(callput: :call, side: side, strike: strike, filled_quantity: quantity, leg_id: 1)
    TTK::Platform::Wrappers::Single.new(
      TTK::Containers::Legs::Position::Example.new(legs: [leg]))
  end
end
