//
//  MASDictionaryTransformer.swift
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


import Foundation

let MASDictionaryTransformerName = "MASDictionaryTransformer"
let MASKeyCodeKey = "keyCode"
let MASModifierFlagsKey = "modifierFlags"

/**
Converts shortcuts for storage in user defaults.

User defaults can’t stored custom types directly, they have to
be serialized to `NSData` or some other supported type like an
`NSDictionary`. In Cocoa Bindings, the conversion can be done
using value transformers like this one.

There’s a built-in transformer (`NSKeyedUnarchiveFromDataTransformerName`)
that converts any `NSCoding` types to `NSData`, but with shortcuts
it makes sense to use a dictionary instead – the defaults look better
when inspected with the `defaults` command-line utility and the
format is compatible with an older sortcut library called Shortcut
Recorder.
*/
class MASDictionaryTransformer: NSValueTransformer {

	override class func allowsReverseTransformation() -> Bool {
		return true
	}
	
	// Storing nil values as an empty dictionary lets us differ between
	// “not available, use default value” and “explicitly set to none”.
	// See http://stackoverflow.com/questions/5540760 for details.
	override func reverseTransformedValue( value: AnyObject? ) -> AnyObject? {
		if value == nil {
			return NSDictionary()
		}
		
		let shortcut = value as! MASShortcut?

		let dict = [
			MASKeyCodeKey: shortcut!.keyCode,
			MASModifierFlagsKey: shortcut!.modifierFlags
		]
		
		return dict as NSDictionary
		
	}
	
	override func transformedValue( value: AnyObject? ) -> AnyObject? {

		let dictionary = value as? NSDictionary
		
		// We have to be defensive here as the value may come from user defaults.
		if dictionary == nil {
			return nil
		}
		
		let keyCodeBox = dictionary!.objectForKey( MASKeyCodeKey ) as? NSNumber
		let modifierFlagsBox = dictionary!.objectForKey( MASModifierFlagsKey ) as? NSNumber
		
		if keyCodeBox == nil || modifierFlagsBox == nil {
			return nil
		}
		
		return MASShortcut(
			keyCode: UInt( keyCodeBox!.unsignedIntegerValue ),
			modifierFlags: UInt( modifierFlagsBox!.unsignedIntegerValue )
		)
		
	}
	
}