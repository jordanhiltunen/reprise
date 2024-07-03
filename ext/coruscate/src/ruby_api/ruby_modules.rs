use magnus::{value::Lazy, Module, RModule, Ruby};

static CORUSCATE: Lazy<RModule> = Lazy::new(|ruby| ruby.define_module("Coruscate").unwrap());

pub(crate) fn coruscate() -> RModule {
    Ruby::get().unwrap().get_inner(&CORUSCATE)
}

static CORE: Lazy<RModule> =
    Lazy::new(|ruby| ruby.get_inner(&CORUSCATE).define_module("Core").unwrap());

pub(crate) fn coruscate_core() -> RModule {
    Ruby::get().unwrap().get_inner(&CORE)
}
