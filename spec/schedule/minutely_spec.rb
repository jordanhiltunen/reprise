# frozen_string_literal: true

require_relative "../support/series_helpers"
require_relative "../support/time_zone_helpers"

RSpec.describe "#repeat_minutely", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Coruscate::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { Time.current.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.minutes }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  def localized_occurrence_start_time(occurrence)
    occurrence.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z")
  end

  before { travel_to Time.new(2024, 6, 30, 0, 0, 0, "-07:00") }

  it "generates an array of daily occurrences" do
    schedule.repeat_minutely(**series_options, time_of_day: nil)

    expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
      to contain_exactly(
           "Sun Jun 30 2024 12:01AM -0700",
           "Sun Jun 30 2024 12:02AM -0700",
           "Sun Jun 30 2024 12:03AM -0700",
           "Sun Jun 30 2024 12:04AM -0700",
         )
  end

  context "when an interval is included" do
    let(:ends_at) { starts_at + 10.minutes }

    it "generates an array of every nth occurrence" do
      schedule.repeat_minutely(**series_options, time_of_day: nil, interval: 2)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Jun 30 2024 12:01AM -0700",
             "Sun Jun 30 2024 12:03AM -0700",
             "Sun Jun 30 2024 12:05AM -0700",
             "Sun Jun 30 2024 12:07AM -0700",
             "Sun Jun 30 2024 12:09AM -0700"
           )
    end
  end

  context "when the schedule straddles a transition from Standard Time to Daylight Savings Time (DST)" do
    let(:starts_at) { TimeZoneHelpers.minutes_before_los_angeles_transition_to_dst }

    it "generates an array of daily occurrences across the DST change" do
      schedule.repeat_minutely(**series_options, time_of_day: nil)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Mar 10 2024 01:59AM -0800",
             # N.B. Notice the DST jump
             "Sun Mar 10 2024 03:00AM -0700",
             "Sun Mar 10 2024 03:01AM -0700",
             "Sun Mar 10 2024 03:02AM -0700"
           )
    end

    context "when the schedule straddles a transition from DST to Standard Time" do
      let(:starts_at) { TimeZoneHelpers.minutes_before_los_angeles_transition_to_st }
      let(:ends_at) { starts_at + (1.hours + 3.minutes) }

      it "generates an array of daily occurrences across the ST change" do
        schedule.repeat_minutely(**series_options, time_of_day: nil)

        occurrences = schedule.occurrences
        first_three_occurrences = occurrences.first(3)
        last_five_occurrences = occurrences.last(5)

        expect(first_three_occurrences.map { |o| localized_occurrence_start_time(o) }).
          to contain_exactly(
               "Sun Nov  3 2024 01:00AM -0700",
               "Sun Nov  3 2024 01:01AM -0700",
               "Sun Nov  3 2024 01:02AM -0700"
             )

        expect(last_five_occurrences.map { |o| localized_occurrence_start_time(o) }).
          to contain_exactly(
               "Sun Nov  3 2024 01:57AM -0700",
               "Sun Nov  3 2024 01:58AM -0700",
               "Sun Nov  3 2024 01:59AM -0700",
               # N.B. Clocks are turned back 1 hour at 2:00am
               "Sun Nov  3 2024 01:00AM -0800",
               "Sun Nov  3 2024 01:01AM -0800",
             )
      end
    end
  end
end
