# frozen_string_literal: true

require "spec_helper"

RSpec.describe Reprise::TimeZoneIdentifier do
  describe ".to_s" do
    subject(:time_zone_identifier) { described_class.new(time_zone:, datetime_source:) }

    let(:datetime_source) { Time.current.in_time_zone(TimeZoneHelpers::LOS_ANGELES_TIME_ZONE) }
    let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

    context "when the given time_zone is valid" do
      context "because the time_zone is an IANA identifier" do
        it "no-ops and returns the time zone identifier when an IANA identifier is given" do
          expect(time_zone_identifier.to_s).to eq(TimeZoneHelpers::LOS_ANGELES_TIME_ZONE)
        end
      end

      context "because the time_zone is a Rails time zone name" do
        # https://github.com/rails/rails/blob/19eebf6d33dd15a0172e3ed2481bec57a89a2404/activesupport/lib/active_support/values/time_zone.rb#L39C8-L39C34
        let(:time_zone) { "Pacific Time (US & Canada)" }

        it "returns the time zone identifier for a Rails time zone name" do
          expect(time_zone_identifier.to_s).to eq(TimeZoneHelpers::LOS_ANGELES_TIME_ZONE)
        end
      end
    end

    context "when an invalid time_zone is given" do
      let(:time_zone) { "CEST" }

      it "raises Reprise::InvalidTimeZoneError" do
        expect { time_zone_identifier.to_s }.to raise_error(
          Reprise::InvalidTimeZoneError,
          /"CEST" is not a valid, unambiguous IANA Time Zone Database identifier/
        )
      end
    end

    context "when no time_zone is given" do
      let(:time_zone) { nil }

      context "and the datetime_source is a Time object" do
        let(:datetime_source) { Time.now }

        it "returns the Etc/UTC IANA identifier" do
          expect(time_zone_identifier.to_s).to eq("Etc/UTC")
        end
      end

      context "and the datetime_source is an ActiveSupport::TimeWithZone object" do
        let(:datetime_source) { Time.current.in_time_zone("Hawaii") }

        it "returns the IANA time zone identifier of the datetime_source" do
          expect(time_zone_identifier.to_s).to eq("Pacific/Honolulu")
        end
      end
    end
  end
end
