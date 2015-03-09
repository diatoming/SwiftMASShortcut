//
//  MASShortcutView.swift
//  SwiftMASShortcut
//
// See MASShortcut https://github.com/shpakovski/MASShortcut
// This code is a line-by-line port of Vadim Shpakovski's original Obj-C code.
// Ported by charles@charlesism.com
// See https://github.com/shpakovski/MASShortcut for copyright details.
// Vadim's original Obj-C project is going to be more reliable. This Swift version has
// not been tested at length.


//void *kUserDataShortcut = &kUserDataShortcut;
//void *kUserDataHint = &kUserDataHint;
var kUserDataShortcut = NSObject()
var kUserDataHint = NSObject()

import Foundation
import AppKit
import Carbon

@objc enum MASShortcutViewStyle:UInt32 {
	case Default = 0  // Height = 19 px
	case TexturedRect // Height = 25 px
	case Rounded      // Height = 43 px
	case Flat
}

let HINT_BUTTON_WIDTH = 23.0
let BUTTON_FONT_SIZE = 11.0
let SEGMENT_CHROME_WIDTH = 6.0

let MASShortcutBinding = "shortcutValue"

public class MASShortcutView: NSView {
	
	var shortcutValueChange: ((MASShortcutView!) -> Void)! // { get set }
	
	var shortcutCell:NSButtonCell!
	
	var shortcutValidator:MASShortcutValidator!
	
	var _enabled:Bool!
	var enabled:Bool {
		get {
			return self._enabled != nil && self._enabled!
		}
		set( val ){
			if self.enabled == val {
				return
			}
			self._enabled = val
			self.updateTrackingAreas()
			self.recording = false
			self.needsDisplay = true
		}
	}
	
	var showsDeleteButton:Bool=false
	
	var _style:MASShortcutViewStyle! = MASShortcutViewStyle.Default
	var style:MASShortcutViewStyle {
		get {
			return self._style
		}
		set( val ){
			if self._style == val {
				return
			}
			self._style = val
			
			self.resetShortcutCellStyle()
			self.needsDisplay = true
			
		}
	}
		
	var _recording:Bool!
	var recording:Bool {
		get {
			return self._recording != nil && self._recording!
		}
		set( flag ){
			
			// Only one recorder can be active at the moment
			
			struct currentRecorder { static var memory:MASShortcutView!=nil }
			
			if flag && ( currentRecorder.memory != nil ) && ( currentRecorder.memory != self ){
				currentRecorder.memory.recording = false
				currentRecorder.memory = flag ? self : nil
			}
			
			// Only enabled view supports recording
			if flag && !self.enabled {
					return
			}
			
			if self.recording == flag {
				return
			}
			self._recording = flag
			self.shortcutPlaceholder = nil
			self.resetToolTips()
			self.activateEventMonitoring( self._recording )
			self.activateResignObserver( self._recording )
			self.needsDisplay = true
		}
	}
	
	var shortcutToolTipTag:NSToolTipTag! = nil
	var hintToolTipTag:NSToolTipTag! = nil
	
	var _hinting:Bool!
	var hinting:Bool {
		get {
			return self._hinting != nil && self._hinting!
		}
		set( val ){
			if self.hinting == val {
				return
			}
			self._hinting = val
			self.needsDisplay = true
		}
	}
	
	
	var _shortcutPlaceholder:NSString!
	var shortcutPlaceholder:NSString! {
		get {
			return self._shortcutPlaceholder
		}
		set( val ){
			self._shortcutPlaceholder = val //.copy() as! NSString
			self.needsDisplay = true
		}
	}
	
	var hintArea:NSTrackingArea!
	
	override init( frame frameRect: NSRect ) {
		super.init( frame:frameRect )
		self.commonInit()
	}
	
	required public init?(coder: NSCoder) {
		super.init( coder: coder )
		self.commonInit()
	}

	deinit {
		self.activateEventMonitoring( false )
		self.activateResignObserver( false )
	}
	
	func commonInit(){
		
		self.shortcutCell = NSButtonCell() //self.dynamicType.shortcutCellClass() as? NSButtonCell

		self.shortcutCell.setButtonType( NSButtonType.PushOnPushOffButton )
		self.shortcutCell.font
			= NSFontManager.sharedFontManager().convertFont(
				self.shortcutCell.font!,
				toSize: CGFloat( BUTTON_FONT_SIZE )
		)
		self.shortcutValidator = MASShortcutValidator.sharedValidator()
		self.enabled = true
		self.showsDeleteButton = true
		self.resetShortcutCellStyle()
		
	}
	
	class func shortcutCellClass() -> AnyClass! {
		return NSButtonCell.self
	}
	
	// MARK: Public accessors
	
	func resetShortcutCellStyle(){

		switch self.style {
				
			case MASShortcutViewStyle.Default:
				self.shortcutCell.bezelStyle = NSBezelStyle.RoundRectBezelStyle

			case MASShortcutViewStyle.TexturedRect:
				self.shortcutCell.bezelStyle = NSBezelStyle.TexturedRoundedBezelStyle

			case MASShortcutViewStyle.Rounded:
				self.shortcutCell.bezelStyle = NSBezelStyle.RoundedBezelStyle

			case MASShortcutViewStyle.Flat:
				self.wantsLayer = true
				self.shortcutCell.backgroundColor = NSColor.clearColor()
				self.shortcutCell.bordered = false
			
			default:
				break
			
		}
		
		
	}
	
	// MARK: Drawing
	
	public override var flipped:Bool {
		return true
	}
	
	func drawInRect( frame: CGRect, withTitle title: String!, alignment: NSTextAlignment, state: Int) {

		self.shortcutCell.title = title;
		self.shortcutCell.alignment = alignment;
		self.shortcutCell.state = state;
		self.shortcutCell.enabled = self.enabled;

		switch self.style {
			
			case MASShortcutViewStyle.Default:
				self.shortcutCell.drawWithFrame( frame, inView:self )
			case MASShortcutViewStyle.TexturedRect:
				self.shortcutCell.drawWithFrame( CGRectOffset(frame, 0.0, 1.0), inView:self )
			case MASShortcutViewStyle.Rounded:
				self.shortcutCell.drawWithFrame( CGRectOffset(frame, 0.0, 1.0), inView:self )
			case MASShortcutViewStyle.Flat:
				self.shortcutCell.drawWithFrame( frame, inView:self )
			default:
				self.shortcutCell.drawWithFrame( frame, inView:self )

		}
		
	}
	
	override public func drawRect( dirtyRect: NSRect ) {
		
		var shortcutRect: CGRect!
		
		if self.shortcutValue != nil {
		
			var buttonTitle:NSString!
		
			if self.recording {

				buttonTitle = NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.Escape.rawValue ) )
		
			} else if self.showsDeleteButton {

				buttonTitle = NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.Clear.rawValue ) )
				
			}

			if buttonTitle != nil {
				
				self.drawInRect(
					self.bounds,
					withTitle: buttonTitle as String,
					alignment: NSTextAlignment.RightTextAlignment,
					state: NSOffState
				)
				
			}

			var shortcutRect_ptr = UnsafeMutablePointer<CGRect>.alloc(1)
			
			self.getShortcutRect(
				shortcutRect_ptr,
				hintRect: nil
			)
			
			shortcutRect = shortcutRect_ptr.memory
			shortcutRect_ptr.dealloc(1)
			
			let title = ( self.recording
				? ( self.hinting
					? NSLocalizedString(
						"Use Old Shortcut",
						comment: "Cancel action button for non-empty shortcut in recording state"
					)
					: ( self.shortcutPlaceholder != nil && (self.shortcutPlaceholder as NSString).length > 0
						? self.shortcutPlaceholder
						: NSLocalizedString(
							"Type New Shortcut",
							comment: "Non-empty shortcut button in recording state"
						) ) )
				: ( self.shortcutValue != nil ) ? self.shortcutValue.description : "" )
			
			self.drawInRect(
				shortcutRect,
				withTitle: title as String,
				alignment: NSTextAlignment.CenterTextAlignment,
				state: self.recording ? NSOnState : NSOffState
			)
			
		} else {
		
			if self.recording {
				
				self.drawInRect(
					self.bounds,
					withTitle: NSStringFromMASKeyCode( CUnsignedShort( kMASShortcutGlyph.Escape.rawValue ) ),
					alignment: NSTextAlignment.RightTextAlignment,
					state: NSOffState
				)
				
				var shortcutRect:CGRect!

				var shortcutRect_ptr = UnsafeMutablePointer<CGRect>.alloc(1)
				
				self.getShortcutRect(
					shortcutRect_ptr,
					hintRect: nil
				)
				
				shortcutRect = shortcutRect_ptr.memory
				shortcutRect_ptr.dealloc(1)
				
				let title = ( self.hinting
					? NSLocalizedString( "Cancel", comment: "Cancel action button in recording state" )
					: ( self.shortcutPlaceholder != nil && (self.shortcutPlaceholder as NSString).length > 0
						? self.shortcutPlaceholder
						: NSLocalizedString( "Type Shortcut", comment: "Empty shortcut button in recording state" ) ) )
				
				self.drawInRect(
					shortcutRect,
					withTitle: title as String,
					alignment: NSTextAlignment.CenterTextAlignment,
					state: NSOnState
				)
				
			} else {

				self.drawInRect(
					self.bounds,
					withTitle: NSLocalizedString(
						"Record Shortcut", comment: "Empty shortcut button in normal state"
					),
					alignment: NSTextAlignment.CenterTextAlignment,
					state: NSOffState
				)
				
			}
		
		}
		
	}
	
	var _shortcutValue:MASShortcut!
	var shortcutValue:MASShortcut! {
		get {
			return self._shortcutValue // TODO: change to self._shortcutValue
		}
		set( shortcutValue ){
			self._shortcutValue = shortcutValue; // TODO: change to self._shortcutValue
			self.resetToolTips()
			self.needsDisplay = true
			self.propagateValue( value:shortcutValue, forBinding:"shortcutValue" )
			
			if self.shortcutValueChange != nil {
				self.shortcutValueChange( self )
			}
			
		}
	}
	
	// MARK: Mouse handling
	
	@objc func getShortcutRect(
		shortcutRectRef: UnsafeMutablePointer<CGRect>,
		hintRect hintRectRef: UnsafeMutablePointer<CGRect>
	){
	
		var shortcutRect = UnsafeMutablePointer<CGRect>.alloc(1)
		var hintRect = UnsafeMutablePointer<CGRect>.alloc(1)
		
		var hintButtonWidth = CGFloat( HINT_BUTTON_WIDTH )
		
		switch self.style {
			
			case MASShortcutViewStyle.TexturedRect:
				hintButtonWidth += CGFloat( 2.0 )
			case MASShortcutViewStyle.Rounded:
				hintButtonWidth += CGFloat( 3.0 )
			case MASShortcutViewStyle.Flat:
				hintButtonWidth -= CGFloat( 8.0 ) - ( self.shortcutCell.font!.pointSize - CGFloat(BUTTON_FONT_SIZE) )
			default:
				break
			
		}
		
		CGRectDivide(
			self.bounds,
			hintRect,
			shortcutRect,
			hintButtonWidth,
			CGRectEdge.MaxXEdge
		)
		
		if shortcutRectRef != nil {
			shortcutRectRef.memory = shortcutRect.memory
		}
		if hintRectRef != nil {
			hintRectRef.memory = hintRect.memory
		}
		
		shortcutRect.dealloc(1)
		hintRect.dealloc(1)
		
	}
	
	func locationInShortcutRect( location:CGPoint ) -> Bool {
		
		var shortcutRect = UnsafeMutablePointer<CGRect>.alloc(1)
		self.getShortcutRect(
			shortcutRect,
			hintRect: nil
		)
		let contains_point = CGRectContainsPoint( shortcutRect.memory,
			self.convertPoint(
				location,
				fromView: nil
			)
		)
		shortcutRect.dealloc(1)
		return contains_point
	}

	
	func locationInHintRect( location:CGPoint ) -> Bool {
		
		var hintRect = UnsafeMutablePointer<CGRect>.alloc(1)
		self.getShortcutRect(
			nil,
			hintRect: hintRect
		)
		let contains_point = CGRectContainsPoint( hintRect.memory,
			self.convertPoint(
				location,
				fromView: nil
			)
		)
		hintRect.dealloc(1)
		return contains_point
	}
	
	
	override public func mouseDown( event: NSEvent ) {

		if self.enabled {
		
			if self.shortcutValue != nil {
		
				if self.recording {
		
					if self.locationInHintRect( event.locationInWindow ) {
		
						self.recording = false
		
					}
					
				} else {
		
					if self.locationInShortcutRect( event.locationInWindow ) {
		
						self.recording = true
		
					} else {
		
						self.shortcutValue = nil
		
					}
		
				}
		
			} else {
		
				if self.recording {
		
					if self.locationInHintRect( event.locationInWindow ) {
		
						self.recording = false
		
					}
		
				} else {
		
					self.recording = true
		
				}
		
			}
		
		} else {
		
			super.mouseDown( event )
		
		}
		
	}
	
	// MARK: Handling mouse over

	
	
	override public func updateTrackingAreas(){
		
		super.updateTrackingAreas()

		if self.hintArea != nil {
			self.removeTrackingArea( self.hintArea )
			self.hintArea = nil
		}
		
		// Forbid hinting if view is disabled
		if !self.enabled {
			return
		}
		
		var hintRect = UnsafeMutablePointer<CGRect>.alloc(1)
		
		self.getShortcutRect( nil, hintRect:hintRect )
		
		let options
			= NSTrackingAreaOptions.MouseEnteredAndExited
			| NSTrackingAreaOptions.ActiveAlways
			| NSTrackingAreaOptions.AssumeInside
		
		self.hintArea = NSTrackingArea(
			rect: hintRect.memory,
			options: options,
			owner: self,
			userInfo: nil
		)
		
	}

	public override func mouseEntered( event:NSEvent ){
		self.hinting = true
	}
	
	public override func mouseExited( event:NSEvent ){
		self.hinting = false
	}
	
	//
	
	func resetToolTips() {
		
		if self.shortcutToolTipTag != nil && self.shortcutToolTipTag != 0 {
			self.removeToolTip( self.shortcutToolTipTag )
			//,
			self.shortcutToolTipTag = 0
		}
		
		if self.hintToolTipTag != nil && self.hintToolTipTag != 0 {
			self.removeToolTip( self.hintToolTipTag )
			//,
			self.hintToolTipTag = 0
		}
		
		if self.shortcutValue == nil || self.recording || !self.enabled {
			return
		}
		
		var shortcutRect_ptr = UnsafeMutablePointer<CGRect>.alloc(1)
		var hintRect_ptr = UnsafeMutablePointer<CGRect>.alloc(1)
		
		self.getShortcutRect(
			shortcutRect_ptr,
			hintRect: hintRect_ptr
		)
		
		let shortcutRect = shortcutRect_ptr.memory
		let hintRect = hintRect_ptr.memory

		self.shortcutToolTipTag = self.addToolTipRect(
			shortcutRect,
			owner: self,
			userData: &kUserDataShortcut
		)

		self.hintToolTipTag = self.addToolTipRect(
			hintRect,
			owner: self,
			userData: &kUserDataHint
		)
		
		shortcutRect_ptr.dealloc(1)
		hintRect_ptr.dealloc(1)
		
	}
	
	override public func view(
		view: NSView,
		stringForToolTip tag: NSToolTipTag,
		point: NSPoint,
		userData data: UnsafeMutablePointer<Void>
	) -> String {
		
		if data == &kUserDataShortcut {
			return NSLocalizedString(
				"Click to record new shortcut",
				comment: "Tooltip for non-empty shortcut button"
			)
		} else if data == &kUserDataHint {
			return NSLocalizedString(
				"Delete shortcut",
				comment: "Tooltip for hint button near the non-empty shortcut"
			)
		}
		
		return ""

	}
	
	// MARK: Event monitoring

	func activateEventMonitoring( shouldActivate:Bool ) {
		
		struct is_active { static var memory=false }
		
		if is_active.memory == shouldActivate {
			return
		}
		
		is_active.memory = shouldActivate
		
		struct eventMonitor { static var memory:AnyObject!=nil }

		if !shouldActivate {
		
			NSEvent.removeMonitor( eventMonitor.memory )
			return

		}
	
		weak var weakSelf = self
		
		let eventMask = NSEventMask.KeyDownMask | NSEventMask.FlagsChangedMask
		
		eventMonitor.memory = NSEvent.addLocalMonitorForEventsMatchingMask(
			eventMask
		){
			immut_event in

			var event = immut_event
			
			// Create a shortcut from the event

			var shortcut = MASShortcut.shortcutWithEvent( event )

			// If the shortcut is a plain Delete or Backspace, clear the current shortcut and cancel recording
			
			let shortcut_modifier_flags = Int( shortcut.modifierFlags )
			let has_modifier_flags = shortcut_modifier_flags != 0
			let shortcut_keyCode = Int( shortcut.keyCode )
			
			if !has_modifier_flags && ( shortcut_keyCode == kVK_Delete || shortcut_keyCode == kVK_ForwardDelete ) {

				weakSelf?.shortcutValue = nil

				weakSelf?.recording = false

				event = nil

			} else if !has_modifier_flags && shortcut_keyCode == kVK_Escape {

				// If the shortcut is a plain Esc, cancel recording

				weakSelf?.recording = false

				event = nil
				
			} else if ( shortcut.modifierFlags == NSEventModifierFlags.CommandKeyMask.rawValue ) && ( shortcut_keyCode == kVK_ANSI_W || shortcut_keyCode == kVK_ANSI_Q ) {

				// If the shortcut is Cmd-W or Cmd-Q, cancel recording and pass the event through

				weakSelf?.recording = false

			} else {

				// Verify possible shortcut
				if shortcut.keyCodeString.length > 0 {
					
					let is_valid = weakSelf != nil && weakSelf!.shortcutValidator.isShortcutValid( shortcut )
					
					if is_valid {
					
						// Verify that shortcut is not used
						var explanation:NSString? = nil

						let is_already_taken_by_system
							= weakSelf != nil
							&& weakSelf!.shortcutValidator.isShortcutAlreadyTakenBySystem(
									shortcut,
									explanation: &explanation
							)
						
						if is_already_taken_by_system {

							// Prevent cancel of recording when Alert window is key
							weakSelf?.activateResignObserver( false )
							
							weakSelf?.activateEventMonitoring( false )

							let format = NSLocalizedString(
								"The key combination %@ cannot be used",
								comment: "Title for alert when shortcut is already used"
							)
						
							var alert = NSAlert()
					
							alert.alertStyle = NSAlertStyle.CriticalAlertStyle
					
							alert.informativeText = explanation! as String  /* THROWS ERROR!!! */
					
							alert.messageText = NSString( format:format, shortcut ) as? String
							
							alert.addButtonWithTitle( NSLocalizedString(
								"OK",
								comment: "Alert button when shortcut is already used"
							))
							
							alert.runModal()
					
							weakSelf?.shortcutPlaceholder = nil
					
							weakSelf?.activateResignObserver( true )
						
							weakSelf?.activateEventMonitoring( true )
						
						} else {
					
							weakSelf?.shortcutValue = shortcut
					
							weakSelf?.recording = false
					
						}
						
					} else {
					
						// Key press with or without SHIFT is not valid input
						NSBeep()
					
					}
					
				} else {

					// User is playing with modifier keys
					weakSelf?.shortcutPlaceholder = shortcut.modifierFlagsString

				}

			event = nil

		}

		return event

		}
	}
	
	func activateResignObserver( shouldActivate:Bool ) {
		
		struct is_active { static var memory=false }
		
		if is_active.memory == shouldActivate {
			return
		}
		
		is_active.memory = shouldActivate
		
		struct observer { static var memory:AnyObject!=nil }
		
		var notificationCenter = NSNotificationCenter.defaultCenter()
		
		if shouldActivate {
		
			weak var weakSelf = self
		
			observer.memory
				= notificationCenter.addObserverForName(
					
					NSWindowDidResignKeyNotification,
					object: self.window,
					queue: NSOperationQueue.mainQueue()
				) {
					notification in
					weakSelf?.recording = false
				}
			
		} else {

			notificationCenter.removeObserver( observer.memory )

		}
		
	}
	
	// MARK: Bindings
	
	// http://tomdalling.com/blog/cocoa/implementing-your-own-cocoa-bindings/
	@objc func propagateValue( value v: AnyObject!, forBinding binding: String! ){
		
		var value:AnyObject! = v
		
		assert( binding != nil )

		// WARNING: bindingInfo contains NSNull, so it must be accounted for
		
		let bindingInfo = self.infoForBinding( binding )
		
		if bindingInfo == nil {
			return //there is no binding
		}

		// apply the value transformer, if one has been set
		
		let maybe_bindingOptions = bindingInfo![NSOptionsKey] as? NSDictionary
		
		if let bindingOptions = maybe_bindingOptions {
		
			var transformer
				= bindingOptions.valueForKey( NSValueTransformerBindingOption ) as? NSValueTransformer
			
			if transformer != nil {

				if let transformerName
					= bindingOptions.valueForKey( NSValueTransformerNameBindingOption ) as? String {
					
					transformer = NSValueTransformer( forName:transformerName )
						
				}
				
			}
			
			if transformer != nil {
				
				if transformer!.dynamicType.allowsReverseTransformation() {

					value = transformer!.reverseTransformedValue( value )
					
				} else {
					
					println( "WARNING: binding \"\(binding)\" has value transformer, but it doesn't allow reverse transformations in \(__FUNCTION__)" )

				}
				
			}
		
		}
		
		var boundObject: AnyObject? = bindingInfo![NSObservedObjectKey]
		
		if boundObject == nil {

			println( "ERROR: NSObservedObjectKey was nil for binding \"\(binding)\" in \(__FUNCTION__)" )
			return
			
		}
		
		var boundKeyPath = bindingInfo![NSObservedKeyPathKey] as? String
		
		if( boundKeyPath == nil ){
		
			println( "ERROR: NSObservedKeyPathKey was nil for binding \"\(binding)\" in \(__FUNCTION__)" )
			return
		}
		
		boundObject!.setValue( value, forKeyPath:boundKeyPath! )
		
	}

}
