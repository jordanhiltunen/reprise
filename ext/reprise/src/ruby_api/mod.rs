use magnus::prelude::*;
use magnus::{Error};

pub mod clock;
mod exclusion;
pub mod interval;
mod occurrence;
mod recurring_series;
mod ruby_modules;
mod schedule;
mod series_options;
mod sorted_exclusions;
mod time_of_day;
mod traits;

pub fn init() -> Result<(), Error> {
    schedule::init()?;
    occurrence::init()?;
    Ok(())
}
