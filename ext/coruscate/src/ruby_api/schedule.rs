use std::cell::RefCell;
use magnus::prelude::*;
use magnus::{Error, Ruby, Module, RHash};
use magnus::class;
use magnus::function;
use magnus::method;
use chrono::{DateTime, Utc, Months, Timelike, TimeZone, NaiveDateTime, NaiveDate, NaiveTime, MappedLocalTime, Days};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::exclusion::Exclusion;
use crate::ruby_api::traits::HasOverlapAwareness;

// #[magnus::wrap(class = "Coruscate::Core::Schedule")]
pub(crate) struct Schedule {
    pub(crate) start_time: i64,
    pub(crate) end_time: i64,
    pub(crate) time_zone: Tz,
    pub(crate) occurrences: Vec<Occurrence>,
    pub(crate) exclusions: Vec<Exclusion>
}

#[magnus::wrap(class = "Coruscate::Core::Schedule")]
struct MutSchedule(RefCell<Schedule>);

impl MutSchedule {
    pub(crate) fn new(start_time: i64, end_time: i64, time_zone: String) -> MutSchedule {
        let parsed_time_zone: Tz = time_zone.parse().expect("Cannot parse time zone");

        Self(RefCell::new(
    Schedule {
            start_time,
            end_time,
            time_zone: parsed_time_zone,
            occurrences: Vec::new(),
            exclusions: Vec::new(),
        }))
    }

    // pub(crate) fn set_exclusions(self, exclusions: Vec<(i64,i64)>) -> bool {
    pub(crate) fn set_exclusions(&self, exclusions: Vec<(i64, i64)>) -> bool {
        let converted_exclusions = exclusions.iter().map(|e| Exclusion::new(e.0, e.1))
            .collect::<Vec<Exclusion>>().try_into().unwrap();
        self.0.borrow_mut().exclusions = converted_exclusions;

        dbg!(&self.0.borrow().exclusions);

        return true
    }

    pub(crate) fn add_exclusion(&self, start_time: i64, end_time: i64) -> bool {
        self.0.borrow_mut().exclusions.push(
            Exclusion { start_time, end_time }
        );

        dbg!("EXCLUSIONS");
        dbg!(&self.0.borrow().exclusions);

        return true
    }

    pub(crate) fn occurrences(&self) -> Vec<i64> {
        // TODO: only return occurrences that do not conflict with exclusions.
        // TODO: generate occurrences on the basis of weekly / daily / yearly / monthly recurrence rules

        let start_time_dt: DateTime<Utc> = DateTime::from_timestamp(self.0.borrow().start_time, 0).unwrap();
        dbg!(&start_time_dt);
        let local_time = start_time_dt.with_timezone(&self.0.borrow().time_zone);

        let start_time_hours = local_time.hour();
        let start_time_minutes = local_time.minute();
        let start_time_seconds = local_time.second();

        dbg!("Start time details");
        dbg!(start_time_hours, start_time_minutes);

        let mut time_vec: Vec<MappedLocalTime<DateTime<Tz>>> = Vec::new();

        for i in 0..12 {
            let intermediate_time = start_time_dt.checked_add_days(Days::new(i)).unwrap();
            let naive_time = NaiveTime::from_hms_opt(start_time_hours, start_time_minutes, start_time_seconds).unwrap();
            let naive_intermediate_datetime = NaiveDate::from(intermediate_time.naive_utc()).and_time(naive_time);
            let tz_aware_intermediate = self.0.borrow().time_zone.from_local_datetime(&naive_intermediate_datetime);

            let occurrence = Occurrence {
                start_time: tz_aware_intermediate.unwrap().timestamp(),
                end_time: tz_aware_intermediate.unwrap().timestamp() + 3600,
            };

            let mut is_valid = true;
            for exclusion in self.0.borrow().exclusions.iter() {
                dbg!("CHECKING EXCLUSION");
                dbg!(exclusion);

                let e1 = DateTime::from_timestamp(exclusion.start_time, 0).unwrap();
                let o1 = DateTime::from_timestamp(occurrence.start_time, 0).unwrap();

                dbg!(e1, "EXCLUSION");
                dbg!(o1, "OCCURRENCE");


                if exclusion.overlaps_with(&occurrence) {
                    dbg!("The occurrence is not valid");
                    is_valid = false;
                }
            }

            if is_valid {
                dbg!("The occurrence is valid");
                time_vec.push(tz_aware_intermediate);
            }
        }

        return time_vec.into_iter().map(|t| t.unwrap().timestamp()).collect();
    }
}

pub fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Coruscate")?;
    let core_module = module.define_module("Core")?;
    let class = core_module.define_class("Schedule", class::object())?;

    class.define_singleton_method("new", function!(MutSchedule::new, 3))?;
    class.define_method("occurrences", method!(MutSchedule::occurrences, 0))?;
    class.define_method("set_exclusions", method!(MutSchedule::set_exclusions, 1))?;
    class.define_method("add_exclusion", method!(MutSchedule::add_exclusion, 2))?;

    Ok(())
}
