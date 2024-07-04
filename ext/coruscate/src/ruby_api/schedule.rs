use std::cell::RefCell;
use magnus::prelude::*;
use magnus::{Error, Ruby, Module, RHash};
use magnus::class;
use magnus::function;
use magnus::method;
use chrono::{DateTime};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::exclusion::Exclusion;
use crate::ruby_api::traits::{HasOverlapAwareness, RecurringSeries};
use crate::ruby_api::frequencies::weekly::Weekly;
use crate::ruby_api::sorted_exclusions::SortedExclusions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::ruby_modules;

type UnixTimestamp = i64;
type Second = i64;

#[derive(Debug)]
pub(crate) struct Schedule<'a> {
    pub(crate) starts_at: UnixTimestamp,
    pub(crate) local_starts_at: DateTime<Tz>,
    pub(crate) ends_at: UnixTimestamp,
    pub(crate) local_ends_at: DateTime<Tz>,
    pub(crate) time_zone: Tz,
    pub(crate) occurrences: Vec<Occurrence>,
    pub(crate) sorted_exclusions: SortedExclusions,
    pub(crate) frequencies: Vec<Box<dyn RecurringSeries + 'a>>
}

// Necessary due to <Vec<Box<dyn RecurringSeries>>
unsafe impl Send for Schedule<'_> {}

#[magnus::wrap(class = "Coruscate::Core::Schedule")]
// A note on using lifetimes for an object like this that we hope to return
// to Ruby: the compiler complains with the following warnings:
// > error: deriving TypedData is not guaranteed to be correct for types with lifetimes,
// consider removing them, or use `#[magnus(unsafe_generics)]` to override this error.
struct MutSchedule<'a>(RefCell<Schedule<'a>>);

impl MutSchedule<'a> {
    pub(crate) fn new<'a>(starts_at: UnixTimestamp, ends_at: UnixTimestamp, time_zone: String) -> MutSchedule<'a> {
        let parsed_time_zone: Tz = time_zone.parse().expect("Cannot parse time zone");
        let starts_at_utc = DateTime::from_timestamp(starts_at, 0).unwrap();
        let local_starts_at = starts_at_utc.with_timezone(&parsed_time_zone);
        let ends_at_utc = DateTime::from_timestamp(ends_at, 0).unwrap();
        let local_ends_at = ends_at_utc.with_timezone(&parsed_time_zone);

        Self(RefCell::new(
            Schedule {
                starts_at,
                local_starts_at,
                ends_at,
                local_ends_at,
                time_zone: parsed_time_zone,
                occurrences: Vec::new(),
                sorted_exclusions: SortedExclusions::new(),
                frequencies: Vec::new()
            }))
    }


    pub(crate) fn add_exclusions(&self, exclusions: Vec<(i64, i64)>) -> bool {
        let mut converted_exclusions = exclusions.iter().map(|e| Exclusion::new(e.0, e.1))
            .collect::<Vec<Exclusion>>();

        self.0.borrow_mut().sorted_exclusions.add_exclusions(&mut converted_exclusions);

        return true;
    }

    pub(crate) fn add_exclusion(&self, start_time: i64, end_time: i64) -> bool {
        self.0.borrow_mut().sorted_exclusions.add_exclusion(Exclusion {
            start_time, end_time
        });

        return true;
    }

    pub(crate) fn repeat_weekly(&self, weekday_string: String, starts_at_time_of_day_ruby_hash: RHash, duration_in_seconds: i64) -> bool {
        let starts_at_time_of_day = TimeOfDay::new_from_ruby_hash(starts_at_time_of_day_ruby_hash);
        let mut new_occurrences: Vec<Occurrence> = Vec::new();

        {
            // let schedule_reference = self.0.borrow();
            let weekly_series = Weekly::new(&self.0, weekday_string, starts_at_time_of_day, duration_in_seconds);
            new_occurrences = weekly_series.generate_occurrences();

            self.0.borrow_mut().frequencies.push(Box::new(weekly_series));
        }

        self.0.borrow_mut().occurrences.extend(new_occurrences);

        return true;
    }

    pub(crate) fn get_occurrences(&self) -> Vec<Occurrence> {
        return self.0.borrow().occurrences.clone().into_iter()
            .filter(|o| !self.0.borrow().sorted_exclusions.is_occurrence_excluded(o))
            .collect();
    }
}

pub fn init() -> Result<(), Error> {
    let class = ruby_modules::coruscate_core().define_class("Schedule", class::object())?;

    class.define_singleton_method("new", function!(MutSchedule::new, 3))?;
    class.define_method("occurrences", method!(MutSchedule::get_occurrences, 0))?;
    class.define_method("add_exclusion", method!(MutSchedule::add_exclusion, 2))?;
    class.define_method("add_exclusions", method!(MutSchedule::add_exclusions, 1))?;
    class.define_method("repeat_weekly", method!(MutSchedule::repeat_weekly, 3))?;

    Ok(())
}
