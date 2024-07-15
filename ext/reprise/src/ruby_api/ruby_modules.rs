use magnus::{value::Lazy, Module, RModule, Ruby};

static REPRISE: Lazy<RModule> = Lazy::new(|ruby| ruby.define_module("Reprise").unwrap());

pub(crate) fn reprise() -> RModule {
    Ruby::get().unwrap().get_inner(&REPRISE)
}

static CORE: Lazy<RModule> =
    Lazy::new(|ruby| ruby.get_inner(&REPRISE).define_module("Core").unwrap());

pub(crate) fn reprise_core() -> RModule {
    Ruby::get().unwrap().get_inner(&CORE)
}
