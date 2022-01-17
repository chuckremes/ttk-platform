RSpec.describe TTK::Platform::Wrappers::Combo::Internal::Calls do

  describe "#project_price_at" do
    let(:container) { described_class.new(legs) }
    subject(:project) { container.project_price_at(underlying: underlying, target: target_strike) }

    before do
      allow(container).to receive(:delta).and_return(delta)
      allow(container).to receive(:gamma).and_return(gamma)
      allow(container).to receive(:midpoint).and_return(midpoint)
    end

    context "with long calls" do
      let(:legs) { make_call_vertical_position_legs(side: :long) }
      let(:delta) { 0.50 }
      let(:gamma) { 0.04 }
      let(:midpoint) { 2.0 }

      context "when price is close to strike and above it then" do
        let(:underlying) { 422.10 }
        let(:target_strike) { 422.0 }

        it "price increases above midpoint" do
          change = 0.05 # about 5 cents
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is above the strike but within a dollar then" do
        let(:underlying) { 422.90 }
        let(:target_strike) { 422.0 }

        it "price increases above midpoint" do
          change = 0.45
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is far above the strike by more than a dollar then" do
        let(:underlying) { 425.90 }
        let(:target_strike) { 422.0 }

        it "price increases far above midpoint" do
          change = 2.33
          expect(project).to be_within(0.005).of(midpoint + change)
        end
      end

      context "when price is close to strike and below it then" do
        let(:underlying) { 421.90 }
        let(:target_strike) { 422.0 }

        it "price decreases below midpoint" do
          change = -0.05
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is below the strike within a dollar then" do
        let(:underlying) { 421.10 }
        let(:target_strike) { 422.0 }

        it "price decreases below midpoint" do
          change = -0.45
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is below the strike by more than a dollar then" do
        let(:underlying) { 418.10 }
        let(:target_strike) { 422.0 }

        it "price decreases below midpoint" do
          change = -1.63
          expect(project).to be_within(0.005).of(midpoint + change)
        end
      end
    end

    context "with short calls" do
      let(:legs) { make_call_vertical_position_legs(side: :short) }
      let(:delta) { -0.50 }
      let(:gamma) { -0.04 }
      let(:midpoint) { 2.0 }

      context "when price is close to strike and above it then" do
        let(:underlying) { 422.10 }
        let(:target_strike) { 422.0 }

        it "price increases above midpoint" do
          change = 0.05 # about 5 cents
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is above the strike but within a dollar then" do
        let(:underlying) { 422.90 }
        let(:target_strike) { 422.0 }

        it "price increases above midpoint" do
          change = 0.45
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is far above the strike by more than a dollar then" do
        let(:underlying) { 425.90 }
        let(:target_strike) { 422.0 }

        it "price increases far above midpoint" do
          change = 2.33
          expect(project).to be_within(0.005).of(midpoint + change)
        end
      end

      context "when price is close to strike and below it then" do
        let(:underlying) { 421.90 }
        let(:target_strike) { 422.0 }

        it "price decreases below midpoint" do
          change = -0.05
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is below the strike within a dollar then" do
        let(:underlying) { 421.10 }
        let(:target_strike) { 422.0 }

        it "price decreases below midpoint" do
          change = -0.45
          expect(project).to be_within(0.001).of(midpoint + change)
        end
      end

      context "when price is below the strike by more than a dollar then" do
        let(:underlying) { 418.10 }
        let(:target_strike) { 422.0 }

        it "price decreases below midpoint" do
          change = -1.63
          expect(project).to be_within(0.005).of(midpoint + change)
        end
      end
    end
  end

end