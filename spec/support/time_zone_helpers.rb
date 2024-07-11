# frozen_string_literal: true

module TimeZoneHelpers
  LOS_ANGELES_TIME_ZONE = "America/Los_Angeles"

  module_function

  def hours_before_los_angeles_transition_to_dst
    Time.new(2024, 3, 9, 22, 0, 0, "-0800")
  end

  def hours_before_los_angeles_transition_to_st
    Time.new(2024, 11, 2, 22, 0, 0, "-0700")
  end
end
