use crate::ruby_api::exclusion::Exclusion;
use crate::ruby_api::interval::Interval;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::recurring_series::daily::Daily;
use crate::ruby_api::recurring_series::hourly::Hourly;
use crate::ruby_api::recurring_series::minutely::Minutely;
use crate::ruby_api::recurring_series::monthly_by_day::MonthlyByDay;
use crate::ruby_api::recurring_series::monthly_by_nth_weekday::MonthlyByNthWeekday;
use crate::ruby_api::recurring_series::weekly::Weekly;
use crate::ruby_api::ruby_modules;
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::sorted_exclusions::SortedExclusions;
use crate::ruby_api::traits::{HasOverlapAwareness, Recurrable, RecurringSeries};
use chrono::{DateTime, TimeDelta};
use chrono_tz::Tz;
use magnus::prelude::*;
use magnus::{class, function, method};
use magnus::{scan_args, Error, Module, RHash, Symbol};
use parking_lot::RwLock;
use rayon::prelude::ParallelSliceMut;
use std::sync::Arc;

pub(crate) type UnixTimestamp = i64;
type Second = i64;

#[derive(Debug)]
pub(crate) struct Schedule {
    pub(crate) starts_at_unix_timestamp: UnixTimestamp,
    pub(crate) local_starts_at_datetime: DateTime<Tz>,
    pub(crate) ends_at_unix_timestamp: UnixTimestamp,
    pub(crate) local_ends_at_datetime: DateTime<Tz>,
    pub(crate) time_zone: Tz,
    pub(crate) occurrences: Vec<Occurrence>,
    pub(crate) sorted_exclusions: SortedExclusions,
    pub(crate) recurring_series: Vec<RecurringSeries>,
}

#[derive(Debug)]
#[magnus::wrap(class = "Reprise::Core::Schedule")]
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

    fn longest_occurrence_duration_in_seconds(&self) -> Option<i64> {
        return self
            .0
            .read()
            .recurring_series
            .iter()
            .map(|s| s.get_occurrence_duration_in_seconds())
            .max();
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

    pub(crate) fn repeat_minutely(&self, kw: RHash) {
        let series_options = SeriesOptions::new(self.time_zone().clone(), kw);
        let minutely_series = Minutely::new(series_options);
        self.0
            .write()
            .recurring_series
            .push(RecurringSeries::Minutely(minutely_series));
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
        kw: RHash,
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

    pub fn occurrences_contained_within_interval(
        &self,
        starts_at_unix_timestamp: i64,
        ends_at_unix_timestamp: i64,
    ) -> Vec<Occurrence> {
        let interval = Interval::new(
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
            self.time_zone(),
        );

        return self
            .generate_occurrences(Some(interval.starts_at()), Some(interval.ends_at()))
            .into_iter()
            .filter(|o| interval.contains(o))
            .collect();
    }

    pub fn occurrences_overlapping_with_interval(
        &self,
        starts_at_unix_timestamp: i64,
        ends_at_unix_timestamp: i64,
    ) -> Vec<Occurrence> {
        let interval = Interval::new(
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
            self.time_zone(),
        );

        // By constraining the examined window of occurrences to the requested interval,
        // +/- the duration of the longest registered event, we can conservatively expand
        // the schedule and iterate over only the occurrences that could conceivably overlap.
        let longest_occurrence_duration_in_seconds =
            self.longest_occurrence_duration_in_seconds().unwrap_or(0);
        let examined_window_starts_at =
            Some(interval.starts_at() - TimeDelta::seconds(longest_occurrence_duration_in_seconds));
        let examined_window_ends_at =
            Some(interval.ends_at() + TimeDelta::seconds(longest_occurrence_duration_in_seconds));

        return self
            .generate_occurrences(examined_window_starts_at, examined_window_ends_at)
            .into_iter()
            .filter(|o| interval.overlaps_with(o))
            .collect();
    }

    pub fn occurrences(&self) -> Vec<Occurrence> {
        return self.generate_occurrences(None, None);
    }

    fn generate_occurrences(
        &self,
        starts_at: Option<DateTime<Tz>>,
        ends_at: Option<DateTime<Tz>>,
    ) -> Vec<Occurrence> {
        let self_reference = self.0.read();
        let starts_at = starts_at.unwrap_or(self_reference.local_starts_at_datetime);
        let ends_at = ends_at.unwrap_or(self_reference.local_ends_at_datetime);

        let mut occurrences = self_reference
            .recurring_series
            .iter()
            .flat_map(|series| series.generate_occurrences(starts_at, ends_at))
            .filter(|o| !self_reference.sorted_exclusions.is_occurrence_excluded(o))
            .collect::<Vec<Occurrence>>();

        occurrences.par_sort_unstable_by(|a, b| {
            a.starts_at_unix_timestamp.cmp(&b.starts_at_unix_timestamp)
        });

        return occurrences;
    }
}

pub fn init() -> Result<(), Error> {
    let class = ruby_modules::reprise_core().define_class("Schedule", class::object())?;

    class.define_singleton_method("new", function!(MutSchedule::new, 3))?;
    class.define_method("occurrences", method!(MutSchedule::occurrences, 0))?;
    class.define_method(
        "occurrences_contained_within_interval",
        method!(MutSchedule::occurrences_contained_within_interval, 2),
    )?;
    class.define_method(
        "occurrences_overlapping_with_interval",
        method!(MutSchedule::occurrences_overlapping_with_interval, 2),
    )?;
    class.define_method("add_exclusion", method!(MutSchedule::add_exclusion, 1))?;
    class.define_method("add_exclusions", method!(MutSchedule::add_exclusions, 1))?;
    class.define_method("repeat_minutely", method!(MutSchedule::repeat_minutely, 1))?;
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
