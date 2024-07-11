# frozen_string_literal: true

require_relative "../support/series_helpers"
require_relative "../support/time_zone_helpers"

RSpec.describe "#repeat_hourly", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Coruscate::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { Time.current.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 6.hours }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  def localized_occurrence_start_time(occurrence)
    occurrence.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z")
  end

  before { travel_to Time.new(2024, 6, 30, 0, 0, 0, "-07:00") }

  it "generates an array of daily occurrences" do
    schedule.repeat_hourly(**series_options(time_of_day: { hour: 1, minute: 2, second: 3 }))

    expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
      to contain_exactly(
           "Sun Jun 30 2024 01:02AM -0700",
           "Sun Jun 30 2024 02:02AM -0700",
           "Sun Jun 30 2024 03:02AM -0700",
           "Sun Jun 30 2024 04:02AM -0700",
           "Sun Jun 30 2024 05:02AM -0700",
         )
  end

  context "when an interval is included" do
    let(:ends_at) { starts_at + 12.hours }

    it "generates an array of every nth occurrence" do
      schedule.repeat_hourly(
        time_of_day: { hour: 1, minute: 2, second: 3 },
        duration_in_seconds: 300,
        interval: 2
      )

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Jun 30 2024 01:02AM -0700",
             "Sun Jun 30 2024 03:02AM -0700",
             "Sun Jun 30 2024 05:02AM -0700",
             "Sun Jun 30 2024 07:02AM -0700",
             "Sun Jun 30 2024 09:02AM -0700",
             "Sun Jun 30 2024 11:02AM -0700"
           )
    end
  end

  context "when the schedule straddles a transition from Standard Time to Daylight Savings Time (DST)" do
    let(:starts_at) { TimeZoneHelpers.hours_before_los_angeles_transition_to_dst }

    it "generates an array of daily occurrences across the DST change" do
      schedule.repeat_hourly(**series_options)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sat Mar  9 2024 10:15PM -0800",
             "Sat Mar  9 2024 11:15PM -0800",
             "Sun Mar 10 2024 12:15AM -0800",
             "Sun Mar 10 2024 01:15AM -0800",
             # N.B. Notice the DST jump to 3:15 AM.
             # https://www.timeanddate.com/news/time/usa-start-dst-2024.html
             "Sun Mar 10 2024 03:15AM -0700",
             "Sun Mar 10 2024 04:15AM -0700",
           )
    end

    context "when the schedule straddles a transition from DST to Standard Time" do
      let(:starts_at) { TimeZoneHelpers.hours_before_los_angeles_transition_to_st }

      it "generates an array of daily occurrences across the ST change" do
        schedule.repeat_hourly(**series_options(time_of_day: { hour: 1, minute: 15 }))

        expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
          to contain_exactly(
               "Sat Nov  2 2024 10:15PM -0700",
               "Sat Nov  2 2024 11:15PM -0700",
               "Sun Nov  3 2024 12:15AM -0700",
               "Sun Nov  3 2024 01:15AM -0700",
               # N.B. Note the jump one hour back
               "Sun Nov  3 2024 01:15AM -0800",
               "Sun Nov  3 2024 02:15AM -0800",
             )
      end
    end
  end
end
