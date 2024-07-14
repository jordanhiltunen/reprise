use std::ops::Add;
use chrono::{DateTime, NaiveTime, TimeDelta};
use chrono_tz::Tz;

pub(crate) fn advance_time_safely(
    datetime_cursor: &DateTime<Tz>,
    time_delta: TimeDelta,
    naive_time: NaiveTime,
) -> DateTime<Tz> {
    let new_datetime_cursor = datetime_cursor.checked_add_signed(time_delta)
        .expect("Datetime must advance")
        .with_time(naive_time).latest();

    return match new_datetime_cursor {
        None => {
            let timezone = datetime_cursor.timezone();
            let datetime_cursor_utc = datetime_cursor.with_time(naive_time)
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

pub(crate) fn set_datetime_cursor_safely(datetime_cursor: DateTime<Tz>, naive_time: NaiveTime) -> DateTime<Tz> {
    return match datetime_cursor.with_time(naive_time).latest() {
        None => {
            // If there is no valid time, it means that we are in a gap in local time:
            // the requested local time is missing / does not exist. This occurs when
            // a local time clock is turned forwards during a transition. To compensate,
            // we translate the requested time one hour ahead, out of the gap.
            datetime_cursor.with_time(naive_time.add(TimeDelta::hours(1))).latest().unwrap()
        }
        Some(datetime_cursor) => { datetime_cursor }
    }
}
