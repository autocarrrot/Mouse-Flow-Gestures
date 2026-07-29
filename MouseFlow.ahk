#Requires AutoHotkey v2.0
#SingleInstance Force

; ==============================================================================
;    MOUSE FLOW GESTURES
;    Mouse gestures, virtual desktops and window management for Windows 10/11
; ==============================================================================
;
;  HOW GESTURES WORK
;    NAVIGATION - switch desktop, task view, skip track - fires the instant you
;    cross the 40px threshold. Nothing to wait for.
;
;    WINDOW ACTIONS - move, pin, snap, show desktop - ARM at the threshold and
;    FIRE when you release, with an OSD showing what will happen:
;       drag back to the centre .......... cancels
;       press Esc while holding .......... cancels
;       press / release Shift mid-swipe .. switches to the Shift action live
;
;    Which is which is the InstantActions list in SETTINGS.
;
; ------------------------------------------------------------------------------
;  MIDDLE MOUSE
;    click ................ normal middle click
;    swipe left ........... switch to the desktop on the RIGHT
;    swipe right .......... switch to the desktop on the LEFT
;    swipe up / down ...... task view
;
;  MB5 / FRONT SIDE BUTTON   (copy + media)
;    click ................ copy
;    swipe left ........... next track
;    swipe right .......... previous track
;    SHIFT + swipe left ... snap window to the left half
;    SHIFT + swipe right .. snap window to the right half
;    SHIFT + swipe up ..... maximise
;    SHIFT + swipe down ... minimise
;    hold + scroll ........ volume up / down
;    hold + click MB4 ..... play / pause
;
;  MB4 / BACK SIDE BUTTON    (paste + windows)
;    click ................ paste
;    swipe left ........... move window to the previous desktop AND follow it
;    swipe right .......... move window to the next desktop AND follow it
;    SHIFT + swipe left ... send window to the previous desktop, STAY here
;    SHIFT + swipe right .. send window to the next desktop, STAY here
;    swipe up ............. pin / unpin window (visible on all desktops)
;    swipe down ........... show desktop
;    hold + scroll ........ switch tabs (Ctrl+Tab)
;    hold + click MB5 ..... play / pause
;
;  KEYBOARD
;    Win+Ctrl+Shift+Left .. move window to the previous desktop
;    Win+Ctrl+Shift+Right . move window to the next desktop. Double tap the
;                           shortcut to create a fresh desktop and move there.
;    Win+1 .. Win+9, Win+0  jump straight to that desktop
;    1 .. 9, 0 in Task View jump to that desktop and close Task View
;    Ctrl+Alt+Shift+X ..... open the RULES PANEL for the current app
;    Ctrl+Alt+Shift+E ..... show + copy the active window's exe name
;
; ------------------------------------------------------------------------------
;  TURNING THINGS OFF PER APP
;    With the app focused, press Ctrl+Alt+Shift+X. A panel lists every feature
;    as a tickbox - ticked means it works in that app. Untick what gets in the
;    way. Saved instantly, no reload. The top tickbox switches the whole script
;    off for that app. Esc or the same hotkey closes it.
;
;    Those two hotkeys sit outside every context check on purpose, so they
;    still work inside an app where you have disabled everything else.
;
;    The BlockIn map below does the same thing by hand, and OnlyIn is the
;    inverse - a feature that works ONLY in the apps you list.
;
;  SETTINGS
;    OSD on/off, create-desktop-at-the-end and wrap-around live at the bottom
;    of the rules panel. Thresholds and timings are in the SETTINGS block.
;    Everything persists to a .ini sitting next to this script.
;
;  IF NOTHING WORKS IN TASK MANAGER / INSTALLERS
;    Those windows are elevated, so an unelevated script cannot touch them.
;    Run this as admin - cleanest via a Task Scheduler task at logon with
;    "run with highest privileges".
; ==============================================================================

#Include VirtualDesktop.ah2

ListLines(false)              ; hot path runs on a 10ms timer, skip the logging
SendMode("Input")             ; the fastest send method
SetKeyDelay(-1, -1)
SetWinDelay(-1)
CoordMode("Mouse", "Screen")  ; MouseGetPos must be screen-relative for the OSD

; ==============================================================================
;    0. APP RULES
; ==============================================================================
; BlockIn -> the feature works everywhere EXCEPT these apps.
; "GLOBAL" is the master switch: listed apps get the whole script disabled.
; The .ini written by the rules panel overrides whatever is set here.

global BlockIn := Map(
    "GLOBAL",        [],                  ; e.g. ["valorant.exe"]

    ; middle mouse
    "MiddleButton",  ["blender.exe"],     ; master switch for the MMB hook
    "DesktopSwipe",  [],                  ; MMB swipe L/R
    "TaskView",      [],                  ; MMB swipe U/D

    ; side buttons
    "CopyPaste",     [],                  ; MB5 click / MB4 click
    "MediaSwipe",    [],                  ; MB5 swipe
    "WindowSnap",    [],                  ; SHIFT + MB5 swipe
    "Volume",        [],                  ; MB5 hold + scroll
    "PlayPause",     [],                  ; MB4 + MB5 chord
    "TabSwitch",     [],                  ; MB4 hold + scroll
    "WindowMove",    [],                  ; MB4 swipe L/R
    "PinWindow",     [],                  ; MB4 swipe up
    "ShowDesktop",   [],                  ; MB4 swipe down

    ; keyboard
    "KeyboardVD",    [],                  ; Win+Ctrl+Shift+arrows
    "WinNumber",     [],                  ; Win+1..0
    "TaskViewNums",  []                   ; 1..0 inside task view
)

; A feature listed here works ONLY in the listed apps.
; Example: global OnlyIn := Map("TabSwitch", ["chrome.exe", "msedge.exe"])
global OnlyIn := Map()

; ==============================================================================
;    1. SETTINGS
; ==============================================================================
global ConfigFile        := A_ScriptDir "\" RegExReplace(A_ScriptName, "\.ahk$", "") ".ini"
global MoveThreshold     := 40      ; px of travel before a swipe triggers
global ActionCooldown    := 220     ; ms minimum between desktop actions
global OSDEnabled        := true    ; on-screen readout
global AutoCreateDesktop := true    ; swiping past the last desktop creates one
global WrapDesktops      := false   ; ...or wraps around (only if the above is off)
global RepeatSwipes      := false   ; true = keep holding and swipe again to
                                    ; repeat an instant action, without re-clicking
global AutoElevate       := false   ; true = relaunch as admin, UAC prompt every
                                    ; boot. Task Scheduler is the better route.

; Copy normally fires on the release of MB5, which is what makes a click a click.
; Set this to true to fire it on the PRESS instead - the absolute fastest it can
; be. The catch: MB5 is also the modifier for volume, media and snapping, so
; every one of those will overwrite your clipboard if something is selected.
global CopyOnPress       := false

; Actions that fire the moment you cross the threshold, with no preview and no
; OSD. Navigation is instant; anything that manipulates a window waits for the
; release so you get a preview and a chance to back out. Move ids in or out.
global InstantActions := ["vd_left", "vd_right", "taskview", "media_prev", "media_next"]

; ==============================================================================
;    2. STATE
; ==============================================================================
global StartX := 0, StartY := 0
global GestureExe := ""              ; exe that was focused when the gesture began
global GestureBtn := ""              ; button that owns the gesture in flight
global Armed := ""                   ; action id currently armed
global Cancelled := false
global LastActionTime := 0
global LastCreatedDesktopNum := 0
global ExeCache := "", ExeCacheTime := 0
global OSD := "", OSDText := "", OSDVisible := false
global OSDW := 300, OSDH := 52
global RulePanel := "", RuleExe := "", RuleBoxes := Map(), RuleMaster := ""

; ==============================================================================
;    3. STARTUP
; ==============================================================================
if (AutoElevate && !A_IsAdmin) {
    try Run '*RunAs "' A_ScriptFullPath '"'
    ExitApp
}

LoadConfig()
InitOSD()
BuildTray()
A_IconTip := "Mouse Flow Gestures"

; ==============================================================================
;    4. RULE ENGINE
; ==============================================================================

; Cached for 50ms. One hotkey press evaluates #HotIf more than once and
; WatchMouse runs every 10ms, so this keeps the OS calls off the hot path.
ActiveExe() {
    global ExeCache, ExeCacheTime
    if (ExeCacheTime && A_TickCount - ExeCacheTime < 50)
        return ExeCache
    exe := ""
    try exe := WinGetProcessName("A")
    ExeCache := exe, ExeCacheTime := A_TickCount
    return exe
}

InList(list, value) {
    if (value = "")
        return false
    for item in list
        if (item = value)                ; "=" is case-insensitive
            return true
    return false
}

IsEnabledFor(feature, exe) {
    global BlockIn, OnlyIn
    if (feature = "" || exe = "")
        return true
    if (BlockIn.Has("GLOBAL") && InList(BlockIn["GLOBAL"], exe))
        return false
    if (OnlyIn.Has(feature) && OnlyIn[feature].Length && !InList(OnlyIn[feature], exe))
        return false
    if (BlockIn.Has(feature) && InList(BlockIn[feature], exe))
        return false
    return true
}

IsEnabled(feature) {
    return IsEnabledFor(feature, ActiveExe())
}

AnyEnabled(features*) {
    exe := ActiveExe()
    for f in features
        if IsEnabledFor(f, exe)
            return true
    return false
}

; Rate limit, so one slow swipe cannot fire twice
CanFire(ms := 0) {
    global LastActionTime, ActionCooldown
    gap := ms ? ms : ActionCooldown
    if (A_TickCount - LastActionTime < gap)
        return false
    LastActionTime := A_TickCount
    return true
}

; Send with a physically held Shift dropped first, otherwise a Shift+swipe
; turns Win+Left into Win+Shift+Left (throws the window to the next monitor)
; and Ctrl+Win+Left into the move-window-to-desktop shortcut.
SendA(keys) {
    if GetKeyState("Shift", "P")
        Send("{Shift up}")
    Send(keys)
}

; ==============================================================================
;    5. OSD
; ==============================================================================

InitOSD() {
    global OSD, OSDText, OSDW, OSDH
    OSD := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
    OSD.BackColor := "1C1C1C"
    OSD.MarginX := 0, OSD.MarginY := 0
    OSD.SetFont("s12 Bold cE8E8E8", "Segoe UI")
    OSDText := OSD.Add("Text", "Center x0 y16 w" OSDW " h" (OSDH - 16), "")
}

MonitorUnderMouse(&L, &T, &R, &B) {
    MouseGetPos(&mx, &my)
    Loop MonitorGetCount() {
        MonitorGetWorkArea(A_Index, &l1, &t1, &r1, &b1)
        if (mx >= l1 && mx < r1 && my >= t1 && my < b1) {
            L := l1, T := t1, R := r1, B := b1
            return
        }
    }
    MonitorGetWorkArea(MonitorGetPrimary(), &L, &T, &R, &B)
}

ShowOSDText(txt) {
    global OSD, OSDText, OSDW, OSDH, OSDEnabled, OSDVisible
    if (!OSDEnabled || txt = "")
        return
    SetTimer(HideOSD, 0)
    OSDText.Value := txt
    MonitorUnderMouse(&L, &T, &R, &B)
    x := L + (R - L - OSDW) // 2
    y := B - (B - T) // 6 - OSDH
    OSD.Show("NoActivate x" x " y" y " w" OSDW " h" OSDH)
    WinSetTransparent(230, "ahk_id " OSD.Hwnd)
    OSDVisible := true
}

ShowOSDFor(txt, ms := 1200) {
    ShowOSDText(txt)
    SetTimer(HideOSD, -ms)
}

HideOSD() {
    global OSD, OSDVisible
    SetTimer(HideOSD, 0)
    if !OSDVisible                       ; never touch the window needlessly
        return
    OSDVisible := false
    try OSD.Hide()
}

; ==============================================================================
;    6. ACTIONS
; ==============================================================================
; Every gesture resolves to an action id. Each id maps to a feature (for the
; per-app rules), a label (for the OSD) and a body (in RunAction).

ActionFeature(id) {
    switch id {
        case "vd_left", "vd_right":                 return "DesktopSwipe"
        case "taskview":                            return "TaskView"
        case "media_prev", "media_next":            return "MediaSwipe"
        case "snap_left", "snap_right",
             "snap_max", "snap_min":                return "WindowSnap"
        case "move_prev", "move_next",
             "move_prev_stay", "move_next_stay":    return "WindowMove"
        case "pin":                                 return "PinWindow"
        case "showdesktop":                         return "ShowDesktop"
    }
    return ""
}

DesktopLabel(n) {
    name := ""
    try name := VD.getDesktopName(n)
    if (name = "" || name = "Desktop " n)
        return "Desktop " n
    return n " - " name
}

; Where a +/-1 move would land, as text
NeighbourLabel(delta) {
    global AutoCreateDesktop, WrapDesktops
    try {
        n := VD.getCurrentDesktopNum()
        count := VD.getCount()
        target := n + delta
        if (target < 1)
            return WrapDesktops ? DesktopLabel(count) : "-"
        if (target > count) {
            if (AutoCreateDesktop)
                return "New desktop"
            return WrapDesktops ? DesktopLabel(1) : "-"
        }
        return DesktopLabel(target)
    }
    return "Desktop"
}

ActionLabel(id) {
    switch id {
        case "vd_left":         return "<  " NeighbourLabel(-1)
        case "vd_right":        return NeighbourLabel(1) "  >"
        case "taskview":        return "Task View"
        case "media_prev":      return "<<  Previous track"
        case "media_next":      return "Next track  >>"
        case "snap_left":       return "Snap left"
        case "snap_right":      return "Snap right"
        case "snap_max":        return "Maximise"
        case "snap_min":        return "Minimise"
        case "move_prev":       return "<  Move to " NeighbourLabel(-1)
        case "move_next":       return "Move to " NeighbourLabel(1) "  >"
        case "move_prev_stay":  return "Send to " NeighbourLabel(-1) " (stay)"
        case "move_next_stay":  return "Send to " NeighbourLabel(1) " (stay)"
        case "pin":             return IsPinned() ? "Unpin window" : "Pin to all desktops"
        case "showdesktop":     return "Show desktop"
    }
    return ""
}

RunAction(id) {
    switch id {
        case "vd_left":
            if CanFire()
                SendA("^#{Left}")
        case "vd_right":
            if CanFire()
                SendA("^#{Right}")
        case "taskview":        SendA("#{Tab}")
        case "media_prev":      SendA("{Media_Prev}")
        case "media_next":      SendA("{Media_Next}")
        case "snap_left":       SendA("#{Left}")
        case "snap_right":      SendA("#{Right}")
        case "snap_max":        SendA("#{Up}")
        case "snap_min":        SendA("#{Down}")
        case "move_next":       MoveWindowDesktop(1, true)
        case "move_prev":       MoveWindowDesktop(-1, true)
        case "move_next_stay":  MoveWindowDesktop(1, false)
        case "move_prev_stay":  MoveWindowDesktop(-1, false)
        case "pin":             TogglePin()
        case "showdesktop":     SendA("#d")
    }
}

MoveWindowDesktop(delta, follow) {
    global AutoCreateDesktop, WrapDesktops
    if !CanFire(300)
        return
    hwnd := WinActive("A")
    if !hwnd
        return
    try {
        n := VD.getCurrentDesktopNum()
        count := VD.getCount()
        target := n + delta

        if (target < 1) {
            if !WrapDesktops
                return
            target := count
        } else if (target > count) {
            if (AutoCreateDesktop) {
                VD.createDesktop(false)
                target := VD.getCount()
            } else if (WrapDesktops) {
                target := 1
            } else
                return
        }

        VD.MoveWindowToDesktopNum(hwnd, target)
        if (follow)
            VD.goToDesktopNum(target)
        else
            ShowOSDFor("Sent to " DesktopLabel(target), 1200)
    } catch as e {
        ShowOSDFor("Desktop error: " e.Message, 1500)
    }
}

IsPinned() {
    hwnd := WinActive("A")
    if !hwnd
        return false
    try return VD.IsWindowPinned(hwnd)
    return false
}

TogglePin() {
    hwnd := WinActive("A")
    if !hwnd
        return
    try {
        if (VD.IsWindowPinned(hwnd)) {
            VD.UnPinWindow(hwnd)
            ShowOSDFor("Unpinned", 1200)
        } else {
            VD.PinWindow(hwnd)
            ShowOSDFor("Pinned to all desktops", 1200)
        }
    } catch as e {
        ShowOSDFor("Pin failed: " e.Message, 1500)
    }
}

; ==============================================================================
;    7. GESTURE ENGINE
; ==============================================================================

StartGesture(btn) {
    global StartX, StartY, GestureExe, GestureBtn, Armed, Cancelled
    MouseGetPos(&StartX, &StartY)
    GestureExe := ActiveExe()
    GestureBtn := btn
    Armed      := ""
    Cancelled  := false
    SetTimer(WatchMouse, 10)
}

; The owner check matters: if you chord MB4 while MB5 is held and then release
; them in the wrong order, the release of a button that never started a gesture
; must not fall through to its click action.
;
; The click path is deliberately the shortest one through this function - there
; is nothing between the check and the Send, so copy and paste stay snappy.
EndGesture(btn, clickAction) {
    global Armed, GestureBtn, Cancelled
    SetTimer(WatchMouse, 0)
    action := Armed
    owner  := GestureBtn
    wasCancelled := Cancelled
    Armed := "", GestureBtn := "", Cancelled := false

    if (owner != btn || wasCancelled)
        return
    if (action = "") {
        clickAction.Call()
        return
    }
    HideOSD()
    RunAction(action)
}

; Which direction maps to which action, per button, with and without Shift
DirAction(btn, dir, shift) {
    global GestureExe
    id := ""
    if (btn = "MButton") {
        if (dir = "R")
            id := "vd_left"                     ; swipe right -> desktop on the left
        else if (dir = "L")
            id := "vd_right"
        else
            id := "taskview"
    }
    else if (btn = "XButton2") {
        if (shift)
            id := (dir = "L") ? "snap_left"
                : (dir = "R") ? "snap_right"
                : (dir = "U") ? "snap_max" : "snap_min"
        else
            id := (dir = "R") ? "media_prev"
                : (dir = "L") ? "media_next" : ""
    }
    else if (btn = "XButton1") {
        if (dir = "R")
            id := shift ? "move_next_stay" : "move_next"
        else if (dir = "L")
            id := shift ? "move_prev_stay" : "move_prev"
        else if (dir = "U")
            id := "pin"
        else
            id := "showdesktop"
    }
    if (id != "" && !IsEnabledFor(ActionFeature(id), GestureExe))
        return ""
    return id
}

WatchMouse() {
    global StartX, StartY, MoveThreshold
    global Armed, GestureBtn, Cancelled, InstantActions, RepeatSwipes

    if (GestureBtn = "" || !GetKeyState(GestureBtn, "P")) {
        SetTimer(WatchMouse, 0)
        return
    }

    ; Esc while still holding aborts the whole gesture
    if GetKeyState("Escape", "P") {
        Cancelled := true
        Armed := ""
        SetTimer(WatchMouse, 0)
        ShowOSDFor("Cancelled", 800)
        return
    }

    MouseGetPos(&cx, &cy)
    dx := cx - StartX, dy := cy - StartY
    nextAction := ""

    if (Abs(dx) >= MoveThreshold || Abs(dy) >= MoveThreshold) {
        dir := (Abs(dx) > Abs(dy)) ? (dx > 0 ? "R" : "L") : (dy > 0 ? "D" : "U")
        nextAction := DirAction(GestureBtn, dir, GetKeyState("Shift", "P"))
    }

    if (nextAction = Armed)
        return

    Armed := nextAction

    if (Armed = "") {
        HideOSD()
    } else if (InList(InstantActions, Armed)) {
        action := Armed
        Armed := ""
        Cancelled := true                ; the release must not click as well
        HideOSD()
        if (RepeatSwipes)
            StartX := cx, StartY := cy   ; ratchet: swipe again without releasing
        else
            SetTimer(WatchMouse, 0)
        RunAction(action)
    } else {
        ShowOSDText(ActionLabel(Armed))
    }
}

; ==============================================================================
;    8. MOUSE HOTKEYS
; ==============================================================================
; The "*" prefix is required so gestures still fire while Shift is held. Every
; variant of a button carries it, so they stay variants of one hotkey.
;
; The !GetKeyState(other button) guards keep the chord variants and the plain
; variants mutually exclusive, so the order of these blocks never matters.

; --- Middle mouse ---
#HotIf IsEnabled("MiddleButton") && AnyEnabled("DesktopSwipe", "TaskView")
*MButton::      StartGesture("MButton")
*MButton Up::   EndGesture("MButton", MMBClick)
#HotIf

MMBClick() {
    Send("{MButton}")
}

; --- Front side button, MB5 ---
#HotIf !GetKeyState("XButton1", "P") && AnyEnabled("CopyPaste", "MediaSwipe", "WindowSnap", "Volume", "PlayPause")
*XButton2:: {
    global CopyOnPress, GestureExe
    StartGesture("XButton2")
    if (CopyOnPress && IsEnabledFor("CopyPaste", GestureExe))
        SendA("^c")
}
*XButton2 Up::  EndGesture("XButton2", MB5Click)
#HotIf

; GestureExe was resolved when the button went down, so this does no OS calls.
MB5Click() {
    global GestureExe, CopyOnPress
    if IsEnabledFor("CopyPaste", GestureExe) {
        if !CopyOnPress
            SendA("^c")
    } else
        Send("{XButton2}")               ; let the app have its native button
}

; --- Back side button, MB4 ---
#HotIf !GetKeyState("XButton2", "P") && AnyEnabled("CopyPaste", "TabSwitch", "WindowMove", "PinWindow", "ShowDesktop", "PlayPause")
*XButton1::     StartGesture("XButton1")
*XButton1 Up::  EndGesture("XButton1", MB4Click)
#HotIf

MB4Click() {
    global GestureExe
    if IsEnabledFor("CopyPaste", GestureExe)
        SendA("^v")
    else
        Send("{XButton1}")               ; browser Back, etc.
}

; --- MB5 held: chord and volume ---
#HotIf GetKeyState("XButton2", "P") && IsEnabled("PlayPause")
*XButton1:: {
    global Cancelled := true             ; cancel MB5's click action
    SendA("{Media_Play_Pause}")
}
*XButton1 Up:: return
#HotIf

#HotIf GetKeyState("XButton2", "P") && !GetKeyState("XButton1", "P") && IsEnabled("Volume")
WheelUp:: {
    global Cancelled := true
    SendA("{Volume_Up}")
}
WheelDown:: {
    global Cancelled := true
    SendA("{Volume_Down}")
}
#HotIf

; --- MB4 held: chord and tab switching ---
#HotIf GetKeyState("XButton1", "P") && IsEnabled("PlayPause")
*XButton2:: {
    global Cancelled := true
    SendA("{Media_Play_Pause}")
}
*XButton2 Up:: return
#HotIf

#HotIf GetKeyState("XButton1", "P") && !GetKeyState("XButton2", "P") && IsEnabled("TabSwitch")
WheelUp:: {
    global Cancelled := true
    SendA("^+{Tab}")
}
WheelDown:: {
    global Cancelled := true
    SendA("^{Tab}")
}
#HotIf

; ==============================================================================
;    9. KEYBOARD HOTKEYS
; ==============================================================================

#HotIf IsEnabled("KeyboardVD")

#^+Left:: {
    global LastCreatedDesktopNum
    LastCreatedDesktopNum := 0
    try {
        n := VD.getCurrentDesktopNum()
        if (n == 1)
            return
        n -= 1
        VD.MoveWindowToDesktopNum(WinActive("A"), n)
        VD.goToDesktopNum(n)
    }
}

#^+Right:: {
    global LastCreatedDesktopNum
    try {
        ; double tap -> always make a fresh desktop
        if (A_PriorHotkey == A_ThisHotkey && A_TimeSincePriorHotkey < 400) {
            VD.createDesktop(false)
            n := VD.getCount()
            VD.MoveWindowToDesktopNum(WinActive("A"), n)
            VD.goToDesktopNum(n)
            LastCreatedDesktopNum := n
            return
        }
        n := VD.getCurrentDesktopNum()
        if (n == LastCreatedDesktopNum)
            return
        LastCreatedDesktopNum := 0
        count := VD.getCount()
        if (n < count) {
            n += 1
        } else if (n == count) {
            VD.createDesktop(false)
            n += 1
            LastCreatedDesktopNum := n
        }
        VD.MoveWindowToDesktopNum(WinActive("A"), n)
        VD.goToDesktopNum(n)
    }
}

#HotIf

; ==============================================================================
;    10. DIRECT DESKTOP SWITCHING
; ==============================================================================

SwitchToDesktopSafe(targetDesktopNum) {
    try {
        count := VD.getCount()
        if (targetDesktopNum > count)
            targetDesktopNum := count        ; fall back to the last one that exists
        VD.goToDesktopNum(targetDesktopNum)
    }
}

TaskViewSwitch(targetDesktopNum) {
    SwitchToDesktopSafe(targetDesktopNum)
    Send("{Esc}")
}

; --- Win + number ---
WinNumberActive(*) {
    return IsEnabled("WinNumber")
}

HotIf WinNumberActive
    Loop 10 {
        i := A_Index
        dNum := (i == 10) ? 10 : i
        Hotkey "#" . ((i == 10) ? "0" : i), ((n, *) => SwitchToDesktopSafe(n)).Bind(dNum)
    }
HotIf

; --- Numbers inside Task View ---
IsTaskViewActive(*) {
    if !IsEnabled("TaskViewNums")
        return false
    try return WinActive(VD._getLocalizedWord_TaskView()) || WinActive("ahk_class MultitaskingViewFrame")
    return false
}

HotIf IsTaskViewActive
    Loop 10 {
        i := A_Index
        dNum := (i == 10) ? 10 : i
        Hotkey ((i == 10) ? "0" : String(i)), ((n, *) => TaskViewSwitch(n)).Bind(dNum)
    }
HotIf

; ==============================================================================
;    11. RULES PANEL
; ==============================================================================
; The hotkey fires while the target app is still focused, so the panel always
; knows which app it is editing. Nothing to guess at.

global FeatureLabels := Map(
    "GLOBAL",        "Enable Mouse Flow in this app",
    "MiddleButton",  "All middle-button gestures",
    "DesktopSwipe",  "Swipe L/R: switch desktop",
    "TaskView",      "Swipe U/D: task view",
    "MediaSwipe",    "Swipe: prev / next track",
    "WindowSnap",    "Shift+swipe: snap window",
    "Volume",        "Hold + scroll: volume",
    "TabSwitch",     "Hold + scroll: switch tabs",
    "WindowMove",    "Swipe L/R: move to desktop",
    "PinWindow",     "Swipe up: pin window",
    "ShowDesktop",   "Swipe down: show desktop",
    "CopyPaste",     "Click: copy / paste",
    "PlayPause",     "MB4+MB5: play / pause",
    "KeyboardVD",    "Win+Ctrl+Shift+arrows",
    "WinNumber",     "Win + number",
    "TaskViewNums",  "Numbers in task view"
)

; title, features, column (1 = left, 2 = right)
global FeatureGroups := [
    ["Middle mouse",            ["MiddleButton", "DesktopSwipe", "TaskView"], 1],
    ["Front side button (MB5)", ["MediaSwipe", "WindowSnap", "Volume"], 1],
    ["Both side buttons",       ["CopyPaste", "PlayPause"], 1],
    ["Back side button (MB4)",  ["TabSwitch", "WindowMove", "PinWindow", "ShowDesktop"], 2],
    ["Keyboard",                ["KeyboardVD", "WinNumber", "TaskViewNums"], 2]
]

; Both of these live outside every #HotIf block on purpose, so they still work
; in an app where everything else has been switched off.
^!+x:: OpenRulePanel()

^!+e:: {
    exe := ActiveExe()
    A_Clipboard := exe
    ShowOSDFor(exe " (copied)", 3000)
}

IsBlockedFor(feature, exe) {
    global BlockIn
    return BlockIn.Has(feature) && InList(BlockIn[feature], exe)
}

SetBlocked(feature, exe, blocked) {
    global BlockIn
    if (exe = "" || !BlockIn.Has(feature))
        return
    list := BlockIn[feature]
    idx := 0
    for i, v in list {
        if (v = exe) {
            idx := i
            break
        }
    }
    if (blocked && !idx)
        list.Push(exe)
    else if (!blocked && idx)
        list.RemoveAt(idx)
}

ClosePanel(*) {
    global RulePanel
    if (RulePanel != "") {
        try RulePanel.Destroy()
        RulePanel := ""
    }
}

OpenRulePanel(*) {
    global RulePanel, RuleExe, RuleBoxes, RuleMaster
    global FeatureGroups, FeatureLabels
    global OSDEnabled, AutoCreateDesktop, WrapDesktops

    activeHwnd := WinActive("A")
    exe := ActiveExe()

    ; already open? close it. The hotkey toggles.
    if (RulePanel != "") {
        wasPanel := (activeHwnd = RulePanel.Hwnd)
        ClosePanel()
        if (wasPanel)
            return
    }
    if (exe = "")
        return

    RuleExe := exe
    RuleBoxes := Map()

    g := Gui("+AlwaysOnTop -MinimizeBox -MaximizeBox", "Mouse Flow Gestures")
    g.MarginX := 0, g.MarginY := 0
    g.SetFont("s11 Bold", "Segoe UI")
    g.Add("Text", "x16 y14 w448", "Rules for " exe)
    g.SetFont("s9 Norm", "Segoe UI")
    g.Add("Text", "x16 y38 w448 c808080", "Ticked = works here. Untick to switch it off in this app only. Saves instantly.")

    RuleMaster := g.Add("CheckBox", "x16 y64 w448 Checked" (IsBlockedFor("GLOBAL", exe) ? 0 : 1), FeatureLabels["GLOBAL"])
    RuleMaster.OnEvent("Click", MasterToggled)

    colX := [16, 250]
    colY := [98, 98]

    for grp in FeatureGroups {
        col := grp[3]
        y := colY[col]
        g.SetFont("s9 Bold", "Segoe UI")
        g.Add("Text", "x" colX[col] " y" y " w214", grp[1])
        y += 20
        g.SetFont("s9 Norm", "Segoe UI")
        for f in grp[2] {
            cb := g.Add("CheckBox", "x" (colX[col] + 10) " y" y " w204 Checked" (IsBlockedFor(f, exe) ? 0 : 1), FeatureLabels[f])
            cb.OnEvent("Click", RuleToggled.Bind(f))
            RuleBoxes[f] := cb
            y += 21
        }
        colY[col] := y + 12
    }

    yb := Max(colY[1], colY[2]) + 2
    g.Add("Text", "x16 y" yb " w448 h1 0x10")            ; divider
    yb += 12
    g.SetFont("s9 Bold", "Segoe UI")
    g.Add("Text", "x16 y" yb " w448", "Applies everywhere")
    g.SetFont("s9 Norm", "Segoe UI")
    yb += 20

    cb1 := g.Add("CheckBox", "x26 y" yb " w204 Checked" (OSDEnabled ? 1 : 0), "Show on-screen readout")
    cb1.OnEvent("Click", SettingToggled.Bind("OSDEnabled"))
    cb2 := g.Add("CheckBox", "x260 y" yb " w204 Checked" (AutoCreateDesktop ? 1 : 0), "Create desktop at the end")
    cb2.OnEvent("Click", SettingToggled.Bind("AutoCreateDesktop"))
    yb += 21
    cb3 := g.Add("CheckBox", "x26 y" yb " w204 Checked" (WrapDesktops ? 1 : 0), "Wrap around desktops")
    cb3.OnEvent("Click", SettingToggled.Bind("WrapDesktops"))
    yb += 32

    bReset := g.Add("Button", "x232 y" yb " w120 h28", "Enable all here")
    bReset.OnEvent("Click", EnableAllHere)
    bClose := g.Add("Button", "x376 y" yb " w88 h28 Default", "Close")
    bClose.OnEvent("Click", ClosePanel)
    g.OnEvent("Escape", ClosePanel)
    g.OnEvent("Close", ClosePanel)

    ApplyMasterState(!IsBlockedFor("GLOBAL", exe))

    H := yb + 44
    RulePanel := g
    PanelPos(activeHwnd, 480, H, &px, &py)
    g.Show("x" px " y" py " w480 h" H)
}

; Centre on the app being edited, falling back to the monitor under the mouse
PanelPos(hwnd, w, h, &x, &y) {
    if (hwnd) {
        try {
            WinGetPos(&wx, &wy, &ww, &wh, "ahk_id " hwnd)
            if (ww > 0 && wh > 0) {
                x := wx + (ww - w) // 2
                y := wy + (wh - h) // 2
                return
            }
        }
    }
    MonitorUnderMouse(&L, &T, &R, &B)
    x := L + (R - L - w) // 2
    y := T + (B - T - h) // 2
}

ApplyMasterState(enabled) {
    global RuleBoxes
    for f, cb in RuleBoxes
        cb.Enabled := enabled ? true : false
}

RuleToggled(feature, ctrl, *) {
    global RuleExe
    SetBlocked(feature, RuleExe, !ctrl.Value)
    SaveConfig()
}

MasterToggled(ctrl, *) {
    global RuleExe
    SetBlocked("GLOBAL", RuleExe, !ctrl.Value)
    SaveConfig()
    ApplyMasterState(ctrl.Value)
}

SettingToggled(name, ctrl, *) {
    global OSDEnabled, AutoCreateDesktop, WrapDesktops
    switch name {
        case "OSDEnabled":        OSDEnabled := ctrl.Value ? true : false
        case "AutoCreateDesktop": AutoCreateDesktop := ctrl.Value ? true : false
        case "WrapDesktops":      WrapDesktops := ctrl.Value ? true : false
    }
    SaveConfig()
}

EnableAllHere(*) {
    global BlockIn, RuleExe, RuleBoxes, RuleMaster
    for k in BlockIn
        SetBlocked(k, RuleExe, false)
    SaveConfig()
    RuleMaster.Value := 1
    for f, cb in RuleBoxes {
        cb.Value := 1
        cb.Enabled := true
    }
}

; ==============================================================================
;    12. TRAY MENU
; ==============================================================================

BuildTray() {
    global ConfigFile
    t := A_TrayMenu
    t.Delete()

    t.Add("Mouse Flow Gestures", (*) => 0)
    t.Disable("Mouse Flow Gestures")
    t.Add("Rules: press Ctrl+Alt+Shift+X in an app", (*) => 0)
    t.Disable("Rules: press Ctrl+Alt+Shift+X in an app")
    t.Add()

    t.Add("Pause hotkeys", (*) => Suspend())
    if (A_IsSuspended)
        t.Check("Pause hotkeys")
    t.Add("Edit config file", (*) => Run('notepad.exe "' ConfigFile '"'))
    t.Add("Edit script", (*) => Edit())
    t.Add("Reload", (*) => Reload())
    t.Add("Exit", (*) => ExitApp())
}

; ==============================================================================
;    13. CONFIG PERSISTENCE
; ==============================================================================

ParseList(str) {
    out := []
    for part in StrSplit(str, ",") {
        part := Trim(part)
        if (part != "")
            out.Push(part)
    }
    return out
}

JoinList(arr) {
    out := ""
    for v in arr
        out .= (out = "" ? "" : ",") v
    return out
}

LoadConfig() {
    global ConfigFile, BlockIn, OSDEnabled, AutoCreateDesktop, WrapDesktops
    global RepeatSwipes, CopyOnPress, MoveThreshold, ActionCooldown
    if !FileExist(ConfigFile)
        return

    keys := []
    for k in BlockIn
        keys.Push(k)
    for k in keys {
        v := IniRead(ConfigFile, "BlockIn", k, "@unset@")
        if (v != "@unset@")
            BlockIn[k] := ParseList(v)
    }

    OSDEnabled        := IniRead(ConfigFile, "Settings", "OSDEnabled", OSDEnabled ? 1 : 0) + 0
    AutoCreateDesktop := IniRead(ConfigFile, "Settings", "AutoCreateDesktop", AutoCreateDesktop ? 1 : 0) + 0
    WrapDesktops      := IniRead(ConfigFile, "Settings", "WrapDesktops", WrapDesktops ? 1 : 0) + 0
    RepeatSwipes      := IniRead(ConfigFile, "Settings", "RepeatSwipes", RepeatSwipes ? 1 : 0) + 0
    CopyOnPress       := IniRead(ConfigFile, "Settings", "CopyOnPress", CopyOnPress ? 1 : 0) + 0
    MoveThreshold     := IniRead(ConfigFile, "Settings", "MoveThreshold", MoveThreshold) + 0
    ActionCooldown    := IniRead(ConfigFile, "Settings", "ActionCooldown", ActionCooldown) + 0
}

SaveConfig() {
    global ConfigFile, BlockIn, OSDEnabled, AutoCreateDesktop, WrapDesktops
    global RepeatSwipes, CopyOnPress, MoveThreshold, ActionCooldown
    try {
        for k in BlockIn
            IniWrite(JoinList(BlockIn[k]), ConfigFile, "BlockIn", k)
        IniWrite(OSDEnabled ? 1 : 0, ConfigFile, "Settings", "OSDEnabled")
        IniWrite(AutoCreateDesktop ? 1 : 0, ConfigFile, "Settings", "AutoCreateDesktop")
        IniWrite(WrapDesktops ? 1 : 0, ConfigFile, "Settings", "WrapDesktops")
        IniWrite(RepeatSwipes ? 1 : 0, ConfigFile, "Settings", "RepeatSwipes")
        IniWrite(CopyOnPress ? 1 : 0, ConfigFile, "Settings", "CopyOnPress")
        IniWrite(MoveThreshold, ConfigFile, "Settings", "MoveThreshold")
        IniWrite(ActionCooldown, ConfigFile, "Settings", "ActionCooldown")
    }
}
