use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The ByMinute modifier corresponds to iCalendar's:
/// byminlist = ( minutes *("," minutes) )
/// minutes = 1*2DIGIT; 0 to 59
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct ByMinute {
    pub(crate) minute: Vec<u8>, // 0 - 59
}

impl Modifiable for ByMinute {
}
