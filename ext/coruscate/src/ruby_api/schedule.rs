use std::sync::{Arc};
use parking_lot::{Mutex};
use magnus::prelude::*;
use magnus::{Error, Module, RHash, scan_args};
use magnus::class;
use magnus::function;
use magnus::method;
use chrono::{DateTime};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::exclusion::Exclusion;
use crate::ruby_api::traits::{HasOverlapAwareness, RecurringSeries};
use crate::ruby_api::frequencies::hourly::Hourly;
use crate::ruby_api::frequencies::weekly::Weekly;
use crate::ruby_api::frequencies::monthly_by_day::MonthlyByDay;
use crate::ruby_api::sorted_exclusions::SortedExclusions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::ruby_modules;

type UnixTimestamp = i64;
type Second = i64;

#[derive(Debug)]
#[derive(Clone)]
enum Frequencies {
    Hourly(Hourly),
    Weekly(Weekly),
    MonthlyByDay(MonthlyByDay),
}

#[derive(Debug)]
pub(crate) struct Schedule {
    pub(crate) starts_at: UnixTimestamp,
    pub(crate) local_starts_at: DateTime<Tz>,
    pub(crate) ends_at: UnixTimestamp,
    pub(crate) local_ends_at: DateTime<Tz>,
    pub(crate) time_zone: Tz,
    pub(crate) occurrences: Vec<Occurrence>,
    pub(crate) sorted_exclusions: SortedExclusions,
    pub(crate) frequencies: Vec<Frequencies>
}

#[derive(Debug)]
#[magnus::wrap(class = "Coruscate::Core::Schedule")]
struct MutSchedule(Arc<Mutex<Schedule>>);

impl MutSchedule {
    pub(crate) fn new(starts_at: UnixTimestamp, ends_at: UnixTimestamp, time_zone: String) -> MutSchedule {
        let parsed_time_zone: Tz = time_zone.parse().expect("Cannot parse time zone");
        let starts_at_utc = DateTime::from_timestamp(starts_at, 0).unwrap();
        let local_starts_at = starts_at_utc.with_timezone(&parsed_time_zone);
        let ends_at_utc = DateTime::from_timestamp(ends_at, 0).unwrap();
        let local_ends_at = ends_at_utc.with_timezone(&parsed_time_zone);

        Self(Arc::new(Mutex::new(
            Schedule {
                starts_at,
                local_starts_at,
                ends_at,
                local_ends_at,
                time_zone: parsed_time_zone,
                occurrences: Vec::new(),
                sorted_exclusions: SortedExclusions::new(),
                frequencies: Vec::new()
            })))
    }

    pub(crate) fn add_exclusions(&self, exclusions: Vec<(i64, i64)>) {
        let mut converted_exclusions = exclusions.iter().map(|e| Exclusion::new(e.0, e.1))
            .collect::<Vec<Exclusion>>();

        self.0.lock().sorted_exclusions.add_exclusions(&mut converted_exclusions);
    }

    pub(crate) fn add_exclusion(&self, kw: RHash) {
        let args: scan_args::KwArgs<(i64, i64), (), ()> = scan_args::get_kwargs(
            kw, &["start_at_unix_timestamp", "end_at_unix_timestamp"], &[],
        ).unwrap();
        let (start_at_unix_timestamp, end_at_unix_timestamp): (i64, i64) = args.required;

        self.0.lock().sorted_exclusions.add_exclusion(Exclusion {
            start_time: start_at_unix_timestamp,
            end_time: end_at_unix_timestamp,
        });
    }

    pub(crate) fn repeat_hourly(&self, kw: RHash) {
        let args: scan_args::KwArgs<(RHash, i64), (), ()> = scan_args::get_kwargs(
            kw, &["initial_time_of_day", "duration_in_seconds"], &[],
        ).unwrap();
        let (initial_time_of_day, duration_in_seconds): (RHash, i64) = args.required;
        let starts_at_time_of_day = TimeOfDay::new_from_ruby_hash(initial_time_of_day);
        let hourly_series = Hourly::new(starts_at_time_of_day, duration_in_seconds);
        self.0.lock().frequencies.push(Frequencies::Hourly(hourly_series));
    }

    pub(crate) fn repeat_weekly(&self, weekday_string: String, starts_at_time_of_day_ruby_hash: RHash, duration_in_seconds: i64) {
        let starts_at_time_of_day = TimeOfDay::new_from_ruby_hash(starts_at_time_of_day_ruby_hash);
        let weekly_series = Weekly::new(weekday_string, starts_at_time_of_day, duration_in_seconds);
        self.0.lock().frequencies.push(Frequencies::Weekly(weekly_series));
    }

    pub(crate) fn repeat_monthly_by_day(&self, day_number: u32, starts_at_time_of_day_ruby_hash: RHash, duration_in_seconds: i64) {
        let starts_at_time_of_day = TimeOfDay::new_from_ruby_hash(starts_at_time_of_day_ruby_hash);
        let monthly_series = MonthlyByDay::new(day_number, starts_at_time_of_day, duration_in_seconds);
        self.0.lock().frequencies.push(Frequencies::MonthlyByDay(monthly_series));
    }

    pub(crate) fn occurrences(&self) -> Vec<Occurrence> {
        let self_reference = self.0.lock();

        return self_reference.frequencies.iter().
            map(|series| {
                return match series {
                    Frequencies::Hourly(hourly) => { hourly.generate_occurrences(self_reference.local_starts_at, self_reference.local_ends_at) }
                    Frequencies::Weekly(weekly) => { weekly.generate_occurrences(self_reference.local_starts_at, self_reference.local_ends_at) }
                    Frequencies::MonthlyByDay(monthly_by_day) => { monthly_by_day.generate_occurrences(self_reference.local_starts_at, self_reference.local_ends_at) }
                };
            }
            ).flatten()
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
    class.define_method("repeat_weekly", method!(MutSchedule::repeat_weekly, 3))?;
    class.define_method("repeat_monthly_by_day", method!(MutSchedule::repeat_monthly_by_day, 3))?;

    Ok(())
}
