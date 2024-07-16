# frozen_string_literal: true

module Reprise
  class Error < StandardError; end

  # The +Reprise::Schedule+ class is the primary interface of the Reprise gem.
  #
  # It offers methods that enable you to:
  # - Initialize a new schedule.
  # - Add recurring series to the schedule via +#repeat_*+ methods.
  # - Mark specific intervals of time as excluded from the schedule via {Reprise::Schedule#add_exclusion} and {Reprise::Schedule#add_exclusions}.
  # - Query for the presence of occurrences within intervals of time via {Reprise::Schedule#occurs_between?}.
  # - Generate an array of all of the schedule's occurrences via {Reprise::Schedule#occurrences}.
  #
  # @private On the interface of this class: all of the methods on +Reprise::Schedule+ could have been
  #   transparently delegated to +Reprise::Core::Schedule+, the internal schedule class that is
  #   implemented in Rust; instead, we define explicit proxy methods with obvious kwargs duplication,
  #   both to make it easier to generate YARD docs and to offer decent autocomplete support in IDEs.
  #   For any changes in the implementation of the interface, prefer DevX over DRY and save our
  #   sophistication budget for the underlying Rust extension.
  class Schedule
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

    # @!macro [new] interval
    #   @param interval [Integer]
    #     This determines whether or not occurrences should be skipped.
    #     A value of +1+ means that every occurrence for the series should be returned;
    #     +2+, every other occurrence should be returned, etc.

    # @!macro [new] recurring_series_start_and_end_times
    #   @param starts_at [Time, nil] The time that the series should begin. If left blank,
    #     the series will start at the same time as the parent schedule.
    #   @param starts_at [Time, nil] The time that the series should end. If left blank,
    #     the series will end at the same time as the parent schedule.

    # @!macro [new] duration_in_seconds
    #   @param duration_in_seconds [Integer]
    #     This determines the end time of each occurrence ({Reprise::Core::Occurrence#end_time}), and also
    #     influences occurrence queries, and whether any added exclusions conflict with any of the schedule's
    #     occurrences.

    # @!macro [new] label
    #   @param label [String, nil] An optional label to apply to all of the occurrences
    #     that are generated from the series. See {Reprise::Core::Occurrence#label}.

    # All schedules must be constructed with a valid +starts_at+ and +ends_at+ time.
    # Reprise does not support infinitely-recurring schedules, or the bounding
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

    # Returns an array of occurrences sorted in order of ascending occurrence start time.
    # This method is not cached; on every call, it will recompute all of the schedule's occurrences.
    # @return [Array<Reprise::Core::Occurrence>]
    def occurrences
      internal_schedule.occurrences
    end

    # @!macro time_of_day
    # @!macro duration_in_seconds
    # @!macro interval
    # @!macro recurring_series_start_and_end_times
    # @!macro label
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
    # @!macro duration_in_seconds
    # @!macro interval
    # @!macro recurring_series_start_and_end_times
    # @!macro label
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
    # @!macro duration_in_seconds
    # @!macro interval
    # @!macro recurring_series_start_and_end_times
    # @!macro label
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
    # @!macro duration_in_seconds
    # @!macro interval
    # @!macro recurring_series_start_and_end_times
    # @!macro label
    # @return [void]
    # @example with a +time_of_day+ hash
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
    # @!macro duration_in_seconds
    # @!macro interval
    # @!macro recurring_series_start_and_end_times
    # @!macro label
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
    # @!macro duration_in_seconds
    # @!macro interval
    # @!macro recurring_series_start_and_end_times
    # @!macro label
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
    # Any occurrences that overlap with an exclusion are removed from the schedule's occurrences.
    # @param starts_at [Time] The time that the exclusion starts at
    # @param ends_at [Time] The time that the exclusion ends at
    def add_exclusion(starts_at:, ends_at:)
      internal_schedule.add_exclusion(
        starts_at_unix_timestamp: starts_at.to_i,
        ends_at_unix_timestamp: ends_at.to_i
      )
    end

    # Add time intervals between which no occurrences are valid.
    # Any occurrences that overlap with an exclusion are removed from the schedule's occurrences.
    # @param exclusions [Array<Array<Time,Time>>] An array of exclusion arrays, consisting of start
    #   and end +Time+ values.
    # @return [void]
    # @example
    #   schedule.add_exclusions([
    #     [exclusion_1_starts_at, exclusion_1_ends_at],
    #     [exclusion_2_starts_at, exclusion_2_ends_at],
    #   ])
    def add_exclusions(exclusions)
      internal_schedule.add_exclusions(
        exclusions.map {|e| e.map(&:to_i) }
      )
    end

    # @!macro [new] include_overlapping
    #   @param include_overlapping [Boolean] when true, the query will also consider
    #     occurrences that partially overlap with the given interval, not just the occurrences
    #     that are entirely contained within the interval.

    # Indicates whether one or more of your schedule's occurrences fall within the given interval.
    # @param starts_at [Time] The start of the interval to query
    # @param ends_at [Time] The end of the interval to query
    # @!macro include_overlapping
    # @return [Boolean]
    def occurs_between?(starts_at, ends_at, include_overlapping: false)
      occurrences_between(starts_at, ends_at, include_overlapping:).any?
    end

    # This method efficiently queries your schedule for occurrences that fall within a given interval.
    # @param starts_at [Time] The start of the interval to query
    # @param ends_at [Time] The end of the interval to query
    # @!macro include_overlapping
    # @return [Array<Reprise::Core::Occurrence>] an array of occurrences that occur between
    #   the given +starts_at+ and +ends_at+ bookends.
    def occurrences_between(starts_at, ends_at, include_overlapping: false)
      if include_overlapping
        internal_schedule.occurrences_overlapping_with_interval(starts_at.to_i, ends_at.to_i)
      else
        internal_schedule.occurrences_contained_within_interval(starts_at.to_i, ends_at.to_i)
      end
    end

    private

    attr_reader :starts_at, :ends_at, :time_zone, :default_time_of_day

    def internal_schedule
      return @_internal_schedule if defined?(@_internal_schedule)

      @_internal_schedule = ::Reprise::Core::Schedule.new(
        starts_at.to_i,
        ends_at.to_i,
        time_zone
      )
    end
  end
end
