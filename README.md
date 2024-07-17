# Reprise

[![build](https://github.com/jordanhiltunen/reprise/actions/workflows/build.yml/badge.svg)](https://github.com/jordanhiltunen/reprise/actions/workflows/build.yml)

Reprise is an experimental performance-first Ruby gem that provides support for defining event recurrence
rules and generating & querying their future occurrences. Depending on your use case, 
you may benefit from a speedup of up to 1000x relative to other recurrence rule gems: because
Reprise is a thin Ruby wrapper around an extension written in Rust, we are able to offer a level
of speed and conservative memory use that we would otherwise be unable to accomplish in
pure Ruby alone.

For more on why and when you might want to use this gem, see [Why Reprise?](#why-reprise).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "reprise"
```

## Usage

### Initialize a new schedule

All schedules must be initialized with a `start_time`, `end_time`, and `time_zone`:

```ruby
schedule = Reprise::Schedule.new(
  starts_at: Time.current, 
  ends_at: Time.current + 4.weeks, 
  time_zone: "Hawaii"
)
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

### Generate Schedule Occurrences

```ruby
# Add however many series you like, then generate your schedule's occurrences:
occurrences = schedule.occurrences

occurrences.take(3).map { |o| puts o.inspect }
# <Reprise::Core::Occurrence start_time="2024-07-22T07:03:04+00:00" end_time="2024-07-22T07:48:04+00:00" label="Brunch">
# <Reprise::Core::Occurrence start_time="2024-07-29T07:03:04+00:00" end_time="2024-07-29T07:48:04+00:00" label="Brunch">
# <Reprise::Core::Occurrence start_time="2024-08-05T07:03:04+00:00" end_time="2024-08-05T07:48:04+00:00" label="Brunch">
```

## Why Reprise?

### First, consider the alternatives

Reprise is particularly indebted to [ice_cube](https://github.com/ice-cube-ruby/ice_cube) and [Montrose](https://github.com/rossta/montrose), projects that have served the Ruby community for years.
They are stable and battle-tested. If you have no actual business need for the kind of performance that Reprise aims for,
you would probably be much better served by choosing one of those two gems instead.

### Tradeoffs

- **Flexibility.** Because Reprise calls into a strictly-typed extension, its current public interface is very much "one-size-fits-all";
  the influence of Rust leaks into its Ruby API. Alternative gems offer much more flexible APIs that support a variety
  of more idiomatic calling conventions: they have better, more forgiving ergonomics. Reprise may invest more efforts
  here in the future, but not until we have landed on a feature-complete, performant core - our primary design goal. 
  Until then, out API will remain sparse but sufficient.
- **Stability.** Reprise is still experimental; we do not yet have a `1.0.0` release or a public roadmap. Breaking changes
  may be frequent across releases. If you do not want to pin Reprise to a specific version and want a library that you can
  upgrade without reviewing the changelog, you may want to consider an alternative for now.
- **Serialization.** We do not yet offer any form of persistence support (e.g. parsing from / serializing to yaml / hash
  / ical / others). 

### Advantages

#### Performance

A truism in the Ruby community is that "Ruby is slow, but that doesn't matter for you":
> So, often it hardly matters that [Ruby] is slow, because your use-case does not need the scale,
> speed, or throughput that Ruby chokes on. Or because the trade-offs are worth it: Often the
> quicker development, cheaper development, faster time-to-market etc is worth the extra resources
> (servers, hardware, SAAS) you must throw at your app to keep it performing acceptable.
> https://berk.es/2022/08/09/ruby-slow-database-slow/

This is often delightfully true, until on the odd occasion Ruby's speed requires that a straightforward feature
be implemented in a contorted or meaningfully-constrained way in order to work.

Reprise aims to solve a niche problem: cutting the latency of recurring schedule generation when it is in
the critical path without imposing an additional complexity burden on clients. For most applications
that deal with recurring events, this is probably not a problem. But if it is, we want to buy you more
effectively-free per-request headroom that you can spend in simple Ruby to improve or ship a feature that
you otherwise couldn't.

##### Benchmarks

You can run benchmarks locally via `bundle exec rake benchmark`; additionally, 
to view our recent benchmarking results in CI, see [past runs of our Benchmark worfklow](https://github.com/jordanhiltunen/reprise/actions/workflows/benchmark.yml).

Below is a sample local benchmark run taken on the following development machine:

| System Detail | Value                                                      |
|---------------|------------------------------------------------------------|
| OS            | macOS 14.5 (23F79)                                         |
| CPU           | 2.4 GHz 8-Core Intel i9                                    |
| Memory        | 64GB 2667 MHz DDRr                                         |
| Ruby Version  | 3.3.2 (2024-05-30 revision e5a195edf6) \[x86_64-darwin23\] |
| Rust Version  | rustc 1.79.0 (129f3b996 2024-06-10)                        |

`benchmark-ips`: (higher is better)
```
ruby 3.3.2 (2024-05-30 revision e5a195edf6) [x86_64-darwin23]
Warming up --------------------------------------
             IceCube     1.000 i/100ms
            Montrose     1.000 i/100ms
             Reprise     1.197k i/100ms
Calculating -------------------------------------
             IceCube     10.259 (± 9.7%) i/s -     52.000 in   5.081337s
            Montrose     14.986 (± 6.7%) i/s -     75.000 in   5.022293s
             Reprise     13.127k (±19.9%) i/s -     63.441k in   5.047277s
```

`benchmark-memory`: (lower is better)
```
Calculating -------------------------------------
             IceCube    10.986M memsize (     1.040k retained)
                       202.268k objects (    14.000  retained)
                         5.000  strings (     1.000  retained)
            Montrose     9.799M memsize (     3.792k retained)
                       157.675k objects (    13.000  retained)
                        34.000  strings (     7.000  retained)
             Reprise    14.872k memsize (     0.000  retained)
                       310.000  objects (     0.000  retained)
                         0.000  strings (     0.000  retained)

Comparison:
             Reprise:      14872 allocated
            Montrose:    9799288 allocated - 658.91x more
             IceCube:   10986192 allocated - 738.72x more
```

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

## Acknowledgements

Reprise, a Ruby gem with a Rust core, is only possible because of the foundation laid by the excellent [Magnus](https://github.com/matsadler/magnus) project.

## Development

To get started after checking out the repo:

```bash
$ bin/setup # install dependencies
$ rake compile:reprise # recompile the extension after making changes to Rust files
$ rake spec # run the test suite
$ rake benchmark # run the benchmarks
```

### Generating Documentation

Reprise' public Ruby API is documented using [YARD](https://yardoc.org/guides/).
To regenerate the documentation after changing any of the annotations, run `rake yard`
and commit the changes.

## Contributing

This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

- :white_check_mark: Report or fix bugs
- :white_check_mark: Suggest features
- :white_check_mark: Write or improve documentation
- :yellow_circle: Submit pull requests (please reach out first)

We plan on welcoming pull requests once we settle on an initial `1.0.0`; until then, we anticipate
a lot of early experimentation, and we will have more time to collaborate and welcome pull requests
once we've hit that milestone.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Reprise project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/reprise/blob/master/CODE_OF_CONDUCT.md).
