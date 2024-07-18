# frozen_string_literal: true

require "spec_helper"

RSpec.describe "interval queries", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { Time.new(2024, 6, 30, 0, 0, 0, "-10:00") }
  let(:ends_at) { starts_at + 6.hours }
  let(:time_zone) { "Hawaii" }

  let(:base_occurrences) do
    schedule.repeat_hourly(duration_in_seconds: 30.minutes)
    schedule.occurrences
  end

  def expect_underlying_set_of_occurrences
    expect(base_occurrences.map { |o| localized_occurrence_start_and_end_time(o) })
      .to contain_exactly(
        "Sun Jun 30 2024 12:00AM -1000 - Sun Jun 30 2024 12:30AM -1000",
        "Sun Jun 30 2024 01:00AM -1000 - Sun Jun 30 2024 01:30AM -1000",
        "Sun Jun 30 2024 02:00AM -1000 - Sun Jun 30 2024 02:30AM -1000",
        "Sun Jun 30 2024 03:00AM -1000 - Sun Jun 30 2024 03:30AM -1000",
        "Sun Jun 30 2024 04:00AM -1000 - Sun Jun 30 2024 04:30AM -1000",
        "Sun Jun 30 2024 05:00AM -1000 - Sun Jun 30 2024 05:30AM -1000",
      )
  end

  before { expect_underlying_set_of_occurrences }

  describe "#occurrences_between" do
    context "when include_overlapping is false" do
      it "returns the occurrences that are contained entirely within the interval" do
        occurrences_between = schedule.occurrences_between(
          Time.new(2024, 6, 30, 2, 15, 0, "-10:00"),
          Time.new(2024, 6, 30, 5, 10, 0, "-10:00")
        )

        expect(occurrences_between.map { |o| localized_occurrence_start_and_end_time(o) })
          .to contain_exactly(
            "Sun Jun 30 2024 03:00AM -1000 - Sun Jun 30 2024 03:30AM -1000",
            "Sun Jun 30 2024 04:00AM -1000 - Sun Jun 30 2024 04:30AM -1000",
          )
      end
    end

    context "when include_overlapping is true" do
      it "returns the occurrences that transpire at least in part within the interval" do
        occurrences_between = schedule.occurrences_between(
          Time.new(2024, 6, 30, 2, 15, 0, "-10:00"),
          Time.new(2024, 6, 30, 5, 10, 0, "-10:00"),
          include_overlapping: true
        )

        expect(occurrences_between.map { |o| localized_occurrence_start_and_end_time(o) })
          .to contain_exactly(
            "Sun Jun 30 2024 02:00AM -1000 - Sun Jun 30 2024 02:30AM -1000",
            "Sun Jun 30 2024 03:00AM -1000 - Sun Jun 30 2024 03:30AM -1000",
            "Sun Jun 30 2024 04:00AM -1000 - Sun Jun 30 2024 04:30AM -1000",
            "Sun Jun 30 2024 05:00AM -1000 - Sun Jun 30 2024 05:30AM -1000"
          )
      end
    end
  end

  describe "#occurs_between?" do
    context "when include_overlapping is false" do
      it "returns true when there are occurrences that are contained entirely within the interval" do
        expect(
          schedule.occurs_between?(
            Time.new(2024, 6, 30, 2, 15, 0, "-10:00"),
            Time.new(2024, 6, 30, 5, 10, 0, "-10:00"),
            include_overlapping: false
          )
        ).to eq(true)
      end

      it "returns false when there are no occurrences within the interval" do
        expect(
          schedule.occurs_between?(
            Time.new(2024, 6, 30, 2, 15, 0, "-10:00"),
            Time.new(2024, 6, 30, 3, 15, 0, "-10:00"),
            include_overlapping: false
          )
        ).to eq(false)
      end
    end

    context "when include_overlapping is true" do
      it "returns true when there are occurrences that transpire at least in part within the interval" do
        expect(
          schedule.occurs_between?(
            Time.new(2024, 6, 30, 2, 15, 0, "-10:00"),
            Time.new(2024, 6, 30, 3, 15, 0, "-10:00"),
            include_overlapping: true
          )
        ).to eq(true)
      end

      it "returns false when there are no occurrences within the interval" do
        expect(
          schedule.occurs_between?(
            Time.new(2024, 6, 30, 2, 31, 0, "-10:00"),
            Time.new(2024, 6, 30, 2, 59, 0, "-10:00"),
            include_overlapping: false
          )
        ).to eq(false)
      end
    end
  end
end
