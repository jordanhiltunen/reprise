# frozen_string_literal: true

module TimeZoneHelpers
  LOS_ANGELES_TIME_ZONE = "America/Los_Angeles"

  # Daylight Saving Time (DST) will begin at 2 a.m. on Sunday, March 10, 2024; the clocks are set
  # ahead by one hour.
  ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 = Time.new(2024, 3, 10, 1, 59, 0, "-0800").freeze
  # Standard Time (ST) will begin at 2:00 am on Sunday, November 3, 2024; the clocks are turned
  # back by one hour.
  ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 = Time.new(2024, 11, 3, 0, 59, 0, "-0700").freeze
end
