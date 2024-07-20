# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_monthly_by_day", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.months }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_monthly_by_day(0, **series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_monthly_by_day(0, **series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of monthly occurrences" do
    schedule.repeat_monthly_by_day(1, **series_options)

    expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
      .to contain_exactly(
        "Mon Apr  1 2024 10:15PM -0700",
        "Wed May  1 2024 10:15PM -0700",
        "Sat Jun  1 2024 10:15PM -0700",
        "Mon Jul  1 2024 10:15PM -0700",
        "Thu Aug  1 2024 10:15PM -0700",
      )
  end

  it "skips months where the requested day does not appear" do
    schedule.repeat_monthly_by_day(31, **series_options)

    expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
      .to contain_exactly(
        "Sun Mar 31 2024 10:15PM -0700",
        "Fri May 31 2024 10:15PM -0700",
        "Wed Jul 31 2024 10:15PM -0700"
      )
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 + 5.minutes).in_time_zone(time_zone)
    end

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_monthly_by_day(10, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          # N.B. The first occurrence begins
          # after the local time gap, one
          # hour forward.
          "Sun Mar 10 2024 03:15AM -0700",
          "Wed Apr 10 2024 02:15AM -0700",
          "Fri May 10 2024 02:15AM -0700",
          "Mon Jun 10 2024 02:15AM -0700",
          "Wed Jul 10 2024 02:15AM -0700",
          "Sat Aug 10 2024 02:15AM -0700",
        )
    end
  end

  context "when the schedule crosses a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 1.month).in_time_zone(time_zone)
    end

    it "generates an array of occurrences across the DST change" do
      schedule.repeat_monthly_by_day(10, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sat Feb 10 2024 02:15AM -0800",
          # N.B. Transition to DST
          "Sun Mar 10 2024 03:15AM -0700",
          "Wed Apr 10 2024 02:15AM -0700",
          "Fri May 10 2024 02:15AM -0700",
          "Mon Jun 10 2024 02:15AM -0700",
        )
    end

    context "and the series time of day falls during an ambiguous time" do
      let(:starts_at) do
        (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 1.month + 5.minutes).in_time_zone(time_zone)
      end

      it "generates an array of occurrences across the DST change" do
        schedule.repeat_monthly_by_day(10, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

        expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
          .to contain_exactly(
            "Fri May 10 2024 02:15AM -0700",
            "Mon Jun 10 2024 02:15AM -0700",
            "Sat Feb 10 2024 02:15AM -0800",
            # N.B. Transition to DST. For this
            # one ambiguous occurrence, it temporarily
            # appears one hour ahead.
            "Sun Mar 10 2024 03:15AM -0700",
            "Wed Apr 10 2024 02:15AM -0700"
          )
      end
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 1.month + 5.minutes)
    end

    it "generates an array of occurrences across the ST change" do
      schedule.repeat_monthly_by_day(3, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Thu Oct  3 2024 02:15AM -0700",
          # N.B. Transition to ST, with a bias
          # towards the instance of the time that
          # falls in the new offset.
          "Sun Nov  3 2024 02:15AM -0800",
          "Tue Dec  3 2024 02:15AM -0800",
          "Fri Jan  3 2025 02:15AM -0800",
          "Mon Feb  3 2025 02:15AM -0800"
        )
    end
  end
end
