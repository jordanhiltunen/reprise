use std::os::raw::c_int;
use magnus::prelude::*;
use magnus::{Error, RArray, Ruby, Module, Value};
use magnus::class;
use magnus::function;
use magnus::method;
use std::time::{Duration, SystemTime};
use chrono::{DateTime, Utc, Months, Timelike, TimeZone, NaiveDateTime, NaiveDate, NaiveTime, MappedLocalTime};
use chrono_tz::Tz;
use magnus::rb_sys::protect;

use rb_sys::{rb_time_timespec, rb_time_timespec_new, rb_time_timeval, rb_time_utc_offset, RTypedData, timespec, timeval};

#[magnus::wrap(class = "Coruscate::Schedule")]
pub(crate) struct Schedule {
    pub(crate) start_time: SystemTime,
    pub(crate) end_time: SystemTime,
    pub(crate) time_zone: chrono_tz::Tz,
    pub(crate) occurrences: Option<Vec<SystemTime>>
}

impl Schedule {
    pub(crate) fn new(start_time: SystemTime, end_time: SystemTime, time_zone: String) -> Schedule {
        let parsed_time_zone: chrono_tz::Tz = time_zone.parse().expect("Cannot parse time zone");

        Schedule {
            start_time,
            end_time,
            time_zone: parsed_time_zone,
            occurrences: None
        }
    }

    pub(crate) fn occurrences(&self) -> RArray {
        let ruby = Ruby::get().unwrap();
        let r_arr = RArray::new();

        let start_time_dt: DateTime<Utc> = self.start_time.clone().into();
        dbg!(&start_time_dt);
        let local_time = start_time_dt.with_timezone(&self.time_zone);

        let start_time_hours = local_time.hour();
        let start_time_minutes = local_time.minute();
        let start_time_seconds = local_time.second();

        let mut time_vec: Vec<MappedLocalTime<DateTime<Tz>>> = Vec::new();

        for i in 0..20 {
            let intermediate_time = start_time_dt.checked_add_months(Months::new(i)).unwrap();
            let naive_time = NaiveTime::from_hms_opt(start_time_hours, start_time_minutes, start_time_seconds).unwrap();
            let naive_intermediate_datetime = NaiveDate::from(intermediate_time.naive_utc()).and_time(naive_time);
            let tz_aware_intermediate = self.time_zone.from_local_datetime(&naive_intermediate_datetime);

            time_vec.push(tz_aware_intermediate);
        }

        // now convert back to ruby times
        for date_time in time_vec.iter() {
            // let ts = timespec {
            //     tv_sec: date_time.unwrap().timestamp() / 1000,
            //     tv_nsec: date_time.unwrap().timestamp_nanos_opt().unwrap(),
            // };
            // let tz = 400 as c_int;// date_time.unwrap().fixed_offset().offset().local_minus_utc() as c_int;
            //
            // dbg!(tz);
            //
            // let val = protect(|| unsafe { rb_time_timespec_new(&ts as *const _, tz) }).unwrap();
            // // Ok(Self(unsafe { NonZeroValue::new_unchecked(val) }))

            r_arr.push( //val
                ruby.time_new(date_time.unwrap().timestamp(), 0).unwrap()




            ).expect("TODO: panic message");
        }

        return r_arr;
    }
}

pub fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Coruscate")?;
    let class = module.define_class("Schedule", class::object())?;

    class.define_singleton_method("new", function!(Schedule::new, 3))?;
    class.define_method("occurrences", method!(Schedule::occurrences, 0))?;

    Ok(())
}
