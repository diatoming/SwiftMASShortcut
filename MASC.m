//
//  MASC.m
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


#import "MASC.h"
#import "SwiftMASShortcut-Swift.h"

static OSStatus MASCarbonEventCallback( EventHandlerCallRef _, EventRef event, void *context ){
	
	MASShortcutMonitor *dispatcher = (__bridge id)context;
	[dispatcher handleEvent:event];
	return noErr;
	
}

EventHandlerUPP MASCarbonEventCallback_ptr = MASCarbonEventCallback;
