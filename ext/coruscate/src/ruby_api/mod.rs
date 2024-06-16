use magnus::prelude::*;
use magnus::{Error, Ruby};

mod schedule;

pub fn init(ruby: &Ruby) -> Result<(), Error> {
    schedule::init(ruby)?;
    Ok(())
}
