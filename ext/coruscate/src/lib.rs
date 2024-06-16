use magnus::{prelude::*, Error, Ruby};

mod ruby_api;

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    ruby_api::init(ruby)?;
    Ok(())
}
