use crate::ruby_api::time_of_day::TimeOfDay;
use chrono::{DateTime, NaiveTime, TimeDelta};
use chrono_tz::Tz;

pub(crate) fn advance_time_safely(
    datetime_cursor: &DateTime<Tz>,
    time_delta: TimeDelta,
    time_of_day: NaiveTime,
) -> DateTime<Tz> {
    let new_datetime_cursor = datetime_cursor.checked_add_signed(time_delta)
        .expect("Datetime must advance")
        .with_time(time_of_day).latest();

    return match new_datetime_cursor {
        None => {
            let timezone = datetime_cursor.timezone();
            let datetime_cursor_utc = datetime_cursor.with_time(time_of_day)
                .latest()
                .expect("Datetime must advance")
                .to_utc();

            return datetime_cursor_utc
                .checked_add_signed(time_delta)
                .expect("UTC datetime must be advanced")
                .with_timezone(&timezone);
        }
        Some(new_datetime_cursor) => new_datetime_cursor,
    };
}
