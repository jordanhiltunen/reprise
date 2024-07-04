use magnus::{Error, prelude::*};

mod ruby_api;

#[magnus::init]
fn init() -> Result<(), Error> {
    ruby_api::init()?;
    Ok(())
}
