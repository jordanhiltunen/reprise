use magnus::prelude::*;
use magnus::{Error, RModule, Ruby, value::Lazy};

mod schedule;
mod occurrence;
mod exclusion;
mod traits;
mod recurrence_rules;
mod frequencies;
mod time_of_day;
mod ruby_modules;
mod sorted_exclusions;

pub fn init(ruby: &Ruby) -> Result<(), Error> {
    schedule::init()?;
    occurrence::init()?;
    Ok(())
}
