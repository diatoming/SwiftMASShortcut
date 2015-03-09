//
//  MASShortcutMonitor.swift
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

/**
Executes action when a shortcut is pressed.

There can only be one instance of this class, otherwise things
will probably not work. (There’s a Carbon event handler inside
and there can only be one Carbon event handler of a given type.)
*/
class MASShortcutMonitor:NSObject {
	
	var eventHandlerRef_ptr = UnsafeMutablePointer<EventHotKeyRef>.alloc(1)
	var eventHandlerRef:EventHotKeyRef {
		return eventHandlerRef_ptr.memory
	}
	
	var hotKeys:NSMutableDictionary! = NSMutableDictionary()
	
	// MARK: Initialization
	
	override init() {

		super.init()

		let hotKeyPressedSpec = EventTypeSpec(
			eventClass: OSType( kEventClassKeyboard ),
			eventKind:  UInt32( kEventHotKeyPressed )
		)
		var hotKeyPressedSpec_ptr = UnsafeMutablePointer<EventTypeSpec>.alloc(1)
		hotKeyPressedSpec_ptr.memory = hotKeyPressedSpec
		
		
		// http://dev.eltima.com/post/97718928834/interacting-with-c-pointers-in-swift-part-3
		// http://www.peachpit.com/articles/article.aspx?p=24462

//		typealias callback = ( EventHandlerCallRef, EventRef, UnsafeMutablePointer<Void>) -> OSStatus
//		
//		var pointer = UnsafeMutablePointer<callback>.alloc(1)
//		pointer.initialize( MASCarbonEventCallback )
//		let c_pointer = COpaquePointer( pointer )
//		pointer.dealloc(1)
//		let callback_ptr = CFunctionPointer<callback>( c_pointer ) as EventHandlerProcPtr
//		let handler_upp = NewEventHandlerUPP( callback_ptr )
		
		let handler_upp = MASCarbonEventCallback_ptr
		
		let status = InstallEventHandler(
			GetEventDispatcherTarget(),
			handler_upp,
			Carbon.ItemCount(1),
			hotKeyPressedSpec_ptr,
			unsafeBitCast( self, UnsafeMutablePointer<Void>.self ),  //as_void_ptr( self ),
			self.eventHandlerRef_ptr
		)
		
		assert( status == noErr, "Could not create MASShortcutMonitor" )
	
	}
	
	deinit {
		if self.eventHandlerRef != nil {
			RemoveEventHandler( self.eventHandlerRef )
			self.eventHandlerRef_ptr.dealloc(1)
		}
	}
	
	class func sharedMonitor() -> MASShortcutMonitor {

		struct once { static var memory:dispatch_once_t=0 }
		struct sharedInstance { static var memory:MASShortcutMonitor! }
		
		dispatch_once( &once.memory ) {
			sharedInstance.memory = MASShortcutMonitor()
		}

		return sharedInstance.memory

	}	
	
	// MARK: Registration

	/**
	 Register a shortcut along with an action.
		
	 Attempting to insert an already registered shortcut probably won’t work.
	 It may burn your house or cut your fingers. You have been warned.
	*/
	
	func registerShortcut( shortcut: MASShortcut!, withAction action: dispatch_block_t! ) -> Bool {
		
		let hotKey:MASHotKey! = MASHotKey.registeredHotKeyWithShortcut( shortcut )
		
		if hotKey == nil {
			return false
		}
	
		hotKey.action = action
		
		self.hotKeys.setObject( hotKey, forKey: shortcut )

		return true
	
	}
	
	func unregisterShortcut( shortcut: MASShortcut! ){
		
		if shortcut != nil {
			self.hotKeys.removeObjectForKey( shortcut )
		}
	}
	
	func unregisterAllShortcuts() {
		self.hotKeys.removeAllObjects()
	}
	
	func isShortcutRegistered( shortcut: MASShortcut! ) -> Bool {
		return self.hotKeys.objectForKey( shortcut ) != nil
	}
	
	// MARK: Event Handling

	@objc internal func handleEvent( event: EventRef ) {

		if GetEventClass( event ) != OSType( kEventClassKeyboard ) {
			return
		}
	
		var hotKeyID = EventHotKeyID()
		
		let status = GetEventParameter(
			event,
			EventParamName( kEventParamDirectObject ),
			EventParamType( typeEventHotKeyID ),
			nil,
			Carbon.ByteCount( sizeof( EventHotKeyID ) ),
			nil,
			&hotKeyID
		)
		
		if status != noErr || hotKeyID.signature != MASHotKeySignature {
			return
		}

		self.hotKeys.enumerateKeysAndObjectsUsingBlock {
			shortcut_obj, hotKey_obj, stop in
			
			let shortcut = shortcut_obj as! MASShortcut!
			let hotKey = hotKey_obj as! MASHotKey!

			if hotKey.action != nil {
				
				dispatch_async( dispatch_get_main_queue(), {
					
					let action = hotKey.action
					action()
					
				})
				
			}
			
			stop.memory = true
			
		}
	
	}
	
	
}

//func MASCarbonEventCallback(
//	_: EventHandlerCallRef,
//	event: EventRef,
//	context: UnsafeMutablePointer<Void>
//	) -> OSStatus {
//		
//		let dispatcher = UnsafeMutablePointer<MASShortcutMonitor>(context).memory
//		dispatcher.handleEvent( event )
//		return noErr
//		
//}
