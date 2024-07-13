# frozen_string_literal: true

require "forwardable"

module Coruscate
  class Error < StandardError; end

  # @note On the interface of this class: all of the methods on +Coruscate::Schedule+ could have been
  #   transparently delegated to +Coruscate::Core::Schedule+, the internal schedule class that is
  #   implemented in Rust; instead, we define explicit proxy methods with obvious kwargs duplication,
  #   both to make it easier to generate YARD docs and to offer decent autocomplete support in IDEs.
  #   For any changes in the implementation of the interface, prefer DevX over DRY and save our
  #   sophistication budget for the underlying Rust extension.
  class Schedule
    extend ::Forwardable
    # @!macro [new] weekday
    #   @param weekday [Symbol] Accepts +:monday+, +:tuesday+, +:wednesday+, +:thursday+, or +:friday+.

    # @!macro [new] time_of_day
    #   @param time_of_day [Hash,Time,nil]
    #     Either a local time value from which the hour, minute, and second
    #     should be derived, or a hash containing at least one of +hour+, +minute+,
    #     or +second+. If +nil+, the time of day will be inferred from the schedule's
    #     +starts_at+ value.
    #   @option time_of_day [Integer] :hour, >= 0 && <= 23
    #   @option time_of_day [Integer] :minute, >= 0 && <= 59
    #   @option time_of_day [Integer] :second, >= 0 && <= 59
    #   @raise [UnsupportedTypeError] if +time_of_day+ is neither a +Hash+ nor a +Time+.
    #   @raise [InvalidHashError] if the hash representation of the time is invalid.
    #   @raise [RangeError] if either the hour, minute, or second is out-of-range.

    # @!macro [new] duration_in_seconds

    # All schedules must be constructed with a valid +starts_at+ and +ends_at+ time.
    # Coruscate does not support infinitely-recurring schedules, or the bounding
    # of schedules on the basis of a maximum occurrence count.
    #
    # @param starts_at [Time]
    #   The beginning of the schedule; the earliest possible moment for a valid occurrence.
    # @param ends_at [Time]
    #   The end of the schedule; the latest possible moment for a valid occurrence.
    # @param time_zone [String]
    #   Must be an unambiguous, valid time-zone according to +ActiveSupport::TimeZone::find_tzinfo+.
    #   See https://github.com/tzinfo/tzinfo/issues/53
    # @raise [TZInfo::InvalidTimezoneIdentifier] if the time zone is ambiguous or invalid.
    def initialize(starts_at:, ends_at:, time_zone:)
      @starts_at = starts_at
      @ends_at = ends_at
      @time_zone = ActiveSupport::TimeZone.find_tzinfo(time_zone).identifier
      @default_time_of_day = TimeOfDay.new(starts_at)
    end

    # @return [Array<Coruscate::Core::Occurrence>]
    def occurrences
      internal_schedule.occurrences
    end

    # @!macro time_of_day
    # @param duration_in_seconds [Integer]
    # @return [void]
    def repeat_minutely(time_of_day: nil, duration_in_seconds:, interval: 1, starts_at: nil, ends_at: nil, label: nil)
      internal_schedule.repeat_minutely(
        time_of_day: TimeOfDay.new(time_of_day || self.starts_at).to_h,
        duration_in_seconds:,
        interval:,
        starts_at_unix_timestamp: starts_at.presence&.to_i,
        ends_at_unix_timestamp: ends_at.presence&.to_i,
        label:
      )
    end

    # @!macro time_of_day
    # @param duration_in_seconds [Integer]
    # @return [void]
    def repeat_hourly(time_of_day: nil, duration_in_seconds:, interval: 1, starts_at: nil, ends_at: nil, label: nil)
      internal_schedule.repeat_hourly(
        time_of_day: TimeOfDay.new(time_of_day || self.starts_at).to_h,
        duration_in_seconds:,
        interval:,
        starts_at_unix_timestamp: starts_at.presence&.to_i,
        ends_at_unix_timestamp: ends_at.presence&.to_i,
        label:
      )
    end

    # @!macro time_of_day
    # @param duration_in_seconds [Integer]
    # @return [void]
    def repeat_daily(time_of_day: nil, duration_in_seconds:, interval: 1, starts_at: nil, ends_at: nil, label: nil)
      internal_schedule.repeat_daily(
        time_of_day: TimeOfDay.new(time_of_day || self.starts_at).to_h,
        duration_in_seconds:,
        interval:,
        starts_at_unix_timestamp: starts_at.presence&.to_i,
        ends_at_unix_timestamp: ends_at.presence&.to_i,
        label:
      )
    end

    # @!macro weekday
    # @!macro time_of_day
    # @param duration_in_seconds [Integer]
    # @return [void]
    # @example with an +hms_opts+ +time_of_day+ hash
    #   schedule.repeat_weekly(:monday, time_of_day: { hour: 6 }, duration_in_seconds: 30)
    # @example with a local time for +time_of_day+
    #   local_time = Time.current.in_time_zone(my_current_time_zone)
    #   schedule.repeat_weekly(:monday, time_of_day: local_time, duration_in_seconds: 30)
    def repeat_weekly(weekday, time_of_day: nil, duration_in_seconds:, interval: 1, starts_at: nil, ends_at: nil, label: nil)
      internal_schedule.repeat_weekly(
        weekday,
        time_of_day: TimeOfDay.new(time_of_day || self.starts_at).to_h,
        duration_in_seconds:,
        interval:,
        starts_at_unix_timestamp: starts_at.presence&.to_i,
        ends_at_unix_timestamp: ends_at.presence&.to_i,
        label:
      )
    end

    # @param day_number [Integer] The number of the day in the month; >= 1 && <= 31
    # @!macro time_of_day
    # @param duration_in_seconds [Integer]
    # @return [void]
    # @example
    #   schedule.repeat_monthly_by_day(15, time_of_day: { hour: 9 }, duration_in_seconds: 30)
    def repeat_monthly_by_day(day_number, time_of_day:, duration_in_seconds:, interval: 1, starts_at: nil, ends_at: nil, label: nil)
      internal_schedule.repeat_monthly_by_day(
        day_number,
        time_of_day: TimeOfDay.new(time_of_day || self.starts_at).to_h,
        duration_in_seconds:,
        interval:,
        starts_at_unix_timestamp: starts_at.presence&.to_i,
        ends_at_unix_timestamp: ends_at.presence&.to_i,
        label:
      )
    end

    # @!macro weekday
    # @param nth_day [Integer] The nth weekday, 0-indexed; e.g. 0 might represent the first wednesday
    # @!macro time_of_day
    # @param duration_in_seconds [Integer]
    # @return [void]
    def repeat_monthly_by_nth_weekday(weekday, nth_day, time_of_day:, duration_in_seconds:, interval: 1, starts_at: nil, ends_at: nil, label: nil)
      internal_schedule.repeat_monthly_by_nth_weekday(
        weekday,
        nth_day,
        time_of_day: TimeOfDay.new(time_of_day || self.starts_at).to_h,
        duration_in_seconds:,
        interval:,
        starts_at_unix_timestamp: starts_at.presence&.to_i,
        ends_at_unix_timestamp: ends_at.presence&.to_i,
        label:
      )
    end

    # Add a time interval between which no occurrences are valid.
    # Any occurrences that overlap with an exclusion are removed.
    # @param starts_at [Time]
    # @param ends_at [Time]
    def add_exclusion(starts_at:, ends_at:)
      internal_schedule.add_exclusion(
        starts_at_unix_timestamp: starts_at.to_i,
        ends_at_unix_timestamp: ends_at.to_i
      )
    end

    # def add_exclusions()
    #
    # end

    def_delegators :internal_schedule,
                   :add_exclusions

    private

    attr_reader :starts_at, :ends_at, :time_zone, :default_time_of_day

    def internal_schedule
      return @_internal_schedule if defined?(@_internal_schedule)

      @_internal_schedule = ::Coruscate::Core::Schedule.new(
        starts_at.to_i,
        ends_at.to_i,
        time_zone
      )
    end
  end
end
