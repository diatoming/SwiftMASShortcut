//
//  MASC.h
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


@import Carbon;

static OSStatus MASCarbonEventCallback( EventHandlerCallRef _, EventRef event, void *context );

EventHandlerUPP MASCarbonEventCallback_ptr;
