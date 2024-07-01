use magnus::prelude::*;
use magnus::{Error, Ruby};

mod schedule;
mod occurrence;
mod exclusion;
mod traits;
mod recurrence_rules;
mod frequencies;
mod time_of_day;
mod sorted_exclusions;

pub fn init(ruby: &Ruby) -> Result<(), Error> {
    schedule::init(ruby)?;
    occurrence::init(ruby)?;
    Ok(())
}
