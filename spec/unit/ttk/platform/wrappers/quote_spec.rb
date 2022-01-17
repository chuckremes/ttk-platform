require_relative "../../../../../../ttk-containers/lib/ttk/containers/rspec/shared_quote_spec"
require_relative "../../../../../../ttk-containers/lib/ttk/containers/product/example"
require_relative "../../../../../../ttk-containers/lib/ttk/containers/quote/example"

RSpec.describe TTK::Platform::Wrappers::Quote do
  let(:product) do
    TTK::Containers::Product::Example.new(
    security_type: security_type, symbol: symbol, callput: callput,
    strike: strike, expiration: expiration_date)
  end
  let(:expiration_date) { TTK::Containers::Product::Expiration::Example.new(year: year, month: month, day: day) }

  let(:symbol) { "SPY" }
  let(:strike) { 0 }
  let(:callput) { "" }
  let(:security_type) { :equity }
  let(:year) { 0 }
  let(:month) { 0 }
  let(:day) { 0 }

  let(:quote_timestamp) { Time.now }
  let(:quote_status) { :realtime }
  let(:ask) { 17.15 }
  let(:bid) { 17.11 }
  let(:last) { 17.12 }
  let(:volume) { 12 }

  describe ".choose_type" do
    context "unknown response" do
      let(:response) do
        Class.new do
          def equity?
            false
          end

          def equity_option?
            false
          end
        end.new
      end

      it "raises UnknownQuoteResponseType" do
        expect { described_class.choose_type(response) }.to raise_error(described_class::UnknownQuoteResponseType)
      end
    end
  end

  # Use an Example from ttk-containers for this test; nice & generic!
  let(:instance) do
    TTK::Containers::Quote::Example.new(product: product, quote_timestamp: quote_timestamp,
                                        quote_status: quote_status, ask: ask, bid: bid, last: last,
                                        volume: volume, dte: dte, open_interest: open_interest,
                                        multiplier: multiplier, intrinsic: intrinsic, extrinsic: extrinsic,
                                        delta: delta, gamma: gamma, theta: theta, vega: vega, rho: rho, iv: iv)
  end

  subject(:container) { described_class.new(body: instance) }

  context "equity" do
    let(:dte) { 1 }
    let(:open_interest) { 1 }
    let(:intrinsic) { 1.0 }
    let(:extrinsic) { 1.0 }
    let(:rho) { 1.0 }
    let(:vega) { 1.0 }
    let(:theta) { 1.0 }
    let(:delta) { 1.0 }
    let(:gamma) { 1.0 }
    let(:iv) { 1.0 }
    let(:multiplier) { 100 }

    describe "creation" do
      it "returns a quote instance" do
        expect(container).to be_instance_of(described_class)
      end

      include_examples "quote interface with required methods", TTK::Containers::Quote
    end

    describe "basic interface" do
      # quote_timestamp, quote_status, ask, bid, last, and volume must be defined for this to work
      include_examples "quote interface - methods equity"
    end

    describe "#update_quote" do
      let(:update_object) do
        instance
      end

      include_examples "quote interface - update equity"
    end
  end

  context "equity option" do
    let(:strike) { 50 }
    let(:callput) { "CALL" }
    let(:security_type) { "OPTN" }
    let(:year) { 2021 }
    let(:month) { 12 }
    let(:day) { 11 }

    let(:dte) { 14 }
    let(:open_interest) { 4 }
    let(:intrinsic) { 1.23 }
    let(:extrinsic) { 0.45 }
    let(:rho) { 0.0 }
    let(:vega) { 1.2 }
    let(:theta) { -1.4 }
    let(:delta) { 0.5 }
    let(:gamma) { 0.02 }
    let(:iv) { 0.145 }
    let(:multiplier) { 100 }

    describe "creation" do
      it "returns a quote instance" do
        expect(container).to be_instance_of(described_class)
      end

      include_examples "quote interface with required methods", TTK::Containers::Quote
    end

    describe "basic interface" do
      # quote_timestamp, quote_status, ask, bid, last, and volume must be defined for this to work
      # also needs the various option vars
      include_examples "quote interface - methods equity_option"
    end

    describe "#update_quote" do
      let(:update_object) do
        instance
      end

      include_examples "quote interface - update equity_option"
    end
  end
end
