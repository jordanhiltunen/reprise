# Reprise

[![build](https://github.com/jordanhiltunen/reprise/actions/workflows/build.yml/badge.svg)](https://github.com/jordanhiltunen/reprise/actions/workflows/build.yml)

Reprise is an experimental performance-first Ruby gem that provides support for defining event recurrence
rules and generating & querying their future occurrences. Depending on your use case, 
you may benefit from a speedup of up to 1000x relative to other recurrence rule gems: because
Reprise is a thin Ruby wrapper around an extension written in Rust, we are able to offer a level
of speed and conservative memory use that we would otherwise be unable to accomplish in
pure Ruby alone.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "reprise"
```


## Design Goals

- Raw performance & memory efficiency.

## Design Non-Goals

- Offering multiple methods / calling conventions for each feature.
  We are calling into Rust functions, relying on a very strict
  typed language to do the heavy lifting for us. Libraries like 
  ice_cube and montrose offer remarkable flexibility in a Ruby idiom; 
  if those libraries make sense for your use case, you should probably
  use them.
- Supporting serialization to and from iCal. We are straying from that
  standard in meaningful ways. For example, we do not define exclusions by
  date, but by specific time ranges. This allows the library to handle 
  exclusion collision detection without client applications having to 
  implement that core scheduling concern on their own, outside of schedule
  expansion.

## Usage

### Initialize a new schedule

All schedules must be initialized with a start time, end time, and time zone.

```ruby
starts_at = Time.current.in_time_zone("Hawaii")
ends_at = Time.current + 4.weeks

schedule = Reprise::Schedule.new(starts_at:, ends_at:, time_zone: "Hawaii")

# 2. Define recurring series
schedule.repeat_weekly(:sunday, time_of_day: { hour: 9, minute: 30 }, duration_in_seconds: 60)
````

### Add recurring event series

```ruby
# When a time_of_day is required, you can pass an hour/minute/second hash:
schedule.repeat_weekly(:sunday, time_of_day: { hour: 9, minute: 30 }, duration_in_seconds: 60)

# Or, you can pass a `Time` value:
time = Time.new(2024, 6, 30, 0, 0, 0, "-10:00")
schedule.repeat_weekly(:sunday, time_of_day: time, duration_in_seconds: 60)

# You can repeat monthly by the nth day; e.g. the third Tuesday of every month:
schedule.repeat_monthly_by_nth_weekday(:tuesday, 2, { hour: 1, minute: 2, second: 3 }, 300)

# Or monthly by day; e.g. the 12th of every month:
schedule.repeat_monthly_by_day(12, { hour: 1, minute: 2, second: 3 }, 300)

# Or hourly: 
schedule.repeat_hourly(
        time_of_day: { hour: 1, minute: 2, second: 3 },
        duration_in_seconds: 300
)
```

## Development

### Compilation

- `rake compile:reprise`

After checking out the res
po, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Generating Documentation

Generate documentation within the `./docs` directory so that it can be
easily imported into GitHub pages. 
See: https://medium.com/make-school/a-cheatsheet-to-generate-documentation-for-your-rails-project-on-gh-pages-e28f6acfb9b9

```
bundle exec rake yard
```

- [ ] TODO: When we have a decent 0.0.1, publish the yarddocs
- on GitHub.

## Why Reprise?

### Consider the alternatives first

Reprise is particularly indebted to [ice_cube](https://github.com/ice-cube-ruby/ice_cube) and [Montrose](https://github.com/rossta/montrose), projects that have served the Ruby community for years.
They are stable and battle-tested. If you have no actual business need for the kind of performance that Reprise aims for,
you would probably be much better served by choosing one of those two gems instead.

### Tradeoffs

- **Flexibility.** Because Reprise calls into a strictly-typed extension, its current public interface is very much "one-size-fits-all";
  the influence of Rust leaks into its Ruby API. Alternative gems offer much more flexible APIs that support a variety
  of more idiomatic calling conventions: they have better, more forgiving ergonomics. Reprise may invest more efforts
  here in the future, but not until we have landed on a feature-complete, performant core - our primary design goal. 
  Until then, out API will remain sparse but sufficient.
- **Stability.** Reprise is still experimental; we have not yet released a `1.0.0` or have a public roadmap. Breaking changes
  may be frequent across releases. If you do not want to pin Reprise to a specific version and want a library that you can
  upgrade without reviewing the changelog, you may want to consider an alternative for now.
- **Serialization.** We do not yet offer any form of persistence support (e.g. parsing from / serializing to yaml / hash
  / ical / others). 

### Advantages

#### Benchmarks

- **Speed**. Reprise can generate events from a series of recurrence rules up to 1000x faster.
- **Memory**. Reprise uses up to 700x less memory during schedule expansion.

#### Exclusion Handling

Beyond performance, one area where Reprise shines is in schedule exclusion handling:

Suppose you have a recurring series that occurs every Monday from 12:30 PM - 1:00 PM. You need to generate
future occurrences of this series, excluding those that do not conflict with pre-existing, non-recurring
schedule entries; e.g. on one particular Monday, you have schedule entries at 9:00 AM - 9:30 AM, 12:15 PM - 1:00 PM, 
and 3:30 - 4:30 PM.

How do you filter out recurring series occurrences that conflict with other schedule entries that exist
in your application?

At time of writing, alternative gems' solutions to this problem are all unfortunately lacking:
- **None**: It is entirely the responsibility of the client application to handle occurrence exclusions,
  despite this logic being core to the domain of recurring schedule management.
- **Date-based exclusion**. Client applications can pass specific dates when occurrences should be excluded.
  This is not sufficient except for in the most simple of circumstances. Again, consider our hypothetical
  Monday @ 12:30 PM recurring series: being able to exclude a specific _date_ from your recurrence rule still 
  requires you to implement your own overlap detection logic to determine whether an occurrence actually conflicts with
  the start and end times of a schedule entry on a given date. 

These limitations can push a significant amount of schedule recurrence logic onto client applications;
Reprise improves on this significantly by offering an API to define exclusions with start and end times; Reprise
then determines whether any given occurrence overlaps with an exclusion that you have defined, and filters
them out during occurrence generation accordingly.

### When Performance Matters

A truism in the Ruby community is that "Ruby is slow, but that doesn't matter for you": 
> So, often it hardly matters that [Ruby] is slow, because your use-case does not need the scale, 
> speed, or throughput that Ruby chokes on. Or because the trade-offs are worth it: Often the 
> quicker development, cheaper development, faster time-to-market etc is worth the extra resources
> (servers, hardware, SAAS) you must throw at your app to keep it performing acceptable.
> https://berk.es/2022/08/09/ruby-slow-database-slow/

This is true until it isn't. Sometimes, Ruby's speed requires that a straightforward feature
be implemented in a contorted or unfortunately-constrained manner in order to work.  

Reprise aims to solve a niche problem: cutting the latency of recurring schedule generation when it is in
the critical path without imposing an additional complexity burden on clients. For most applications
that deal with recurring events, this is probably not a problem. But if it is, we want to buy you more
effectively-free per-request headroom that you can spend in simple Ruby to improve or ship a feature that
you otherwise couldn't.

## Acknowledgements [#related]

Reprise, a Ruby gem with a Rust core, is only possible because of the foundation laid by the excellent [Magnus](https://github.com/matsadler/magnus) project.

## Benchmarks

You can run benchmarks locally via `bundle exec rake benchmark`.

To view a list of past benchmarking results in CI, see [past runs of our Benchmark worfklow](https://github.com/jordanhiltunen/reprise/actions/workflows/benchmark.yml).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/reprise. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Reprise project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/reprise/blob/master/CODE_OF_CONDUCT.md).
