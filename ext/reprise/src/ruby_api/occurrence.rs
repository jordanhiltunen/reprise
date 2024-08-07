use crate::ruby_api::ruby_modules;
use crate::ruby_api::traits::HasOverlapAwareness;
use magnus::{class, method, Error, Module, Ruby, Time};
use chrono::{DateTime, Utc};

#[derive(Debug)]
#[magnus::wrap(class = "Reprise::Core::Occurrence")]
pub(crate) struct Occurrence {
    pub(crate) starts_at_unix_timestamp: i64,
    pub(crate) ends_at_unix_timestamp: i64,
    pub(crate) label: Option<String>,
}

// this is safe as Occurrence does not contain any Ruby types
unsafe impl magnus::IntoValueFromNative for Occurrence {}

impl Occurrence {
    pub(crate) fn new(
        starts_at_unix_timestamp: i64,
        ends_at_unix_timestamp: i64,
        label: Option<String>,
    ) -> Occurrence {
        return Occurrence {
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
            label,
        };
    }

    pub fn starts_at(&self) -> Time {
        return Occurrence::ruby_handle()
            .time_new(self.starts_at_unix_timestamp, 0)
            .unwrap();
    }

    pub fn ends_at(&self) -> Time {
        return Occurrence::ruby_handle()
            .time_new(self.ends_at_unix_timestamp, 0)
            .unwrap();
    }

    pub fn starts_at_utc(&self) -> DateTime<Utc> {
        return DateTime::from_timestamp(self.starts_at_unix_timestamp, 0).unwrap();
    }

    pub fn ends_at_utc(&self) -> DateTime<Utc> {
        return DateTime::from_timestamp(self.ends_at_unix_timestamp, 0).unwrap();
    }

    pub fn label(&self) -> Option<String> {
        return self.label.clone();
    }

    pub(crate) fn inspect(&self) -> String {
        return format!(
            "<Reprise::Core::Occurrence starts_at={:?} ends_at={:?} label={:?}>",
            self.starts_at_utc().to_rfc3339(),
            self.ends_at_utc().to_rfc3339(),
            self.label().unwrap_or("nil".into())
        );
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
    let occurrence_class =
        ruby_modules::reprise_core().define_class("Occurrence", class::object())?;
    occurrence_class.define_method("starts_at", method!(Occurrence::starts_at, 0))?;
    occurrence_class.define_method("ends_at", method!(Occurrence::ends_at, 0))?;
    occurrence_class.define_method("label", method!(Occurrence::label, 0))?;
    occurrence_class.define_method("inspect", method!(Occurrence::inspect, 0))?;

    Ok(())
}
