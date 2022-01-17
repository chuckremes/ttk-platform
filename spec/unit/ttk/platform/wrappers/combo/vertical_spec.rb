RSpec.describe TTK::Platform::Wrappers::Combo::Vertical do
  subject(:vertical) { described_class.new(container) }

  let(:spread) { TTK::Platform::Wrappers::Position.new(container) }
  let(:symbol) { "SPY" }

  context "with puts" do
    context "given a bull put combo" do
      let(:container) { make_put_vertical_position(side: :short) }
      let(:strike1) { spread.legs[0].strike }
      let(:strike2) { spread.legs[1].strike }

      describe "#strike" do
        subject(:strike) { vertical.strike }
        it "returns the highest strike" do
          expect(strike).to eq strike1
        end
      end

      describe "#anchor_strike" do
        subject(:anchor_strike) { vertical.anchor_strike }

        it "returns the highest strike" do
          expect(anchor_strike).to eq strike1
        end
      end

      describe "#wing_strike" do
        subject(:wing_strike) { vertical.wing_strike }
        it "returns the lowest strike" do
          expect(wing_strike).to eq strike2
        end
      end

      describe "#expiration_date" do
        subject(:expiration_date) { vertical.expiration_date.date }
        it "returns the lowest strike" do
          expect(expiration_date).to eq spread.legs[0].expiration_date.date
        end
      end

      describe "#side" do
        subject(:side) { vertical.side }
        it "returns :short" do
          expect(side).to eq spread.legs[0].side
        end
      end

      describe "#short?" do
        subject(:short?) { vertical.short? }
        it "returns true" do
          expect(short?).to be true
        end
      end

      describe "#long?" do
        subject(:long?) { vertical.long? }
        it "returns false" do
          expect(long?).to be false
        end
      end
    end

    context "given a bear put combo" do
      let(:container) { make_put_vertical_position(side: :long) }
      let(:strike1) { spread.legs[0].strike }
      let(:strike2) { spread.legs[1].strike }

      describe "#strike" do
        subject(:strike) { vertical.strike }
        it "returns the highest strike" do
          expect(strike).to eq strike1
        end
      end

      describe "#anchor_strike" do
        subject(:anchor_strike) { vertical.anchor_strike }

        it "returns the highest strike" do
          expect(anchor_strike).to eq strike1
        end
      end

      describe "#wing_strike" do
        subject(:wing_strike) { vertical.wing_strike }
        it "returns the lowest strike" do
          expect(wing_strike).to eq strike2
        end
      end

      describe "#expiration_date" do
        subject(:expiration_date) { vertical.expiration_date.date }
        it "returns the lowest strike" do
          expect(expiration_date).to eq spread.legs[0].expiration_date.date
        end
      end

      describe "#side" do
        subject(:side) { vertical.side }
        it "returns :long" do
          expect(side).to eq spread.legs[0].side
        end
      end

      describe "#short?" do
        subject(:short?) { vertical.short? }
        it "returns false" do
          expect(short?).to be false
        end
      end

      describe "#long?" do
        subject(:long?) { vertical.long? }
        it "returns long" do
          expect(long?).to be true
        end
      end
    end
  end

  context "with calls" do
    context "given a bear call combo" do
      let(:container) { make_call_vertical_position(side: :short) }
      let(:strike1) { spread.legs[0].strike }
      let(:strike2) { spread.legs[1].strike }

      describe "#strike" do
        subject(:strike) { vertical.strike }
        it "returns the lowest strike" do
          expect(strike).to eq strike1
        end
      end

      describe "#anchor_strike" do
        subject(:anchor_strike) { vertical.anchor_strike }

        it "returns the lowest strike" do
          expect(anchor_strike).to eq strike1
        end
      end

      describe "#wing_strike" do
        subject(:wing_strike) { vertical.wing_strike }
        it "returns the highest strike" do
          expect(wing_strike).to eq strike2
        end
      end

      describe "#expiration_date" do
        subject(:expiration_date) { vertical.expiration_date.date }
        it "returns the expiration" do
          expect(expiration_date).to eq spread.legs[0].expiration_date.date
        end
      end

      describe "#side" do
        subject(:side) { vertical.side }
        it "returns :short" do
          expect(side).to eq spread.legs[0].side
        end
      end

      describe "#short?" do
        subject(:short?) { vertical.short? }
        it "returns true" do
          expect(short?).to be true
        end
      end

      describe "#long?" do
        subject(:long?) { vertical.long? }
        it "returns false" do
          expect(long?).to be false
        end
      end
    end

    context "given a bull call combo" do
      let(:container) { make_call_vertical_position(side: :long) }
      let(:strike1) { spread.legs[0].strike }
      let(:strike2) { spread.legs[1].strike }

      describe "#strike" do
        subject(:strike) { vertical.strike }
        it "returns the lowest strike" do
          expect(strike).to eq strike1
        end
      end

      describe "#anchor_strike" do
        subject(:anchor_strike) { vertical.anchor_strike }

        it "returns the lowest strike" do
          expect(anchor_strike).to eq strike1
        end
      end

      describe "#wing_strike" do
        subject(:wing_strike) { vertical.wing_strike }
        it "returns the highest strike" do
          expect(wing_strike).to eq strike2
        end
      end

      describe "#expiration_date" do
        subject(:expiration_date) { vertical.expiration_date.date }
        it "returns the expiration" do
          expect(expiration_date).to eq spread.legs[0].expiration_date.date
        end
      end

      describe "#side" do
        subject(:side) { vertical.side }
        it "returns :long" do
          expect(side).to eq spread.legs[0].side
        end
      end

      describe "#short?" do
        subject(:short?) { vertical.short? }
        it "returns false" do
          expect(short?).to be false
        end
      end

      describe "#long?" do
        subject(:long?) { vertical.long? }
        it "returns true" do
          expect(long?).to be true
        end
      end
    end
  end
end
