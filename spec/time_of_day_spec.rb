require "spec_helper"

RSpec.describe Coruscate::TimeOfDay do
  describe ".new" do
    describe "errors" do
      it "raises MissingArgumentError when no constructor params are given" do
        expect { described_class.new }.to raise_error(Coruscate::TimeOfDay::MissingArgumentError)
      end

      it "raises InvalidHashError when the hms_opts hash contains unexpected keys" do
        expect { described_class.new(hms_opts: { years: 12 }) }.
          to raise_error(Coruscate::TimeOfDay::InvalidHashError)
      end

      it "raises RangeError when the time of day is out-of-range" do
        expect { described_class.new(hms_opts: { hour: 25 }) }.
          to raise_error(Coruscate::TimeOfDay::RangeError)
      end
    end
  end

  describe "#to_h" do
    context "when initialized with a local time" do
      it "returns a hash representation of the local time" do
        time_of_day = described_class.new(time: Time.new(2024, 6, 30, 8, 45, 10, "-10:00"))

        expect(time_of_day.to_h).to eq(
          {
            hour: 8,
            minute: 45,
            second: 10
          }
        )
      end
    end

    context "when initialized with hms_opts" do
      it "returns default values of 0 for hms options that are not set" do
        time_of_day = described_class.new(hms_opts: { minute: 30 })

        expect(time_of_day.to_h).to eq(
          {
            hour: 0,
            minute: 30,
            second: 0
          }
        )
      end
    end
  end
end
