# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_weekly", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.weeks }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_weekly(:monday, **series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_weekly(:monday, **series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of weekly occurrences" do
    schedule.repeat_weekly(:monday, duration_in_seconds: 30.minutes)

    expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
      .to contain_exactly(
        "Mon Apr  1 2024 01:59AM -0700",
        "Mon Apr  8 2024 01:59AM -0700",
        "Mon Mar 11 2024 01:59AM -0700",
        "Mon Mar 18 2024 01:59AM -0700",
        "Mon Mar 25 2024 01:59AM -0700"
      )
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024).in_time_zone(time_zone)
    end

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_weekly(:sunday, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          # N.B. The first occurrence begins
          # after the local time gap, one
          # hour forward.
          "Sun Mar 10 2024 03:15AM -0700",
          "Sun Mar 17 2024 02:15AM -0700",
          "Sun Mar 24 2024 02:15AM -0700",
          "Sun Mar 31 2024 02:15AM -0700",
          "Sun Apr  7 2024 02:15AM -0700",
        )
    end
  end

  context "when the schedule crosses a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 1.week).in_time_zone(time_zone)
    end

    it "generates an array of occurrences across the DST change" do
      schedule.repeat_weekly(:monday, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Mon Mar  4 2024 01:59AM -0800",
          # N.B. Transition to DST
          "Mon Mar 11 2024 01:59AM -0700",
          "Mon Mar 18 2024 01:59AM -0700",
          "Mon Mar 25 2024 01:59AM -0700",
          "Mon Apr  1 2024 01:59AM -0700",
      )
    end

    context "and the series time of day falls during an ambiguous time" do
      let(:starts_at) do
        (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 7.days + 5.minutes)
      end

      it "generates an array of occurrences across the DST change" do
        schedule.repeat_weekly(:sunday, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

        expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
          .to contain_exactly(
            "Sun Apr  7 2024 02:15AM -0700",
            "Sun Mar  3 2024 02:15AM -0800",
            # N.B. Transition to DST. For this
            # one ambiguous occurrence, it temporarily
            # appears one hour ahead.
            "Sun Mar 10 2024 03:15AM -0700",
            "Sun Mar 17 2024 02:15AM -0700",
            "Sun Mar 24 2024 02:15AM -0700",
            "Sun Mar 31 2024 02:15AM -0700"
          )
      end
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 7.days + 5.minutes)
    end

    it "generates an array of occurrences across the ST change" do
      schedule.repeat_weekly(:sunday, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Oct 27 2024 02:15AM -0700",
          # N.B. Transition to ST, with a bias
          # towards the instance of the time that
          # falls in the new offset.
          "Sun Nov  3 2024 02:15AM -0800",
          "Sun Nov 10 2024 02:15AM -0800",
          "Sun Nov 17 2024 02:15AM -0800",
          "Sun Nov 24 2024 02:15AM -0800",
        )
    end
  end
end
