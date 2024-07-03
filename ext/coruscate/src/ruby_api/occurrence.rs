use magnus::{class, Error, method, Module, Ruby, Time};
use crate::ruby_api::traits::HasOverlapAwareness;
use crate::ruby_api::ruby_modules;

#[derive(Debug, Copy, Clone)]
#[magnus::wrap(class = "Coruscate::Core::Occurrence")]
pub(crate) struct Occurrence {
    pub(crate) start_time: i64,
    pub(crate) end_time: i64
}

// this is safe as Occurrence does not contain any Ruby types
unsafe impl magnus::IntoValueFromNative for Occurrence {}

impl Occurrence {
    pub(crate) fn new(start_time: i64, end_time: i64) -> Occurrence {
        return Occurrence { start_time, end_time }
    }

    pub fn start_time(&self) -> Time {
        return Occurrence::ruby_handle().time_new(self.start_time, 0).unwrap();
    }

    pub fn end_time(&self) -> Time {
        return Occurrence::ruby_handle().time_new(self.end_time, 0).unwrap();
    }

    fn ruby_handle() -> Ruby {
        Ruby::get().unwrap()
    }
}

impl HasOverlapAwareness for Occurrence {
    fn get_start_time(&self) -> i64 {
        return self.start_time;
    }

    fn get_end_time(&self) -> i64 {
        return self.end_time;
    }
}

pub fn init() -> Result<(), Error> {
    let occurrence_class = ruby_modules::coruscate_core().define_class("Occurrence", class::object())?;
    occurrence_class.define_method("start_time", method!(Occurrence::start_time, 0))?;
    occurrence_class.define_method("end_time", method!(Occurrence::end_time, 0))?;

    Ok(())
}
