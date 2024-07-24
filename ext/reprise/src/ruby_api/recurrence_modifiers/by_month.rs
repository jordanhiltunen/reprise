use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The ByMinute modifier corresponds to iCalendar's:
/// bymodaylist = ( monthdaynum *("," monthdaynum) )
/// monthnum = 1*2DIGIT; 1 to 12
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct ByMonth {
    pub(crate) month: Vec<u8>, // 1-12
}

impl Modifiable for ByMonth {
}
