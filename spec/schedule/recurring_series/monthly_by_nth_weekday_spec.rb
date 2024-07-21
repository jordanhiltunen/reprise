# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_monthly_by_nth_weekday", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.months }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_monthly_by_nth_weekday(:tuesday, 2, **series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_monthly_by_nth_weekday(:tuesday, 2, **series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports an optional count argument" do
    let(:series_options_hash) { series_options }
    let(:occurrences) do
      schedule.repeat_monthly_by_nth_weekday(:tuesday, 2, **series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of monthly occurrences with a fixed weekday" do
    schedule.repeat_monthly_by_nth_weekday(:tuesday, 2, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)

    expect(
      schedule.occurrences.map { |o| o.starts_at.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
    ).to contain_exactly(
      "Tue Mar 19 2024 01:02AM -0700",
      "Tue Apr 16 2024 01:02AM -0700",
      "Tue May 21 2024 01:02AM -0700",
      "Tue Jun 18 2024 01:02AM -0700",
      "Tue Jul 16 2024 01:02AM -0700"
    )
  end

  it "allows negative indexing into the monthly occurrences" do
    schedule.repeat_monthly_by_nth_weekday(
      :friday, -1, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300
    )

    expect(
      schedule.occurrences.map { |o| o.starts_at.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
    ).to contain_exactly(
      "Fri Mar 29 2024 01:02AM -0700",
      "Fri Apr 26 2024 01:02AM -0700",
      "Fri May 31 2024 01:02AM -0700",
      "Fri Jun 28 2024 01:02AM -0700",
      "Fri Jul 26 2024 01:02AM -0700"
    )
  end

  it "can handle nth weekday edge cases that do not occur every month" do
    # The fifth (NB: 4; zeroth indexing) wednesday of a month is relatively rare.
    schedule.repeat_monthly_by_nth_weekday(:wednesday, 4, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)

    expect(
      schedule.occurrences.map { |o| o.starts_at.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
    ).to contain_exactly(
      "Wed May 29 2024 01:02AM -0700",
      "Wed Jul 31 2024 01:02AM -0700"
    )
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 + 5.minutes).in_time_zone(time_zone)
    end

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_monthly_by_nth_weekday(:sunday, 1, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          # N.B. The first occurrence begins
          # after the local time gap, one
          # hour forward.
          "Sun Mar 10 2024 03:15AM -0700",
          "Sun Apr 14 2024 02:15AM -0700",
          "Sun May 12 2024 02:15AM -0700",
          "Sun Jun  9 2024 02:15AM -0700",
          "Sun Jul 14 2024 02:15AM -0700",
        )
    end
  end

  context "when the schedule crosses a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 2.months).in_time_zone(time_zone)
    end

    it "generates an array of occurrences across the DST change" do
      schedule.repeat_monthly_by_nth_weekday(:sunday, 1, time_of_day: { hour: 1, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sun Jan 14 2024 01:15AM -0800",
          "Sun Feb 11 2024 01:15AM -0800",
          "Sun Mar 10 2024 01:15AM -0800",
          # N.B. Transition to DST
          "Sun Apr 14 2024 01:15AM -0700",
          "Sun May 12 2024 01:15AM -0700",
          "Sun Jun  9 2024 01:15AM -0700"
        )
    end

    context "and the series time of day falls during an ambiguous time" do
      let(:starts_at) do
        (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 2.months).in_time_zone(time_zone)
      end

      it "generates an array of occurrences across the DST change" do
        schedule.repeat_monthly_by_nth_weekday(:sunday, 1, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

        expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
          .to contain_exactly(
            "Sun Jan 14 2024 02:15AM -0800",
            "Sun Feb 11 2024 02:15AM -0800",
            # N.B. Transition to DST. For this
            # one ambiguous occurrence, it temporarily
            # appears one hour ahead.
            "Sun Mar 10 2024 03:15AM -0700",
            "Sun Apr 14 2024 02:15AM -0700",
            "Sun May 12 2024 02:15AM -0700",
            "Sun Jun  9 2024 02:15AM -0700"
          )
      end
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 1.month)
    end

    it "generates an array of occurrences across the ST change" do
      schedule.repeat_monthly_by_nth_weekday(:sunday, 0, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sun Oct  6 2024 02:15AM -0700",
          # N.B. Transition to ST, with a bias
          # towards the instance of the time that
          # falls in the new offset.
          "Sun Nov  3 2024 02:15AM -0800",
          "Sun Dec  1 2024 02:15AM -0800",
          "Sun Jan  5 2025 02:15AM -0800",
          "Sun Feb  2 2025 02:15AM -0800",
          "Sun Mar  2 2025 02:15AM -0800"
        )
    end
  end
end
