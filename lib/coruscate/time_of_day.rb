# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"

module Coruscate
  class TimeOfDay
    class MissingArgumentError < Coruscate::Error; end
    class InvalidHashError < Coruscate::Error; end
    class RangeError < Coruscate::Error; end

    DEFAULT_TIME_OF_DAY = { hour: 0, minute: 0, second: 0 }.freeze
    TIME_OF_DAY_ATTRIBUTES = %i[hour minute second]
    attr_accessor *TIME_OF_DAY_ATTRIBUTES

    # @private
    # @param time [Time, nil] a local time value from which the hour, minute, and second
    #   should be derived.
    #
    # @param [Hash] hms_opts The hour, minute, and second of the time of day.
    # @option hms_opts [Integer] :hour, >= 0 && <= 23
    # @option hms_opts [Integer] :minute, >= 0 && <= 59
    # @option hms_opts [Integer] :second, >= 0 && <= 59
    # @example
    #   { hour: 1, minute: 30, second: 15 }
    # @raise [MissingArgumentError] if neither <code>time</code> nor an <code>hms_opts</code> hash is present.
    # @raise [InvalidHashError] if the hash representation of the time is invalid.
    # @raise [RangeError] if either the hour, minute, or second is out-of-range.
    def initialize(time: nil, hms_opts: {})
      raise MissingArgumentError if time.blank? && hms_opts&.empty?
      raise InvalidHashError if (hms_opts.keys - TIME_OF_DAY_ATTRIBUTES).any?
      time.present? ? initialize_from_time(time) : initialize_from_hash(hms_opts)

      validate_time_of_day
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
    def initialize_from_hash(hash)
      DEFAULT_TIME_OF_DAY.merge(hash).slice(*TIME_OF_DAY_ATTRIBUTES).each do |key, value|
        public_send("#{key}=", value)
      end
    end

    def validate_time_of_day
      return if (hour >= 0 && hour <= 23) &&
        (minute >= 0 && minute <= 59) &&
        (second >= 0 && second <= 59)

      raise RangeError, "The time of day is out of range (#{to_h})"
    end
  end
end
