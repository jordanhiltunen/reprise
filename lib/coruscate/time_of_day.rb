# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"

module Coruscate
  class TimeOfDay
    class UnsupportedTypeError < Coruscate::Error; end
    class InvalidHashError < Coruscate::Error; end
    class RangeError < Coruscate::Error; end

    DEFAULT_TIME_OF_DAY = { hour: 0, minute: 0, second: 0 }.freeze
    TIME_OF_DAY_ATTRIBUTES = DEFAULT_TIME_OF_DAY.keys.freeze
    attr_accessor(*TIME_OF_DAY_ATTRIBUTES)

    # @param [Time, Hash] time_of_day
    #   Accepts either a local time value from which the hour, minute, and second
    #   should be derived, or a hash containing at least one of +hour+, +minute+,
    #   or +second+.
    # @option time_of_day [Integer] :hour, >= 0 && <= 23
    # @option time_of_day [Integer] :minute, >= 0 && <= 59
    # @option time_of_day [Integer] :second, >= 0 && <= 59
    # @example
    #   { hour: 1, minute: 30, second: 15 }
    # @raise [UnsupportedTypeError] if +time_of_day+ is neither a +Hash+ nor a +Time+.
    # @raise [InvalidHashError] if the hash representation of the time is invalid.
    # @raise [RangeError] if either the hour, minute, or second is out-of-range.
    def initialize(time_of_day)
      return initialize_from_hash(time_of_day) if time_of_day.is_a?(Hash)
      return initialize_from_time(time_of_day) if time_of_day.is_a?(Time)

      raise UnsupportedTypeError, "#{time_of_day.class} is not a supported type"
    end

    # @return [Hash]
    # @example
    #   { hour: 1, minute: 30, second: 15 }
    def to_h
      {
        hour:,
        minute:,
        second:
      }
    end

    private

    # @private
    def initialize_from_time(time)
      self.hour = time.hour
      self.minute = time.min
      self.second = time.sec
    end

    # @private
    def initialize_from_hash(hms_opts)
      raise InvalidHashError if (hms_opts.keys - TIME_OF_DAY_ATTRIBUTES).any?

      DEFAULT_TIME_OF_DAY.merge(hms_opts).slice(*TIME_OF_DAY_ATTRIBUTES).each do |key, value|
        public_send("#{key}=", value)
      end

      validate_time_of_day
    end

    def validate_time_of_day
      return if (hour >= 0 && hour <= 23) &&
        (minute >= 0 && minute <= 59) &&
        (second >= 0 && second <= 59)

      raise RangeError, "The time of day is out of range (#{to_h})"
    end
  end
end
