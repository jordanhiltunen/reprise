use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The ByWeekNumber modifier corresponds to iCalendar's:
/// bywknolist  = ( weeknum *("," weeknum) )
/// weeknum = [plus / minus] ordwk
/// ordwk = 1*2DIGIT; 1 to 53
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct ByWeekNumber {
    pub(crate) week_number: Vec<i8>, // +/- 1 to 53
}

impl Modifiable for ByWeekNumber {
}
