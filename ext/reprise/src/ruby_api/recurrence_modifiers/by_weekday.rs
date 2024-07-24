use chrono::Weekday;
use crate::ruby_api::recurrence_modifiers::modifiable::Modifiable;

/// The ByWeekday modifier corresponds to iCalendar's:
/// bywdaylist = ( weekdaynum *("," weekdaynum) )
/// NB. `bywdaylist` seems improperly specified.
/// weekdaynum  = [[plus / minus] ordwk] weekday
/// weekday = "SU" / "MO" / "TU" / "WE" / "TH" / "FR" / "SA"
/// ordwk = 1*2DIGIT; 1 to 53
/// The BYDAY rule part specifies a COMMA-separated list of days of the week;
/// SU indicates Sunday; MO indicates Monday; TU indicates Tuesday;
/// WE indicates Wednesday; TH indicates Thursday; FR indicates
/// Friday; and SA indicates Saturday.
/// Each BYDAY value can also be preceded by a positive (+n) or
/// negative (-n) integer. If present, this indicates the nth occurrence
/// of a specific day within the MONTHLY or YEARLY "RRULE". For example,
/// within a MONTHLY rule, +1MO (or simply 1MO) represents the first
/// Monday within the month, whereas -1MO represents the last Monday
/// of the month. The numeric value in a BYDAY rule part with the FREQ
/// rule part set to YEARLY corresponds to an offset within the month
/// when the BYMONTH rule part is present, and corresponds to an offset
/// within the year when the BYWEEKNO or BYMONTH rule parts are present.
/// If an integer modifier is not present, it means all days of this type
/// within the specified frequency. For example, within a MONTHLY rule,
/// MO represents all Mondays within the month. The BYDAY rule part
/// MUST NOT be specified with a numeric value when the FREQ rule part
/// is not set to MONTHLY or YEARLY. Furthermore, the BYDAY rule part
/// MUST NOT be specified with a numeric value with the FREQ rule part
/// set to YEARLY when the BYWEEKNO rule part is specified.
/// See: https://icalendar.org/iCalendar-RFC-5545/3-3-10-recurrence-rule.html
#[derive(Debug, Clone)]
pub(crate) struct ByWeekday {
    pub(crate) nth_occurrence: Option<i8>,
    pub(crate) weekday: Weekday,
}

impl Modifiable for ByWeekday {
}
