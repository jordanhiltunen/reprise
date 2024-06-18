use magnus::prelude::*;
use magnus::{Error, Ruby};

mod schedule;
mod occurrence;
mod exclusion;
mod traits;
mod recurrence_rules;

pub fn init(ruby: &Ruby) -> Result<(), Error> {
    schedule::init(ruby)?;
    Ok(())
}
