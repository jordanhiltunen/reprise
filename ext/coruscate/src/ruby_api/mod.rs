use magnus::prelude::*;
use magnus::{Error, RModule, Ruby, value::Lazy};

mod schedule;
mod occurrence;
mod exclusion;
mod traits;
mod recurring_series;
mod series_options;
mod time_of_day;
mod ruby_modules;
mod sorted_exclusions;
pub mod interval;

pub fn init() -> Result<(), Error> {
    schedule::init()?;
    occurrence::init()?;
    Ok(())
}
