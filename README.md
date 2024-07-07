# Coruscate

> /ˈkɒɹəskeɪt/
> (intransitive) To give off light; to reflect in flashes; to sparkle.

Coruscate is a shiny schedule expansion library that pursues speed first and foremost.
While battle-tested gems like IceCube and Montrose provide incredibly flexible APIs
to allow client applications to idiomatically construct recurring schedules with ease,
Coruscate offers a very sparse API, opting instead to pursue blazingly-fast schedule
expansion at the expense of ergonomics.

Coruscate provides schedule expansion using a Rust extension built with magnus.
Your use case probably will not benefit from the emphasis it places on raw performance,
you would probably benefit more from the mature and very comprehensive APIs offered
by IceCube and Montrose... but if you only need to support very rudimentary schedule
expansion logic and you need speed, this might be worthwhile

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/coruscate`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

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

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'coruscate'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install coruscate

## Usage

### Initialize a new schedule

All schedules must be initialized with a start time, end time, and time zone.

```ruby
starts_at = Time.current.in_time_zone("Hawaii")
ends_at = Time.current + 4.weeks

schedule = Coruscate::Schedule.new(starts_at:, ends_at:, time_zone: "Hawaii")

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
        initial_time_of_day: { hour: 1, minute: 2, second: 3 },
        duration_in_seconds: 300
)
```

## Development

### Compilation

- `rake compile:coruscate`

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

## Benchmarks

You can run benchmarks locally via `bundle exec rake benchmark`.

To view a list of past benchmarking results in CI, see [past runs of our Benchmark worfklow](https://github.com/jordanhiltunen/coruscate/actions/workflows/benchmark.yml).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/coruscate. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Coruscate project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/coruscate/blob/master/CODE_OF_CONDUCT.md).
