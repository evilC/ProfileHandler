/*
Taking the example further - using a second section to Profilize a custom Hotkey GuiControl
*/
#SingleInstance force
OutputDebug, DBGVIEWCLEAR
#include ProfileHandler.ahk
#Include <HotClass>						; https://github.com/evilC/HotClass

mc := new MyClass()
return

GuiClose:
	ExitApp

class MyClass {
	__New(){
		this.ph := new ProfileHandler()	; Cause the GuiControls to be added for the ProfileHandler, but do not Initialize yet
		this.ph.SetPreLoadCallback(this.PreProfileLoad.Bind(this))
		this.ph.SetPostLoadCallback(this.PostProfileLoad.Bind(this))
		;this.HotClass := new HotClass({disablejoystickhats: 1, OnChangeCallback: this.HkChanged.Bind(this)})	; Disabling Joystick Hats stops the SetTimer interfering with debugging
		this.HotClass := new HotClass({OnChangeCallback: this.HkChanged.Bind(this)})
		
		; PerProfileGuiControls are Objects which we wish to have handled by the ProfileHandler on a Per-Profile basis
		this.PerProfileGuiControls := {}
		; MyEdit is a Profile dependant Edit GuiControl.
		Gui, Add, Text, w100 xm yp+40, Per-Profile EditBox
		this.PerProfileGuiControls.MyEdit := new PersistentGuiControl(this.MyEditChanged.Bind(this), "Edit", "xp+100 yp-3 w200",, "Some Default Text")
		
		; GlobalGuiControls are Objects which we wish to have handled by the ProfileHandler, but are not affected by current profile
		this.GlobalGuiControls := {}
		; MyCheck is a Global (Not Profile dependant) GuiControl
		this.GlobalGuiControls.MyCheck := new PersistentGuiControl(this.MyCheckChanged.Bind(this), "CheckBox", "xm", "Global CheckBox (Not affected by Current Profile)", "1")
		
		this.HotClass.DisableHotkeys()
		this.Hotkeys := {}
		Loop 1 {
			name := "hk" A_Index
			Gui, Add, Text, w100 xm yp+30, Per-Profile Hotkey
			this.Hotkeys[name] := this.HotClass.AddHotkey(name, this.hkPressed.Bind(this, A_Index), "w200 xp+100 yp-2")
		}
		this.ph.Init({PerProfile: {GuiControls: this.PerProfileGuiControls, Hotkeys: this.Hotkeys}, Global: {GuiControls: this.GlobalGuiControls}})
		Gui, Show, x0 y0
		
		this.HotClass.EnableHotkeys()
	}
	
	; Put HotClass into IDLE state before loading hotkeys
	PreProfileLoad(){
		this.HotClass.DisableHotkeys()
	}
	
	; Put HotClass into ACTIVE state after loading hotkeys
	PostProfileLoad(){
		this.HotClass.EnableHotkeys()
	}
	
	hkPressed(idx, event){
		ToolTip % "HK " idx ": " event
	}
	
	HkChanged(aParams*){
		this.ph.SettingChanged()
	}
	
	; Called when the contents of the Edit Box changes. This should happen in the following cases:
	; The Editbox changes through user interaction
	; The profile changes (including once at the start)
	MyEditChanged(){
		;ToolTip % "MyEdit Value: " this.PerProfileGuiControls.MyEdit.value
		this.ph.SettingChanged()	; Let ProfileHandler know that something changed
	}
	
	; Called when the state of the CheckBox changes. This should happen in the following cases:
	; The CheckBox changes through user interaction
	; Once at the start of the script
	MyCheckChanged(){
		this.ph.SettingChanged()	; Let ProfileHandler know that something changed
	}
}

; ========================= GuiControl Wrapper ===================================
/*
This wraps GuiControls in a manner suitable for use with the ProfileHandler

It ensures that any get or set of the .value property sets or gets the contents of the GuiControl
First param specifies the "g-label" to call when the GuiControl changes through user interaction
Next, it accepts the normal params as would be used in a Gui, Add command (eg ControlType, Options, Text)
Next, it accepts a "Default" param to specify the Default Value
*/
class PersistentGuiControl {
	__New(callback, ctrltype, options := "", text := "", Default := ""){
		this._PHDefaultValue := Default ; This property will be expected by the ProfileHandler class, and should contain the Default Value
		this._callback := callback
		Gui, Add, % ctrltype, % options " hwndhwnd", % text
		this.hwnd := hwnd
		fn := this.ControlChanged.Bind(this)
		GuiControl +g, % hwnd, % fn
	}
	
	; The control changed state either through user interaction, or through change of profile
	ControlChanged(){
		GuiControlGet, val, , % this.hwnd
		this._value := val
		this._callback.()
	}
	
	; Getters and Setters.
	; Trap Gets or sets of .value, and re-route to ._value
	; On Set of .value, also change state of GuiControl
	value[]{
		get {
			return this._value
		}
		
		set {
			GuiControl,, % this.hwnd, % value
			return this._value := value
		}
	}
}
