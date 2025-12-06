#Requires AutoHotkey v2.0

; --- Include the v2 library ---
; Ensure "VirtualDesktop.ah2" (or "VD.ahk") is in the same folder.
#Include VirtualDesktop.ah2

; === CONFIGURATION ===
global MoveThreshold := 40
global StartX := 0
global StartY := 0
global LastCreatedDesktopNum := 0

; --- Flags ---
global GestureCancelled := false
global SideButtonActionTaken := false 
global IsDoubleTap := false

; ==============================================================================
;    1. MIDDLE MOUSE BUTTON (Desktop & Task View)
; ==============================================================================
; These hotkeys are DISABLED if Blender is the active window.
#HotIf !WinActive("ahk_exe blender.exe")

MButton:: {
    global StartX, StartY, GestureCancelled
    GestureCancelled := false
    MouseGetPos(&StartX, &StartY)
    SetTimer(WatchMouse, 10)
}

MButton Up:: {
    global GestureCancelled, StartX, StartY, MoveThreshold
    SetTimer(WatchMouse, 0) 

    if (GestureCancelled) {
        return
    }

    MouseGetPos(&CurrentX, &CurrentY)
    local DeltaX := Abs(CurrentX - StartX)
    local DeltaY := Abs(CurrentY - StartY)

    ; If no movement -> Standard Middle Click
    if (DeltaX < MoveThreshold AND DeltaY < MoveThreshold) {
        Send("{MButton}")
    }
}

#HotIf ; End of Blender Exception

; ==============================================================================
;    2. FRONT SIDE BUTTON (MB5 / XButton2) -> Copy, Media Controls
; ==============================================================================
; Click: Copy (Instant)
; Hold + MB4: Play/Pause
; Hold + Swipe: Next/Prev Track

XButton2:: {
    global StartX, StartY, GestureCancelled, SideButtonActionTaken
    GestureCancelled := false
    SideButtonActionTaken := false
    MouseGetPos(&StartX, &StartY)
    SetTimer(WatchMouse, 10)
}

XButton2 Up:: {
    global GestureCancelled, SideButtonActionTaken, StartX, StartY, MoveThreshold
    SetTimer(WatchMouse, 0)

    ; If gesture or chord happened, do nothing
    if (GestureCancelled || SideButtonActionTaken) {
        return
    }

    ; No gesture -> Perform Copy (Instant)
    MouseGetPos(&CurrentX, &CurrentY)
    local DeltaX := Abs(CurrentX - StartX)
    local DeltaY := Abs(CurrentY - StartY)

    if (DeltaX < MoveThreshold AND DeltaY < MoveThreshold) {
        Send("^c") ; Copy
    }
}

; --- MB5 HELD CONTEXT ---
#HotIf GetKeyState("XButton2", "P")

    ; CHORD: Hold MB5 + Click MB4 -> Play/Pause
    XButton1:: {
        global GestureCancelled := true ; Cancel MB5's Copy action
        Send("{Media_Play_Pause}")
    }
    ; Consume the 'Up' event so it doesn't trigger Paste logic
    XButton1 Up:: return 

#HotIf

; ==============================================================================
;    3. BACK SIDE BUTTON (MB4 / XButton1) -> Paste, Tabs, Window Mgmt
; ==============================================================================
; Click: Paste (Instant - No Delay)
; Double-Tap: Nothing
; Hold + MB5: Play/Pause
; Hold + Scroll: Switch Tabs
; Hold + Swipe Left/Right: Move Window to Desktop
; Hold + Swipe Up: Pin Window (Show on all desktops)
; Hold + Swipe Down: Show Desktop

XButton1:: {
    global StartX, StartY, GestureCancelled, SideButtonActionTaken
    GestureCancelled := false
    SideButtonActionTaken := false
    MouseGetPos(&StartX, &StartY)
    SetTimer(WatchMouse, 10)
}

XButton1 Up:: {
    global GestureCancelled, SideButtonActionTaken, StartX, StartY, MoveThreshold
    SetTimer(WatchMouse, 0)

    ; If gesture, scroll or chord happened, do nothing
    if (GestureCancelled || SideButtonActionTaken) {
        return
    }

    ; No gesture -> Perform Paste (Instant)
    MouseGetPos(&CurrentX, &CurrentY)
    local DeltaX := Abs(CurrentX - StartX)
    local DeltaY := Abs(CurrentY - StartY)

    if (DeltaX < MoveThreshold AND DeltaY < MoveThreshold) {
        Send("^v") ; Paste
    }
}

; --- MB4 HELD CONTEXT ---
#HotIf GetKeyState("XButton1", "P")

    ; 1. CHORD: Hold MB4 + Click MB5 -> Play/Pause
    XButton2:: {
        global GestureCancelled := true ; Cancel MB4's Paste action
        Send("{Media_Play_Pause}")
    }
    ; Consume the 'Up' event so it doesn't trigger Copy logic
    XButton2 Up:: return

    ; 2. SCROLL: Tab Switching
    WheelUp:: {
        global SideButtonActionTaken := true
        Send("^+{Tab}")
    }
    WheelDown:: {
        global SideButtonActionTaken := true
        Send("^{Tab}")
    }

#HotIf

; ==============================================================================
;    SHARED MOUSE WATCHER (Handles all Swipes)
; ==============================================================================

WatchMouse() {
    global StartX, StartY, MoveThreshold, GestureCancelled
    MouseGetPos(&CurrentX, &CurrentY)
    
    ; --- A. MIDDLE BUTTON HELD (Desktop & Task View) ---
    if (GetKeyState("MButton", "P")) {
        if (CurrentX > StartX + MoveThreshold) { ; Swipe Right -> View Left Desktop
            Send("^#{Left}")
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        else if (CurrentX < StartX - MoveThreshold) { ; Swipe Left -> View Right Desktop
            Send("^#{Right}")
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        else if (CurrentY < StartY - MoveThreshold) { ; Swipe Up -> Task View
            Send("#{Tab}")
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        else if (CurrentY > StartY + MoveThreshold) { ; Swipe Down -> Task View
            Send("#{Tab}")
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
    }

    ; --- B. FRONT SIDE BUTTON (MB5) HELD (Media Control) ---
    else if (GetKeyState("XButton2", "P")) {
        if (CurrentX > StartX + MoveThreshold) { ; Swipe Right -> Previous Track
            Send("{Media_Prev}")
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        else if (CurrentX < StartX - MoveThreshold) { ; Swipe Left -> Next Track
            Send("{Media_Next}")
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
    }

    ; --- C. BACK SIDE BUTTON (MB4) HELD (Window Management) ---
    else if (GetKeyState("XButton1", "P")) {
        
        ; Swipe Right -> Move Window to NEXT Desktop
        if (CurrentX > StartX + MoveThreshold) { 
            n := VD.getCurrentDesktopNum()
            count := VD.getCount()
            
            if (n < count) {
                n += 1
                VD.MoveWindowToDesktopNum(WinActive("A"), n)
                VD.goToDesktopNum(n)
            } else { ; At the end -> Create new
                VD.createDesktop(false)
                n += 1
                VD.MoveWindowToDesktopNum(WinActive("A"), n)
                VD.goToDesktopNum(n)
            }
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        
        ; Swipe Left -> Move Window to PREVIOUS Desktop
        else if (CurrentX < StartX - MoveThreshold) { 
            n := VD.getCurrentDesktopNum()
            if (n > 1) {
                n -= 1
                VD.MoveWindowToDesktopNum(WinActive("A"), n)
                VD.goToDesktopNum(n)
            }
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        
        ; Swipe Up -> Pin Window (Show on all Desktops)
        else if (CurrentY < StartY - MoveThreshold) { 
            hwnd := WinActive("A")
            if (VD.IsWindowPinned(hwnd)) {
                VD.UnPinWindow(hwnd)
                ToolTip("Window Unpinned")
            } else {
                VD.PinWindow(hwnd)
                ToolTip("Window Pinned (Visible on all Desktops)")
            }
            SetTimer () => ToolTip(), -1500 ; Remove Tooltip after 1.5s
            
            SoundBeep(1000, 100) 
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
        
        ; Swipe Down -> Show Desktop (Minimize All)
        else if (CurrentY > StartY + MoveThreshold) { 
            Send("#d") ; Win + D
            GestureCancelled := true
            SetTimer(WatchMouse, 0)
        }
    }
}

; ==============================================================================
;    4. KEYBOARD HOTKEYS (Window Moving & Desktops)
; ==============================================================================

#^+Left:: {
    global LastCreatedDesktopNum
    LastCreatedDesktopNum := 0 
    n := VD.getCurrentDesktopNum()
    if (n == 1) {
        Return
    }
    n -= 1
    VD.MoveWindowToDesktopNum(WinActive("A"), n)
    VD.goToDesktopNum(n)
}

#^+Right:: {
    global LastCreatedDesktopNum
    if (A_PriorHotkey == A_ThisHotkey && A_TimeSincePriorHotkey < 400) {
        VD.createDesktop(false) 
        n := VD.getCount()      
        VD.MoveWindowToDesktopNum(WinActive("A"), n) 
        VD.goToDesktopNum(n)                         
        LastCreatedDesktopNum := n
        Return 
    }
    n := VD.getCurrentDesktopNum()
    if (n == LastCreatedDesktopNum) {
        Return
    }
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

; ==============================================================================
;    5. DIRECT DESKTOP SWITCHING (Win+N and TaskView N)
; ==============================================================================

; --- Helper Function: Switch Safely ---
SwitchToDesktopSafe(targetDesktopNum) {
    count := VD.getCount()
    if (targetDesktopNum > count) {
        targetDesktopNum := count ; Fallback to the last available desktop
    }
    VD.goToDesktopNum(targetDesktopNum)
}

; --- Helper Function: Switch & Escape (For Task View) ---
TaskViewSwitch(targetDesktopNum) {
    SwitchToDesktopSafe(targetDesktopNum)
    Send("{Esc}") ; Close Task View immediately
}

; --- A. Win + Number (1-9, 0) ---
; Overrides default Taskbar app switching behavior
Loop 10 {
    i := A_Index
    dNum := (i == 10) ? 10 : i ; Map '0' to Desktop 10, '1' to 1
    
    ; Bind the variable dNum to the function so it doesn't get overwritten
    Hotkey "#" . ((i == 10) ? "0" : i), ((n, *) => SwitchToDesktopSafe(n)).Bind(dNum)
}

; --- B. Task View Mode (Just Numbers 1-9, 0) ---
; Active only when "Task View" is the active window.

IsTaskViewActive(*) {
    return WinActive(VD._getLocalizedWord_TaskView()) || WinActive("ahk_class MultitaskingViewFrame")
}

HotIf IsTaskViewActive
    Loop 10 {
        i := A_Index
        dNum := (i == 10) ? 10 : i
        
        ; Bind numbers 1-9 and 0 to the Switch & Escape function
        Hotkey ((i == 10) ? "0" : String(i)), ((n, *) => TaskViewSwitch(n)).Bind(dNum)
    }
HotIf
