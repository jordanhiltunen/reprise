use magnus::{class, Error, method, Module, Ruby, Time};
use crate::ruby_api::traits::HasOverlapAwareness;
use crate::ruby_api::ruby_modules;

#[derive(Debug, Copy, Clone)]
#[magnus::wrap(class = "Coruscate::Core::Occurrence")]
pub(crate) struct Occurrence {
    pub(crate) starts_at_unix_timestamp: i64,
    pub(crate) ends_at_unix_timestamp: i64
}

// this is safe as Occurrence does not contain any Ruby types
unsafe impl magnus::IntoValueFromNative for Occurrence {}

impl Occurrence {
    pub(crate) fn new(starts_at_unix_timestamp: i64, ends_at_unix_timestamp: i64) -> Occurrence {
        return Occurrence { starts_at_unix_timestamp, ends_at_unix_timestamp }
    }

    pub fn start_time(&self) -> Time {
        return Occurrence::ruby_handle().time_new(self.starts_at_unix_timestamp, 0).unwrap();
    }

    pub fn end_time(&self) -> Time {
        return Occurrence::ruby_handle().time_new(self.ends_at_unix_timestamp, 0).unwrap();
    }

    fn ruby_handle() -> Ruby {
        Ruby::get().unwrap()
    }
}

impl HasOverlapAwareness for Occurrence {
    fn get_starts_at_unix_timestamp(&self) -> i64 {
        return self.starts_at_unix_timestamp;
    }

    fn get_ends_at_unix_timestamp(&self) -> i64 {
        return self.ends_at_unix_timestamp;
    }
}

pub fn init() -> Result<(), Error> {
    let occurrence_class = ruby_modules::coruscate_core().define_class("Occurrence", class::object())?;
    occurrence_class.define_method("start_time", method!(Occurrence::start_time, 0))?;
    occurrence_class.define_method("end_time", method!(Occurrence::end_time, 0))?;

    Ok(())
}
