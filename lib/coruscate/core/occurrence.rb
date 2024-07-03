# frozen_string_literal: true

module Coruscate
  module Core
    # This class definition is open-classed only for the purposes
    # of adding documentation; it is defined dynamically within
    # the Rust extension.
    class Occurrence
      # @!attribute [r] start_time
      #   @return [Time] The start time of the occurrence.
      # @!attribute [r] end_time
      #   @return [Time] The end time of the occurrence.
    end
  end
end
