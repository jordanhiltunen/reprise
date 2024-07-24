use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The ByHour modifier corresponds to iCalendar's:
/// byhrlist = ( hour *("," hour) )
/// hour = 1*2DIGIT; 0 to 23
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct ByHour {
    pub(crate) hour: Vec<u8>, // 0 - 23
}

impl ByHour {
}

impl Modifiable for ByHour {
}
