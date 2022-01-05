#
# Reopens the Helper module from ttk-containers and adds more convenience
# methods for supporting testing.
#
require_relative "../../../../../ttk-containers/lib/ttk/containers/rspec"

module Helper
  # make_option_leg(klass: TTK::Containers::Leg::Example, callput: :call, side: :long,
  #                       direction: :opening, strike: 100, last: 4.56,
  #                       expiration_date: nil, unfilled_quantity: 0, filled_quantity: 1,
  #                       price: 1.0, market_price: 0.0, stop_price: 0.0,
  #                       placed_time: Time.now, execution_time: Time.now, preview_time: Time.now,
  #                       leg_status: :executed, leg_id: 1, fees: 0.0, commission: 0.0)

  # Makes a TTK::Container::Legs::Position::Example with two Put legs.
  # By default, strikes are 10 points apart. The +side+ makes it either
  # a bear spread; switching to :short makes it a bull spread.
  #
  def make_put_vertical(side: :long, quantity: 1)
    side1, side2 = side == :long ? [:long, :short] : [:short, :long]

    legs = [make_option_leg(callput: :put, side: side2, strike: 90, filled_quantity: quantity, leg_id: 1),
            make_option_leg(callput: :put, side: side1, strike: 100,  filled_quantity: quantity, leg_id: 2)]
    TTK::Containers::Legs::Position::Example.new(legs: legs)
  end

  def make_call_vertical(side: :long, quantity: 1)
    side1, side2 = side == :long ? [:long, :short] : [:short, :long]

    legs = [make_option_leg(callput: :call, side: side1, strike: 90, filled_quantity: quantity, leg_id: 1),
            make_option_leg(callput: :call, side: side2, strike: 100,  filled_quantity: quantity, leg_id: 2)]
    TTK::Containers::Legs::Position::Example.new(legs: legs)
  end
end
