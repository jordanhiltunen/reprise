use magnus::prelude::*;
use magnus::{Error, RArray, Ruby, Module};
use magnus::class;
use magnus::function;
use magnus::method;
use std::time::{Duration, SystemTime};

#[magnus::wrap(class = "Coruscate::Schedule")]
pub(crate) struct Schedule {
    pub(crate) start_time: SystemTime,
    pub(crate) end_time: SystemTime,
    pub(crate) occurrences: Option<Vec<SystemTime>>
}

impl Schedule {
    pub(crate) fn new(start_time: SystemTime, end_time: SystemTime) -> Schedule {
        Schedule {
            start_time,
            end_time,
            occurrences: None
        }
    }

    pub(crate) fn occurrences(&self) -> RArray {
        let ruby = Ruby::get().unwrap();
        let r_arr = RArray::new();

        r_arr.push(ruby.time_new(1654018280, 0).unwrap()).unwrap();
        r_arr.push(ruby.time_new(1654018280, 0).unwrap()).unwrap();
        r_arr.push(ruby.time_new(1654018280, 0).unwrap()).unwrap();

        return r_arr;
    }
}


pub fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Coruscate")?;
    let class = module.define_class("Schedule", class::object())?;

    class.define_singleton_method("new", function!(Schedule::new, 2))?;
    class.define_method("occurrences", method!(Schedule::occurrences, 0))?;

    Ok(())
}
