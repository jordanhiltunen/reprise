# frozen_string_literal: true

begin
  require "reprise/#{RUBY_VERSION.to_f}/reprise"
rescue LoadError
  require "reprise/reprise"
end

require "active_support"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/time"
require "reprise/schedule"
require "reprise/time_of_day"
require "reprise/time_zone_identifier"
require "reprise/version"
