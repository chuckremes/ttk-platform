# for ComposedMethods
# temporary until ttk-containers is made into a real gem
require_relative "../../../../../ttk-containers/lib/ttk/containers/quote/shared"
require "delegate"

module TTK
  module Platform
    module Wrappers
      # The Quote container appear to be
      # superfluous when all they do is delegate everything to the Market::Containers::Response
      # objects. The reason these classes exist here is so we can pass around references to
      # the <Vendor>::Containers::Quotes::Equity and EquityOption containers for permanent storage
      # in a Position or Order. When receiving new quote data and updating them, we can just
      # pass in the new Market::Containers::Response object to this container and the values
      # will update. The original object references remain intact from the perspective of the
      # Order or Position container.
      #
      class Quote < SimpleDelegator
        UnknownQuoteResponseType = Class.new(StandardError)

        # Expects a <Vendor>::Market::Containers::Equity or EquityOption response object. From it
        # we determine which Quote container to use.
        #
        def self.choose_type(response)
          if response.equity? || response.equity_option?
            new(body: response)
          else
            raise UnknownQuoteResponseType.new(response)
          end
        end

        def initialize(body:)
          # Plain #super is wrong because it interprets it as super(body: body) which
          # ends up passing a hash { body: body } as the argument to SimpleDelegator.
          # That's wrong.
          super(body)
        end

        def update_quote(new_body)
          # Since we are delegating to a parent, we need a way to swap in a new
          # parent object that is the destination of all delegation. This is how
          # we update a Quote container to have new quote values. We substitute in
          # the latest TTK::<Vendor>::Market::Containers::Equity or EquityOption response
          # instance.

          # add sanity checks here maybe?
          __setobj__(new_body)
        end
      end
    end
  end
end
