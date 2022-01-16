require_relative "write"

module TTK
  module Platform
    module Order
      class Vertical < Write
        def initialize(body:, wing:, vendor:)
          @legs = [Leg.new(product: body.product, quote: body),
            Leg.new(product: wing.product, quote: wing)]

          super(vendor: vendor)
        end

        def direction=(value)
          super do
            legs.each { |leg| leg.direction = value}
          end
        end

        def quantity=(value)
          super do
            legs.each { |leg| leg.unfilled_quantity = value}
          end
        end

        def side=(value)
          super do
            if value == :long
              legs[0].side = :long
              legs[1].side = :short
            else
              legs[0].side = :short
              legs[1].side = :long
            end
          end
        end

        def preview!
          # use vendor interfaces to convert the body and wing information
          # along with order attributes into a vendor order and send it
          # to the vendor's preview api

          super do
            # last call in this block should return the vendor Response object
            # and the preview payload, e.g. [response, payload]
            vendor.preview_vertical(attributes: self)
          end
        end

        def submit!
          super do
            vendor.submit_vertical(attributes: self, preview: @preview_payload)
          end
        end
      end
    end
  end
end