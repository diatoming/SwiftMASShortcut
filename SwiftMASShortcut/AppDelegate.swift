//
//  AppDelegate.swift
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


import Cocoa
import AppKit
import Carbon

let MASCustomShortcutKey = "customShortcut"
let MASCustomShortcutEnabledKey = "customShortcutEnabled"
let MASHardcodedShortcutEnabledKey = "hardcodedShortcutEnabled"

var MASObservingContext = UnsafeMutablePointer<Void>.alloc(1)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet var customShortcutView:MASShortcutView!
	@IBOutlet var feedbackTextField:NSTextField!
	
	@IBOutlet weak var window: NSWindow!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application

		var defaults = NSUserDefaults.standardUserDefaults()
		
		// Register default values to be used for the first app start
		defaults.registerDefaults([
			MASHardcodedShortcutEnabledKey: true,
			MASCustomShortcutEnabledKey: true
		])

		// Bind the shortcut recorder view’s value to user defaults.
		// Run “defaults read com.shpakovski.mac.Demo” to see what’s stored
		// in user defaults.
		
		self.customShortcutView.associatedUserDefaultsKey = MASCustomShortcutKey
		
		// Enable or disable the recorder view according to the first checkbox state
		
		self.customShortcutView.bind(
			"enabled",
			toObject: defaults,
			withKeyPath: MASCustomShortcutEnabledKey,
			options: nil
		)
		
		// Watch user defaults for changes in the checkbox states
		
		defaults.addObserver(
			self,
			forKeyPath: MASCustomShortcutEnabledKey,
			options: NSKeyValueObservingOptions.Initial | NSKeyValueObservingOptions.New,
			context: MASObservingContext
		)
		
		defaults.addObserver(
			self,
			forKeyPath: MASHardcodedShortcutEnabledKey,
			options: NSKeyValueObservingOptions.Initial | NSKeyValueObservingOptions.New,
			context: MASObservingContext
		)

	}

	@objc func playShortcutFeedback() {
		
		NSSound( named:"Ping" )?.play()
		self.feedbackTextField.stringValue = "Shortcut pressed!"

		dispatch_after(
			
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64( 0.5 * Double(NSEC_PER_SEC) )
			),
			
			dispatch_get_main_queue(), {
				self.feedbackTextField.stringValue = ""
			}

		)

	}
	
	// Handle changes in user defaults. We have to check keyPath here to see which of the
	// two checkboxes was changed. This is not very elegant, in practice you could use something
	// like https://github.com/facebook/KVOController with a nicer API.

	override func observeValueForKeyPath(
		keyPath: String,
		ofObject object: AnyObject,
		change: [NSObject : AnyObject],
		context: UnsafeMutablePointer<Void>
	) {
		
		if( context != MASObservingContext) {
			super.observeValueForKeyPath( keyPath, ofObject: object, change: change, context: context )
			return
		}
		
		let newValue = change[NSKeyValueChangeNewKey]!.boolValue
		
		if keyPath == MASCustomShortcutEnabledKey {
			self.setCustomShortcutEnabled( newValue )
		} else if keyPath == MASHardcodedShortcutEnabledKey {
			self.setHardcodedShortcutEnabled( newValue )
		}
		
	}

	func setCustomShortcutEnabled( enabled:Bool ){
		if enabled {
			
			MASShortcutBinder.sharedBinder().bindShortcutWithDefaultsKey(
				MASCustomShortcutKey,
				toAction: { () -> Void in
					
					self.playShortcutFeedback()
					
				}
			)
			
		} else {
			
			MASShortcutBinder.sharedBinder().breakBindingWithDefaultsKey( MASCustomShortcutKey )

		}
	}

	func setHardcodedShortcutEnabled( enabled:Bool ){
		
		let shortcut = MASShortcut(
			keyCode: UInt( kVK_F2 ),
			modifierFlags: NSEventModifierFlags.CommandKeyMask.rawValue
		)
		
		if enabled {
			
				MASShortcutMonitor.sharedMonitor().registerShortcut(
					shortcut,
					withAction: { () -> Void in

						self.playShortcutFeedback()

				})
			
		} else {
			MASShortcutMonitor.sharedMonitor().unregisterShortcut( shortcut )
		}
	}
	
	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

	func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
		return true
	}

}

