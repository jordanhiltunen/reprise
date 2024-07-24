use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The ByMonthDay modifier corresponds to iCalendar's:
/// bymodaylist = ( monthdaynum *("," monthdaynum) )
/// monthdaynum = [plus / minus] ordmoday
/// ordmoday = 1*2DIGIT; 1 to 31
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct ByMonthDay {
    pub(crate) month_day: Vec<i8>, // +/-1 - 31
}

impl Modifiable for ByMonthDay {
}
