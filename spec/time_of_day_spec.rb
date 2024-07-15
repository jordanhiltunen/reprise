# frozen_string_literal: true

require "spec_helper"

RSpec.describe Reprise::TimeOfDay do
  describe "#initialize" do
    describe "errors" do
      it "raises UnsupportedTypeError when an unsupported time_of_day is given" do
        expect { described_class.new(5) }.to raise_error(
          Reprise::TimeOfDay::UnsupportedTypeError, "Integer is not a supported type"
        )
      end

      it "raises InvalidHashError when the hms_opts hash contains unexpected keys" do
        expect { described_class.new({ years: 12 }) }
          .to raise_error(Reprise::TimeOfDay::InvalidHashError)
      end

      it "raises RangeError when the time of day is out-of-range" do
        expect { described_class.new({ hour: 25 }) }
          .to raise_error(Reprise::TimeOfDay::RangeError)
      end
    end
  end

  describe "#to_h" do
    context "when initialized with a local time" do
      it "returns a hash representation of the local time" do
        time_of_day = described_class.new(Time.new(2024, 6, 30, 8, 45, 10, "-10:00"))

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
        time_of_day = described_class.new({ minute: 30 })

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
