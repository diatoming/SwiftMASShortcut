//
//  MASShortcut.swift
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


let MASShortcutKeyCode = "KeyCode"
let MASShortcutModifierFlags = "ModifierFlags"

func contains_flag( container:UInt, flag:NSEventModifierFlags ) -> Bool {
	
	let cont = Int( container )
	let f = Int( flag.rawValue )
	return cont & f == f
	
}

/**
A model class to hold a key combination.

This class just represents a combination of keys. It does not care if
the combination is valid or can be used as a hotkey, it doesn’t watch
the input system for the shortcut appearance, nor it does access user
defaults.
*/
class MASShortcut: NSObject, NSSecureCoding, NSCopying {
	
	/**
	The virtual key code for the keyboard key.

	Hardware independent, same as in `NSEvent`. See `Events.h` in the HIToolbox
	framework for a complete list, or Command-click this symbol: `kVK_ANSI_A`.
	*/
	var _keyCode:UInt!
	/*nonatomic*/ var keyCode:UInt {
		return self._keyCode
	}

	/**
	Cocoa keyboard modifier flags.

	Same as in `NSEvent`: `NSCommandKeyMask`, `NSAlternateKeyMask`, etc.
	*/
	var _modifierFlags:UInt!
	/*nonatomic*/ var modifierFlags:UInt {
		return self._modifierFlags
	}

	/**
	Same as `keyCode`, just a different type.
	*/
	/*nonatomic*/ var carbonKeyCode:UInt32 {
		return self.keyCode == UInt( NSNotFound )
			? UInt32( 0 )
			: UInt32( self.keyCode )
	}

	/**
	Carbon modifier flags.

	A bit sum of `cmdKey`, `optionKey`, etc.
	*/
	/*nonatomic*/ var carbonFlags:UInt32 {
		return MASCarbonModifiersFromCocoaModifiers( self.modifierFlags )
	}

	override var description:String {
		return "\(self.modifierFlagsString)\(self.keyCodeString)"
	}
	
	/**
	A key-code string used in key equivalent matching.
	
	For precise meaning of “key equivalents” see the `keyEquivalent`
	property of `NSMenuItem`. Here the string is used to support shortcut
	validation (“is the shortcut already taken in this menu?”) and
	for display in `NSMenu`.
	
	The value of this property may differ from `keyCodeString`. For example
	the Russian keyboard has a `Г` (Ge) Cyrillic character in place of the
	latin `U` key. This means you can create a `^Г` shortcut, but in menus
	that’s always displayed as `^U`. So the `keyCodeString` returns `Г`
	and `keyCodeStringForKeyEquivalent` returns `U`.
	*/
	/*nonatomic*/ var keyCodeStringForKeyEquivalent:String {
		
		let keyCodeString = self.keyCodeString
		
		if ( keyCodeString.length <= 1 ) {
			
			return keyCodeString.lowercaseString
			
		}

		switch Int( self.keyCode ){
			
			case kVK_F1:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF704 ) )
			case kVK_F2:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF705 ) )
			case kVK_F3:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF706 ) )
			case kVK_F4:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF707 ) )
			case kVK_F5:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF708 ) )
			case kVK_F6:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF709 ) )
			case kVK_F7:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF70a ) )
			case kVK_F8:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF70b ) )
			case kVK_F9:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF70c ) )
			case kVK_F10:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF70d ) )
			case kVK_F11:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF70e ) )
			case kVK_F12:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF70f ) )
			// From here I am guessing F13 etc come sequentially
			case kVK_F13:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF710 ) )
			case kVK_F14:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF711 ) )
			case kVK_F15:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF712 ) )
			case kVK_F16:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF713 ) )
			case kVK_F17:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF714 ) )
			case kVK_F18:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF715 ) )
			case kVK_F19:
				return NSStringFromMASKeyCode( CUnsignedShort( 0xF716 ) )
			case kVK_Space:
				return NSStringFromMASKeyCode( CUnsignedShort( 0x20 ) )
			default:
				break
			
		}

		return ""

	}
	
	typealias UniCharCount = CUnsignedLong
	/**
	A string representing the “key” part of a shortcut, like the `5` in `⌘5`.
	
	@warning The value may change depending on the active keyboard layout.
	For example for the `^2` keyboard shortcut (`kVK_ANSI_2+NSControlKeyMask`
	to be precise) the `keyCodeString` is `2` on the US keyboard, but `ě` when
	the Czech keyboard layout is active. See the spec for details.
	*/
	/*nonatomic*/ var keyCodeString:NSString {

		// Some key codes don't have an equivalent
		
		switch Int( self.keyCode ) {
			
			case NSNotFound: return ""
			case kVK_F1: return "F1"
			case kVK_F2: return "F2"
			case kVK_F3: return "F3"
			case kVK_F4: return "F4"
			case kVK_F5: return "F5"
			case kVK_F6: return "F6"
			case kVK_F7: return "F7"
			case kVK_F8: return "F8"
			case kVK_F9: return "F9"
			case kVK_F10: return "F10"
			case kVK_F11: return "F11"
			case kVK_F12: return "F12"
			case kVK_F13: return "F13"
			case kVK_F14: return "F14"
			case kVK_F15: return "F15"
			case kVK_F16: return "F16"
			case kVK_F17: return "F17"
			case kVK_F18: return "F18"
			case kVK_F19: return "F19"
			case kVK_Space: return NSLocalizedString(
				"Space",
				comment: "Shortcut glyph name for SPACE key"
			)
			case kVK_Escape: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.Escape.rawValue ) )
			case kVK_Delete: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.DeleteLeft.rawValue ) )
			case kVK_ForwardDelete: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.DeleteRight.rawValue ) )
			case kVK_LeftArrow: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.LeftArrow.rawValue ) )
			case kVK_RightArrow: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.RightArrow.rawValue ) )
			case kVK_UpArrow: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.UpArrow.rawValue ) )
			case kVK_DownArrow: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.DownArrow.rawValue ) )
			case kVK_Help: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.Help.rawValue ) )
			case kVK_PageUp: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.PageUp.rawValue ) )
			case kVK_PageDown: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.PageDown.rawValue ) )
			case kVK_Tab: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.TabRight.rawValue ) )
			case kVK_Return: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.ReturnR2L.rawValue ) )
				
				// Keypad
			case kVK_ANSI_Keypad0: return "0"
			case kVK_ANSI_Keypad1: return "1"
			case kVK_ANSI_Keypad2: return "2"
			case kVK_ANSI_Keypad3: return "3"
			case kVK_ANSI_Keypad4: return "4"
			case kVK_ANSI_Keypad5: return "5"
			case kVK_ANSI_Keypad6: return "6"
			case kVK_ANSI_Keypad7: return "7"
			case kVK_ANSI_Keypad8: return "8"
			case kVK_ANSI_Keypad9: return "9"
			case kVK_ANSI_KeypadDecimal: return "."
			case kVK_ANSI_KeypadMultiply: return "*"
			case kVK_ANSI_KeypadPlus: return "+"
			case kVK_ANSI_KeypadClear: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.PadClear.rawValue ) )
			case kVK_ANSI_KeypadDivide: return "/"
			case kVK_ANSI_KeypadEnter: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.Return.rawValue ) )
			case kVK_ANSI_KeypadMinus: return "–"
			case kVK_ANSI_KeypadEquals: return "="
				
				// Hardcode
			case 119: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.SoutheastArrow.rawValue ) )
			case 115: return NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.NorthwestArrow.rawValue ) )
			default: break
			
		}
		
		// Everything else should be printable so look it up in the current ASCII capable keyboard layout

		var maybe_keystroke:NSString? = keycode_to_str( UInt16( self.keyCode ) )
		
		if !( maybe_keystroke?.length > 0 ) {
				return ""
		}
		
		// Validate keystroke
		
		var keystroke = maybe_keystroke!
		
		for i in 0 ..< keystroke.length {
			
			let char = keystroke.characterAtIndex(i)
			let char_is_valid = MASShortcut.valid_chars.characterIsMember( char )
			if !char_is_valid {
				return ""
			}
			
		}

		// Finally, we've got a shortcut!
		
		return keystroke.uppercaseString;
		
	}
	
	class var valid_chars:NSCharacterSet {
		
		var chars = NSMutableCharacterSet()

		chars.formUnionWithCharacterSet( NSCharacterSet.alphanumericCharacterSet() )
		chars.formUnionWithCharacterSet( NSCharacterSet.punctuationCharacterSet() )
		chars.formUnionWithCharacterSet( NSCharacterSet.symbolCharacterSet() )

		return chars
		
	}

	func keycode_to_str( keyCode:UInt16 ) -> NSString? {

		// Everything else should be printable so look it up in the current ASCII capable keyboard layout
		var error = noErr
		
		var keystroke:NSString? = nil
		
		let inputSource:TISInputSource!
			= TISCopyCurrentASCIICapableKeyboardLayoutInputSource().takeUnretainedValue()
		
		if inputSource == nil {
			return keystroke
		}
		
		let layoutDataRef_ptr = TISGetInputSourceProperty( inputSource, kTISPropertyUnicodeKeyLayoutData)
		var layoutDataRef:CFDataRef! = unsafeBitCast( layoutDataRef_ptr, CFDataRef.self )

		if layoutDataRef == nil {
			return keystroke
		}

		var layoutData
			= unsafeBitCast( CFDataGetBytePtr(layoutDataRef), UnsafePointer<CoreServices.UCKeyboardLayout>.self )
		
		let key_translate_options = OptionBits(CoreServices.kUCKeyTranslateNoDeadKeysBit)
		var deadKeyState = UInt32( 0 )
		let max_chars = 256
		var chars = [UniChar]( count:max_chars, repeatedValue:0 )
		var length = 0
		
		error = CoreServices.UCKeyTranslate(
			layoutData,
			keyCode,
			UInt16( CoreServices.kUCKeyActionDisplay ),
			UInt32( 0 ), // No modifiers
			UInt32( LMGetKbdType() ),
			key_translate_options,
			&deadKeyState,
			max_chars,
			&length,
			&chars
		)
		
		keystroke
			= ( error == noErr ) && ( length > 0 )
			? NSString( characters:&chars, length:length )
			: ""
		
		return keystroke
		
	}
	
	/**
	A string representing the shortcut modifiers, like the `⌘` in `⌘5`.
	*/
	/*nonatomic*/ var modifierFlagsString:String {
		
		var chars = ""
		if contains_flag( self.modifierFlags, NSEventModifierFlags.ControlKeyMask ){
			chars += String(UnicodeScalar( kControlUnicode ))
		}
		if contains_flag( self.modifierFlags, NSEventModifierFlags.AlternateKeyMask ){
			chars += String(UnicodeScalar( kOptionUnicode ))
		}
		if contains_flag( self.modifierFlags, NSEventModifierFlags.ShiftKeyMask ){
			chars += String(UnicodeScalar( kShiftUnicode ))
		}
		if contains_flag( self.modifierFlags, NSEventModifierFlags.CommandKeyMask ){
			chars += String(UnicodeScalar( kCommandUnicode ))
		}
		return chars
		
	}
	
	init( keyCode code:UInt, modifierFlags flags:UInt ){
		
		self._keyCode = code
		self._modifierFlags = MASPickCocoaModifiers( flags )
		
	}
	
	class func shortcutWithKeyCode( code:UInt, modifierFlags flags:UInt ) -> MASShortcut {
		return MASShortcut( keyCode:code, modifierFlags:flags )
	}

	/**
	Creates a new shortcut from an `NSEvent` object.

	This is just a convenience initializer that reads the key code and modifiers from an `NSEvent`.
	*/
	class func shortcutWithEvent( event:NSEvent ) -> MASShortcut {
		return MASShortcut(
			keyCode: UInt( event.keyCode ),
			modifierFlags:event.modifierFlags.rawValue as UInt
		)
	}

	func encodeWithCoder( coder: NSCoder ){
		
		coder.encodeInteger(
			self.keyCode != UInt( NSNotFound )
			? Int( self.keyCode )
			: -1,
			forKey: MASShortcutKeyCode
		)
		coder.encodeInteger(
			Int( self.modifierFlags ),
			forKey: MASShortcutModifierFlags
		)
		
	}

	override func isEqual( object: AnyObject? ) -> Bool {
		if let shortcut = object as? MASShortcut {
			return shortcut.keyCode == self.keyCode
			&& shortcut.modifierFlags == self.modifierFlags
		}
		return false
	}
	
	override var hash:Int {
		return Int( self.keyCode + self.modifierFlags )
	}
	
	required init(coder decoder: NSCoder){ // NS_DESIGNATED_INITIALIZER
		
		let code = decoder.decodeIntegerForKey( MASShortcutKeyCode )
		self._keyCode
			= code < 0
			? UInt( NSNotFound )
			: UInt( code )
		self._modifierFlags = UInt( decoder.decodeIntegerForKey( MASShortcutModifierFlags ) )
		
	}
	
	static func supportsSecureCoding() -> Bool {
		return true
	}
	
	func copyWithZone( zone: NSZone ) -> AnyObject {
		
		return MASShortcut.shortcutWithKeyCode(
			self.keyCode,
			modifierFlags: self.modifierFlags
		)

	}
	
}
