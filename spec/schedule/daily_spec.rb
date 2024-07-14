# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_daily", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Coruscate::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { Time.current.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.days }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  def localized_occurrence_start_time(occurrence)
    occurrence.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z")
  end

  before { travel_to Time.new(2024, 6, 30, 0, 0, 0, "-07:00") }

  it "generates an array of daily occurrences" do
    schedule.repeat_daily(**series_options(time_of_day: { hour: 1, minute: 2, second: 3 }))

    expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
      .to contain_exactly(
        "Sun Jun 30 2024 01:02AM -0700",
        "Mon Jul  1 2024 01:02AM -0700",
        "Tue Jul  2 2024 01:02AM -0700",
        "Wed Jul  3 2024 01:02AM -0700",
        "Thu Jul  4 2024 01:02AM -0700"
      )
  end

  context "when the schedule straddles a transition from Standard Time to Daylight Savings Time (DST)" do
    let(:starts_at) { TimeZoneHelpers.hours_before_los_angeles_transition_to_dst - 1.day }

    it "generates an array of daily occurrences across the DST change" do
      schedule.repeat_daily(**series_options)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Fri Mar  8 2024 10:15PM -0800",
          "Sat Mar  9 2024 10:15PM -0800",
          "Sun Mar 10 2024 10:15PM -0700",
          "Mon Mar 11 2024 10:15PM -0700",
          "Tue Mar 12 2024 10:15PM -0700",
          "Wed Mar 13 2024 10:15PM -0700"
        )
    end

    context "and the series time of day falls during an ambiguous time" do
      it "generates an array of daily occurrences across the DST change" do
        schedule.repeat_daily(**series_options(time_of_day: { hour: 2, minute: 15 }))

        expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
          .to contain_exactly(
            "Sat Mar  9 2024 02:15AM -0800",
            # N.B. there is no 2:15 AM on this date;
            # the time zone advances by 1 hour at 2:00am.
            # We follow the Google Calendar approach, and return
            # the exact same UTC time, but in the new offset.
            "Sun Mar 10 2024 03:15AM -0700",
            "Mon Mar 11 2024 02:15AM -0700",
            "Tue Mar 12 2024 02:15AM -0700",
            "Wed Mar 13 2024 02:15AM -0700"
          )
      end
    end
  end

  context "when the schedule straddles a transition from DST to Standard Time" do
    let(:starts_at) { TimeZoneHelpers.hours_before_los_angeles_transition_to_st - 1.day }

    it "generates an array of daily occurrences across the ST change" do
      schedule.repeat_daily(**series_options(time_of_day: { hour: 1, minute: 15 }))

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sat Nov  2 2024 01:15AM -0700",
          # N.B. Clocks are turned back 1 hour at 2:00am
          # on November 3rd; we bias towards the new offset,
          # and return the "second" instance of the time.
          "Sun Nov  3 2024 01:15AM -0800",
          "Mon Nov  4 2024 01:15AM -0800",
          "Tue Nov  5 2024 01:15AM -0800",
          "Wed Nov  6 2024 01:15AM -0800"
        )
    end
  end
end
