use std::error::Error;

fn main() -> Result<(), Box<dyn Error>> {
    // Propagate linking from rb-sys for usage in the Reprise extension
    let _ = rb_sys_env::activate()?;

    Ok(())
}
