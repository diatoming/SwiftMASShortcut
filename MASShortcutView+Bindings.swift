//
//  MASShortcutView+Bindings.swift
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
A simplified interface to bind the recorder value to user defaults.

You can bind the `shortcutValue` to user defaults using the standard
`bind:toObject:withKeyPath:options:` call, but since that’s a lot to type
and read, here’s a simpler option.

Setting the `associatedUserDefaultsKey` binds the view’s shortcut value
to the given user defaults key. You can supply a value transformer to convert
values between user defaults and `MASShortcut`. If you don’t supply
a transformer, the `NSUnarchiveFromDataTransformerName` will be used
automatically.

Set `associatedUserDefaultsKey` to `nil` to disconnect the binding.
*/

extension MASShortcutView {
	
	@objc var associatedUserDefaultsKey:NSString! {
		
		get {

			let maybe_bindingInfo = self.infoForBinding( MASShortcutBinding )
			
			if let untyped_bindingInfo = maybe_bindingInfo {

				let bindingInfo = untyped_bindingInfo as! [String:String]
				let keyPath = bindingInfo[NSObservedKeyPathKey]!
				let key = keyPath.stringByReplacingOccurrencesOfString( "values.", withString: "")
				return key
				
			}
			
			return nil
			
		}
		
		set( newKey ){
			
			self.setAssociatedUserDefaultsKey(
				newKey as String,
				withTransformerName: NSKeyedUnarchiveFromDataTransformerName
			)
			
		}
		
	}

	func setAssociatedUserDefaultsKey( newKey: String!, withTransformer transformer: NSValueTransformer! ){
	
		// Break previous binding if any
		if let currentKey = self.associatedUserDefaultsKey {
			self.unbind( currentKey as String )
		}

		// Stop if the new binding is nil
		if newKey == nil {
			return
		}

		let options:[String:NSValueTransformer]!
			= transformer != nil
			? [ NSValueTransformerBindingOption: transformer ]
			: nil
		
		self.bind(
			MASShortcutBinding,
			toObject: NSUserDefaultsController.sharedUserDefaultsController(),
			withKeyPath: "values." + newKey,
			options: options
		)
		
	}
	
	func setAssociatedUserDefaultsKey( newKey: String!, withTransformerName transformerName: String! ){
	
		self.setAssociatedUserDefaultsKey(
			newKey,
			withTransformer: NSValueTransformer( forName:transformerName )
		)
		
	}

}