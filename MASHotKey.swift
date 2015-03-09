//
//  MASHotKey.swift
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


import Foundation

import Carbon

let MASHotKeySignature:FourCharCode = UTGetOSTypeFromString( "MASS" )
//let MASHotKeySigString = UTCreateStringForOSType( MASHotKeySignature ).takeUnretainedValue()

@objc class MASHotKey: NSObject {

	var hotKeyRef_ptr = UnsafeMutablePointer<EventHotKeyRef>.alloc(1)
	var hotKeyRef:EventHotKeyRef {
		return hotKeyRef_ptr.memory
	}

	@objc var carbonID:UInt32=0
	
	var action:dispatch_block_t!
	
	init( shortcut:MASShortcut ) {
		
		super.init()
		
		struct CarbonHotKeyID { static var memory:UInt32=0 }
		
		self.carbonID = ++CarbonHotKeyID.memory
		
		let hotKeyID = EventHotKeyID(
			signature: MASHotKeySignature,
			id: self.carbonID
		)
		
		let status = RegisterEventHotKey(
			shortcut.carbonKeyCode,
			shortcut.carbonFlags,
			hotKeyID,
			GetEventDispatcherTarget(),
			0 as OptionBits,
			self.hotKeyRef_ptr
		)
		
		assert( status == noErr, "RegisterEventHotKey failed" )
		
	}
	
	deinit {
		
		if self.hotKeyRef != nil {
			UnregisterEventHotKey( self.hotKeyRef )
			self.hotKeyRef_ptr.dealloc(1)
		}
		
	}
	
	class func registeredHotKeyWithShortcut( shortcut: MASShortcut! ) -> MASHotKey {
				
		return MASHotKey( shortcut:shortcut )
		
	}
	
}