# require 'async'
# require 'async/barrier'
# require "async/limiter/window/sliding"

require "set"

module TTK
  module Platform
    module Collections
      # Maintains a list of all quote subscriptions. Any time the system needs a
      # quote, it retrieves it from here.
      #
      # Basically this class allocates a Quote container for every unique symbol
      # and stores it in a list. This quote container is returned to the caller
      # to store. As quote updates are received by the system, the interior of
      # the quote container is swapped with the updated information. In this way
      # the quote containers always have the most up-to-date information while
      # avoiding a complex pub/sub architecture.
      #
      # Each symbol is tracked only once. A single quote container is allocated
      # for each symbol and shared out to any callers who want the same quote
      # information. In a way, it could be said that the quote container itself
      # is the observer and this class publishes updates to it exclusively.
      #
      class Quotes < Collection
        UnknownQuoteType = Class.new(StandardError)
        MissingQuoteWrapper = Class.new(StandardError)

        def initialize(vendor_interface:, collection:, meta: {})
          super
          @collection ||= Set.new

          @refresh = 5000 # config&.refresh_ms || 5_000

          # According to ETrade API v0 docs, the Market APIs can be called
          # at a rate of 4 per second or 14000 per hour. Not sure if it
          # applies to the v1 API (which this implements) but it's a good
          # baseline.
          # @barrier = Async::Barrier.new
          # @limiter = Async::Limiter::Window::Sliding.new(8, window: 1, parent: @barrier)
        end

        # Returns a new Quotes collection where all elements are #equity? or it's an empty list
        #
        def equity
          self.class.new(collection: collection.select { |element| element.equity? },
            vendor_interface: interface,
            meta: package_meta)
        end

        # Returns a new Quotes collection where all elements are #equity_option? or it's an empty list
        #
        def equity_option
          self.class.new(collection: collection.select { |element| element.equity_option? },
            vendor_interface: interface,
            meta: package_meta)
        end

        # Returns a new Quotes collection where all elements are +symbol+ or it's an empty list
        #
        def symbol(symbol)
          self.class.new(collection: collection.select { |element| element.symbol == symbol },
            vendor_interface: interface,
            meta: package_meta)
        end

        # When a Quote has been retrieved elsewhere (e.g. via a Chain), we can register
        # it here for updates.
        #
        def register(quote:)
          return unless quote.respond_to?(:update_quote)
          collection << quote
        end

        # Subscribe to get a quote update.
        #
        # +cycle+ => :once or :forever, defaults to :once
        #
        # Returns: Quote container
        #
        def subscribe(symbol:, type:, refresh: @refresh, cycle: :once)
          symbol, type = sanitize(symbol, type)
          quote = find(symbol: symbol)

          return quote if quote # already subscribed so return directly

          quote = populate(symbol: symbol, type: type)
          register(quote: quote)
          quote
        end

        def sanitize(symbol, type)
          # turn into osi format even for equity so we are
          # consistent
          # do same for type so we can use it as an internal map/key
          raise "Unknown type [#{type.inspect}]" unless [:equity, :equity_option].include?(type)
          # do sanity checks on symbol to confirm osi
          [symbol, type]
        end

        def find(symbol:)
          # From chains also wrapping quotes, there *could be* multiple symbol wrappers
          # for a single OSI symbol; just use first one found
          collection.find { |element| element.osi == symbol }
        end

        # Gets the initial quote for this +symbol+ and wraps it up appropriately.
        # Future calls to update the quote will reuse the same wrapper.
        #
        def populate(symbol:, type:)
          response = interface.lookup_quote(symbol: symbol, type: type)
          TTK::Platform::Wrappers::Quote.choose_type(response)
        end

        # Updates all of the active subscriptions. Currently being called
        # synchronously but this will be moved to its own thread (likely)
        # and then updated on some routine refresh cycle.
        def refresh
          STDERR.puts "called from..."
          pp caller(0, 4)

          equity = collection.select { |element| element.equity? }.
            map { |element| element.osi }.uniq
          equity_options = collection.select { |element| element.equity_option? }.
            map { |element| element.osi }.uniq

          responses = []

          # Async do |task|
          #   @limiter.async do
          responses += interface.lookup_quotes(symbols: equity, type: :equity)
          # end
          # @limiter.async do
          responses += interface.lookup_quotes(symbols: equity_options, type: :equity_option)
          #   end
          # end.wait # do not proceed until all fetches are complete

          responses.each do |response|
            collection.select { |element| element.osi == response.osi }.each do |quote|
              quote.update_quote(response)
            end
          end
        end
      end
    end
  end
end
