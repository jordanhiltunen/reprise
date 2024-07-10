use crate::ruby_api::exclusion::Exclusion;
use crate::ruby_api::interval::Interval;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::recurring_series::hourly::Hourly;
use crate::ruby_api::recurring_series::monthly_by_day::MonthlyByDay;
use crate::ruby_api::recurring_series::monthly_by_nth_weekday::MonthlyByNthWeekday;
use crate::ruby_api::recurring_series::weekly::Weekly;
use crate::ruby_api::ruby_modules;
use crate::ruby_api::sorted_exclusions::SortedExclusions;
use crate::ruby_api::traits::{Recurrable};
use chrono::DateTime;
use chrono_tz::Tz;
use magnus::prelude::*;
use magnus::{class, function, method};
use magnus::{scan_args, Error, Module, RHash, Symbol};
use parking_lot::RwLock;
use std::sync::Arc;
use crate::ruby_api::recurring_series::daily::Daily;
use crate::ruby_api::series_options::SeriesOptions;

pub(crate) type UnixTimestamp = i64;
type Second = i64;

#[derive(Debug, Clone)]
enum RecurringSeries {
    Hourly(Hourly),
    Daily(Daily),
    Weekly(Weekly),
    MonthlyByDay(MonthlyByDay),
    MonthlyByNthWeekday(MonthlyByNthWeekday),
}

#[derive(Debug)]
pub(crate) struct Schedule {
    pub(crate) starts_at_unix_timestamp: UnixTimestamp,
    pub(crate) local_starts_at_datetime: DateTime<Tz>,
    pub(crate) ends_at_unix_timestamp: UnixTimestamp,
    pub(crate) local_ends_at_datetime: DateTime<Tz>,
    pub(crate) time_zone: Tz,
    pub(crate) occurrences: Vec<Occurrence>,
    pub(crate) sorted_exclusions: SortedExclusions,
    // There may be magnus-related quirks that make it more difficult to idiomatically accrete
    // a collection of recurring series (e.g. something like Vec<dyn Recurrable> instead of
    // using an enum; that will require lifetimes, and magnus does not currently support lifetimes
    // on wrapped classes.
    // - > error: deriving TypedData is not guaranteed to be correct for types with lifetimes,
    //   > consider removing them, or use `#[magnus(unsafe_generics)]` to override this error.
    // - cf. https://stackoverflow.com/a/58487065
    pub(crate) recurring_series: Vec<RecurringSeries>,
}

#[derive(Debug)]
#[magnus::wrap(class = "Coruscate::Core::Schedule")]
struct MutSchedule(Arc<RwLock<Schedule>>);

impl MutSchedule {
    pub(crate) fn new(
        starts_at_unix_timestamp: UnixTimestamp,
        ends_at_unix_timestamp: UnixTimestamp,
        time_zone: String,
    ) -> MutSchedule {
        let parsed_time_zone: Tz = time_zone.parse().expect("Cannot parse time zone");
        let starts_at_utc = DateTime::from_timestamp(starts_at_unix_timestamp, 0).unwrap();
        let local_starts_at_datetime = starts_at_utc.with_timezone(&parsed_time_zone);
        let ends_at_utc = DateTime::from_timestamp(ends_at_unix_timestamp, 0).unwrap();
        let local_ends_at_datetime = ends_at_utc.with_timezone(&parsed_time_zone);

        Self(Arc::new(RwLock::new(Schedule {
            starts_at_unix_timestamp,
            local_starts_at_datetime,
            ends_at_unix_timestamp,
            local_ends_at_datetime,
            time_zone: parsed_time_zone,
            occurrences: Vec::new(),
            sorted_exclusions: SortedExclusions::new(),
            recurring_series: Vec::new(),
        })))
    }

    pub(crate) fn time_zone(&self) -> Tz {
        return self.0.read().time_zone;
    }

    pub(crate) fn add_exclusions(&self, exclusions: Vec<(i64, i64)>) {
        let mut converted_exclusions = exclusions
            .iter()
            .map(|e| Exclusion::new(e.0, e.1))
            .collect::<Vec<Exclusion>>();

        self.0
            .write()
            .sorted_exclusions
            .add_exclusions(&mut converted_exclusions);
    }

    pub(crate) fn add_exclusion(&self, kw: RHash) {
        let args: scan_args::KwArgs<(i64, i64), (), ()> = scan_args::get_kwargs(
            kw,
            &["starts_at_unix_timestamp", "ends_at_unix_timestamp"],
            &[],
        )
        .unwrap();
        let (starts_at_unix_timestamp, ends_at_unix_timestamp): (i64, i64) = args.required;

        self.0.write().sorted_exclusions.add_exclusion(Exclusion {
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
        });
    }

    pub(crate) fn repeat_hourly(&self, kw: RHash) {
        let series_options = SeriesOptions::new(self.time_zone().clone(), kw);
        let hourly_series = Hourly::new(series_options);
        self.0
            .write()
            .recurring_series
            .push(RecurringSeries::Hourly(hourly_series));
    }

    pub(crate) fn repeat_daily(&self, kw: RHash) {
        let series_options = SeriesOptions::new(self.time_zone().clone(), kw);
        let daily_series = Daily::new(series_options);
        self.0
            .write()
            .recurring_series
            .push(RecurringSeries::Daily(daily_series));
    }

    pub(crate) fn repeat_weekly(&self, weekday_symbol: Symbol, kw: RHash) {
        let series_options = SeriesOptions::new(self.time_zone().clone(), kw);
        let weekly_series = Weekly::new(weekday_symbol, series_options);
        self.0
            .write()
            .recurring_series
            .push(RecurringSeries::Weekly(weekly_series));
    }

    pub(crate) fn repeat_monthly_by_day(&self, day_number: u32, kw: RHash) {
        let series_options = SeriesOptions::new(self.time_zone().clone(), kw);
        let monthly_series = MonthlyByDay::new(day_number, series_options);
        self.0
            .write()
            .recurring_series
            .push(RecurringSeries::MonthlyByDay(monthly_series));
    }

    pub(crate) fn repeat_monthly_by_nth_weekday(
        &self,
        weekday_symbol: Symbol,
        nth_day: i32,
        kw: RHash
    ) {
        let series_options = SeriesOptions::new(self.time_zone().clone(), kw);
        let monthly_by_nth_weekday_series =
            MonthlyByNthWeekday::new(weekday_symbol, nth_day, series_options);
        self.0
            .write()
            .recurring_series
            .push(RecurringSeries::MonthlyByNthWeekday(
                monthly_by_nth_weekday_series,
            ));
    }

    pub(crate) fn occurrences(&self) -> Vec<Occurrence> {
        let self_reference = self.0.read();

        // Even though we are structurally equipped to use par_iter() here to parallelize,
        // and it is a simple substitution over iter(), schedule expansion is not computationally
        // demanding enough for it to really matter. Relative to IceCube, sequential processing is
        // ~500x faster, and parallel, only ~200x.
        return self_reference
            .recurring_series
            .iter()
            .map(|series| {
                // series.generate_occurrences(self_reference.local_starts_at_datetime, self_reference.local_ends_at_datetime)
                return match series {
                    RecurringSeries::Hourly(hourly) => hourly.generate_occurrences(
                        self_reference.local_starts_at_datetime,
                        self_reference.local_ends_at_datetime,
                    ),
                    RecurringSeries::Daily(daily) => daily.generate_occurrences(
                        self_reference.local_starts_at_datetime,
                        self_reference.local_ends_at_datetime,
                    ),
                    RecurringSeries::Weekly(weekly) => weekly.generate_occurrences(
                        self_reference.local_starts_at_datetime,
                        self_reference.local_ends_at_datetime,
                    ),
                    RecurringSeries::MonthlyByDay(monthly_by_day) => monthly_by_day
                        .generate_occurrences(
                            self_reference.local_starts_at_datetime,
                            self_reference.local_ends_at_datetime,
                        ),
                    RecurringSeries::MonthlyByNthWeekday(monthly_by_nth_weekday) => {
                        monthly_by_nth_weekday.generate_occurrences(
                            self_reference.local_starts_at_datetime,
                            self_reference.local_ends_at_datetime,
                        )
                    }
                };
            })
            .flatten()
            .filter(|o| !self_reference.sorted_exclusions.is_occurrence_excluded(o))
            .collect();
    }
}

pub fn init() -> Result<(), Error> {
    let class = ruby_modules::coruscate_core().define_class("Schedule", class::object())?;

    class.define_singleton_method("new", function!(MutSchedule::new, 3))?;
    class.define_method("occurrences", method!(MutSchedule::occurrences, 0))?;
    class.define_method("add_exclusion", method!(MutSchedule::add_exclusion, 1))?;
    class.define_method("add_exclusions", method!(MutSchedule::add_exclusions, 1))?;
    class.define_method("repeat_hourly", method!(MutSchedule::repeat_hourly, 1))?;
    class.define_method("repeat_daily", method!(MutSchedule::repeat_daily, 1))?;
    class.define_method("repeat_weekly", method!(MutSchedule::repeat_weekly, 2))?;
    class.define_method(
        "repeat_monthly_by_day",
        method!(MutSchedule::repeat_monthly_by_day, 2),
    )?;
    class.define_method(
        "repeat_monthly_by_nth_weekday",
        method!(MutSchedule::repeat_monthly_by_nth_weekday, 3),
    )?;

    Ok(())
}
