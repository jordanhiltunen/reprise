use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The BySecond modifier corresponds to iCalendar's:
/// byseclist = ( seconds *("," seconds) )
/// seconds = 1*2DIGIT; 0 to 60
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct BySecond {
    pub(crate) second: Vec<u8>, // 0-60
}

impl Modifiable for BySecond {
}
