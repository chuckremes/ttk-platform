# Purpose

All of the high-level abstractions that should carry over
between strategies across brokers are collected here.

For example, the `TTK::Platform::Wrappers::Quote` class
is a generic wrapper that goes around a specific vendor's
implementation. All methods are delegated by the wrapper
to its internal instance. We test the implementation by
use of the shared specs facility provided by
`ttk-containers` just like the vendor gems use. Therefore,
all implementations should remain in sync at all times.

Further, this gem will contain the logic for loading
the correct vendor's gem upon loading and instantiation
of a strategy. The strategy configuration files specify
the vendor to use, so that information is used to
bootstrap the correct broker gem. All broker gems
should present an identical interface, so the other
high level constructs here can interchangeably use any
broker without modification. (Will be cool if this
actually works.)