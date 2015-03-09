//
//  MASShortcutBinder.swift
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


import Foundation

/**
Binds actions to user defaults keys.

If you store shortcuts in user defaults (for example by binding
a `MASShortcutView` to user defaults), you can use this class to
connect an action directly to a user defaults key. If the shortcut
stored under the key changes, the action will get automatically
updated to the new one.

This class is mostly a wrapper around a `MASShortcutMonitor`. It
watches the changes in user defaults and updates the shortcut monitor
accordingly with the new shortcuts.
*/
class MASShortcutBinder: NSObject {
	
	/**
	 The underlying shortcut monitor.
	*/
	var shortcutMonitor = MASShortcutMonitor.sharedMonitor()
	
	/**
	 Binding options customizing the access to user defaults.
		
	 As an example, you can use `NSValueTransformerNameBindingOption` to customize
	 the storage format used for the shortcuts. By default the shortcuts are converted
	 from `NSData` (`NSKeyedUnarchiveFromDataTransformerName`). Note that if the
	 binder is to work with `MASShortcutView`, both object have to use the same storage
	 format.
	*/
	var bindingOptions:[NSObject : AnyObject]
		= [NSValueTransformerNameBindingOption:NSKeyedUnarchiveFromDataTransformerName]
	
	private var actions = [:] as NSMutableDictionary!
	private var shortcuts = [:] as NSMutableDictionary!
	
	// MARK: Initialization
	
	deinit {
		
		for bindingName in self.actions.allKeys as! [String] {
			self.unbind( bindingName )
		}
		
	}
	
	
	/**
	 A convenience shared instance.
		
	 You may use it so that you don’t have to manage an instance by hand,
	 but it’s perfectly fine to allocate and use a separate instance instead.
	*/
	class func sharedBinder() -> MASShortcutBinder {

		struct once { static var memory:dispatch_once_t=0 }
		struct sharedInstance { static var memory:MASShortcutBinder! }
		
		dispatch_once( &once.memory ) {
			sharedInstance.memory = MASShortcutBinder()
		}

		return sharedInstance.memory

	}
	
	// MARK: Registration

	
	/**
	 Binds given action to a shortcut stored under the given defaults key.
		
	 In other words, no matter what shortcut you store under the given key,
	 pressing it will always trigger the given action.
	*/
	
	func bindShortcutWithDefaultsKey( defaultsKeyName: String!, toAction action:dispatch_block_t! ){
		
		// TODO: when app is entirely Swift, don't use unsafe bitcast
		let action: AnyObject = unsafeBitCast( action, AnyObject.self )
		// TODO: original used action.copy
		self.actions.setObject( action.copy() /*.copy*/, forKey:defaultsKeyName )
		
		self.bind(
			defaultsKeyName,
			toObject: NSUserDefaultsController.sharedUserDefaultsController(),
			withKeyPath: "values.\(defaultsKeyName)",
			options: self.bindingOptions
		)
		
	}

	/**
	Disconnect the binding between user defaults and action.
	
	In other words, the shortcut stored under the given key will no longer trigger an action.
	*/
	
	func breakBindingWithDefaultsKey( defaultsKeyName: String! ) {
		
		self.shortcutMonitor.unregisterShortcut( self.shortcuts.objectForKey( defaultsKeyName ) as! MASShortcut )
		self.shortcuts.removeObjectForKey( defaultsKeyName )
		self.actions.removeObjectForKey( defaultsKeyName )
		self.unbind( defaultsKeyName )
		
	}
	
	// MARK: Bindings
	
	/**
	 Register default shortcuts in user defaults.
		
	 This is a convenience frontent to `[NSUserDefaults registerDefaults]`.
	 The dictionary should contain a map of user defaults’ keys to appropriate
	 keyboard shortcuts. The shortcuts will be transformed according to
	 `bindingOptions` and registered using `registerDefaults`.
	*/
	func registerDefaultShortcuts( defaultShortcuts: [NSObject : AnyObject]! ){

		var transformer:NSValueTransformer!
			= self.bindingOptions[NSValueTransformerBindingOption] as? NSValueTransformer
		
		if transformer == nil {
			let transformerName:String!
				= self.bindingOptions[NSValueTransformerNameBindingOption] as? String
			if transformerName != nil {
				transformer = NSValueTransformer( forName:transformerName )
			}
		}

		assert( transformer != nil, "Can’t register default shortcuts without a transformer." )

		(defaultShortcuts as NSDictionary).enumerateKeysAndObjectsUsingBlock {
			gen_defaultsKey, gen_shortcut, stop in
			let defaultsKey = gen_defaultsKey as! NSString
			let shortcut = gen_shortcut as! MASShortcut!
			let value: AnyObject! = transformer.reverseTransformedValue( gen_shortcut )
			NSUserDefaults.standardUserDefaults().registerDefaults(
				[defaultsKey:value]
			)
		}
		
	}
	
	override internal func setValue( value: AnyObject?, forUndefinedKey key: String ) {

		if !self.isRegisteredAction( key ) {
			super.setValue( value, forUndefinedKey:key )
			return
		}

		let newShortcut = value as! MASShortcut!
		let currentShortcut = self.shortcuts.objectForKey( key ) as! MASShortcut!

		// Unbind previous shortcut if any
		if currentShortcut != nil {
			self.shortcutMonitor.unregisterShortcut( currentShortcut )
		}

		// Just deleting the old shortcut
		if newShortcut == nil {
			return
		}

		// Bind new shortcut
		self.shortcuts.setObject( newShortcut, forKey:key )
		// TODO: when app is entirely Swift, don't use unsafe bitcast
		let action = unsafeBitCast( self.actions[key]!, dispatch_block_t.self )
		self.shortcutMonitor.registerShortcut(
			newShortcut,
			withAction: action
		)
		
	}
	
	internal func isRegisteredAction( name: String! ) -> Bool {
		return self.actions.objectForKey(name) != nil
	}
	
	override internal func valueForUndefinedKey( key: String ) -> AnyObject? {
		return self.isRegisteredAction( key )
			? self.shortcuts.objectForKey(key)
			: super.valueForUndefinedKey(key)
	}
	
}
