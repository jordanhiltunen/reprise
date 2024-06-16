// use magnus::{
//     class,
//     define_class,
//     encoding::{CType, RbEncoding},
//     method,
//     prelude::*,
//     Error, RString,
// };
//  use magnus::method::Function0

use std::ops::Add;
use magnus::{class, define_module, function, method, prelude::*, Error, Value, RArray, Ruby, Time};
use magnus::r_array;


// use magnus::Time;
use std::time::{Duration, SystemTime};

// fn is_blank(rb_self: RString) -> Result<bool, Error> {
//     // RString::as_str is unsafe as it's possible for Ruby to invalidate the
//     // str as we hold a reference to it, but here we're only ever using the
//     // &str before Ruby is invoked again, so it doesn't get a chance to mess
//     // with it and this is safe.
//     unsafe {
//         // fast path, string is valid utf-8 and we can use Rust's stdlib
//         if let Some(s) = rb_self.test_as_str() {
//             return Ok(!s.contains(|c: char| !c.is_whitespace()));
//         }
//     }
//
//     // slow path, use Ruby's API to iterate the codepoints and check for blanks
//     let enc = RbEncoding::from(rb_self.enc_get());
//     // Similar to ::as_str above, RString::codepoints holds a reference to the
//     // underlying string data and we can't let Ruby mutate or invalidate the
//     // string while we hold a reference to the codepoints iterator. Here we
//     // don't invoke any Ruby methods that could modify the string, so this is
//     // safe.
//     unsafe {
//         for cp in rb_self.codepoints() {
//             if !enc.is_code_ctype(cp?, CType::Blank) {
//                 return Ok(false);
//             }
//         }
//     }
//
//     Ok(true)
// }
//
// #[magnus::init]
// fn init() -> Result<(), Error> {
//     let class = define_class("String", class::object())?;
//     class.define_method("rust_blank?", method!(is_blank, 0))?;
//     Ok(())
// }

fn return_hello() -> String {
    return "Hello!".to_string();
}

fn return_modified_time(ruby: &Ruby, raw_time: SystemTime) -> RArray {

    // return raw_time.add(Duration::new(900, 0));


//     raw_time

//     let mut additional_times: Vec<SystemTime> = Vec::new();
//
//     additional_times.push(raw_time.add(Duration::new(900, 0)));
//     additional_times.push(raw_time.add(Duration::new(1800, 0)));
//     additional_times.push(raw_time.add(Duration::new(2700, 0)));

//     additional_times.push("Hello".into());
//     additional_times.push("Hello".into());
//     additional_times.push("Hello".into());

    // return raw_time;

//     return r_array::RArray::from_vec(additional_times);

//     return additional_times;

    // let mut additional_times: Vec<Time> = Vec::new();
    //
    // additional_times.push(ruby.time_new(1654013280, 0).unwrap());
    // additional_times.push(ruby.time_new(1654015280, 0).unwrap());
    // additional_times.push(ruby.time_new(1654018280, 0).unwrap());
    //
    // return additional_times;

    let r_arr = RArray::new();

    r_arr.push(ruby.time_new(1654018280, 0).unwrap()).unwrap();
    r_arr.push(ruby.time_new(1654018280, 0).unwrap()).unwrap();
    r_arr.push(ruby.time_new(1654018280, 0).unwrap()).unwrap();

    return r_arr;

}


#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("Coruscate")?;
    module.define_module_function("return_hello", function!(return_hello, 0)).unwrap();
    module.define_module_function("return_modified_time", function!(return_modified_time, 1)).unwrap();
    Ok(())
}


