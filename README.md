# 🖱️ Mouse Flow Gestures

**Turn your mouse into a productivity powerhouse.**

This AutoHotkey v2 script brings trackpad-like gestures, seamless virtual desktop management, and advanced window controls to your mouse. Window actions preview themselves before they fire, and every single feature can be switched off per application from a panel you summon inside that app. Optimized for the **Razer Basilisk X Hyperspeed**, but works with any 5-button mouse.

## 🚀 Features

* **Gesture Navigation:** Switch desktops and open Task View by holding the middle mouse button and swiping. Fires instantly, no lag.
* **Preview before you commit:** Window actions arm when you cross the threshold and show an on-screen readout of what is about to happen. Release to fire, drag back to centre or hit `Esc` to cancel.
* **Window Management:** Move windows across desktops, send them to a desktop *without* following, pin them everywhere, or toggle always-on-top.
* **Aero Snap on the mouse:** Hold `Shift` while swiping the front side button to snap, maximise or minimise the active window.
* **Complete Media Control:** Play/Pause, Next/Prev track and volume, entirely from your mouse.
* **Per-app rules:** Press `Ctrl+Alt+Shift+X` inside any app for a panel of tickboxes, one per feature, saved instantly. Blender ships with middle-mouse gestures disabled out of the box.
* **Direct Desktop Switching:** Jump to any desktop with `Win + Number`.
* **Infinite Desktop Creation:** Swiping past the last desktop creates a new one — or wraps around, if you prefer.

## 🛠️ Prerequisites

1. **[AutoHotkey v2](https://www.autohotkey.com/)** installed.
2. **Windows 10 or 11**.

## 📦 Installation

1. Clone or download this repository.
2. Ensure `VirtualDesktop.ah2` and `MouseFlow.ahk` are in the same folder.
3. Double-click `MouseFlow.ahk` to start.
4. *(Optional)* Right-click the script, create a shortcut, and drop it in your Startup folder (`Win+R` → `shell:startup`) to run on boot.

> **Running as admin:** hotkeys are ignored while an elevated window is focused — Task Manager, installers, anything UAC'd. To fix it, create a Task Scheduler task that runs the script at logon with *"Run with highest privileges"*. There is also an `AutoElevate` flag in the script, but it prompts UAC on every boot.

## 🎮 Controls Manual

### How gestures work

**Navigation fires instantly.** Switching desktop, opening Task View and skipping tracks all happen the moment you cross the threshold.

**Window actions preview first.** Moving, pinning, snapping, show-desktop and always-on-top **arm** at the threshold, show an OSD telling you what will happen, and **fire** when you release.

| While holding a window action | Result |
| :--- | :--- |
| Drag back to the centre | Cancels |
| Press `Esc` | Cancels |
| Press or release `Shift` | Switches to the Shift action, OSD updates live |

Which actions skip the preview is a one-line list in the script:

```autohotkey
global InstantActions := ["vd_left", "vd_right", "taskview", "media_prev", "media_next"]
```

Pull an id out to give it a preview, or add one in (`"pin"`, `"showdesktop"`, `"move_next"` …) to make it immediate.

### 1. Middle Mouse Button — Desktop Manager

*Hold the wheel down and move the mouse. Disabled in Blender by default.*

| Gesture | Action |
| :--- | :--- |
| **Click** | Standard Middle Click |
| **Swipe Left** | Switch to **Right Desktop** |
| **Swipe Right** | Switch to **Left Desktop** |
| **Swipe Up / Down** | Open **Task View** |

### 2. Front Side Button (MB5) — Media, Clipboard & Snapping

*The button closest to the front of the mouse.*

| Action | Function |
| :--- | :--- |
| **Click** | **Copy** (`Ctrl + C`) — *instant* |
| **Double Tap** | **Clipboard History** (`Win + V`) |
| **Hold still, then release** | **Mute / Unmute** 🔇 |
| **Swipe Left** | **Next Track** ⏭️ |
| **Swipe Right** | **Previous Track** ⏮️ |
| **`Shift` + Swipe Left** | **Snap window left** |
| **`Shift` + Swipe Right** | **Snap window right** |
| **`Shift` + Swipe Up** | **Maximise** |
| **`Shift` + Swipe Down** | **Minimise** |
| **Hold + Scroll Wheel** | **Volume Up / Down** 🔊 |
| **Hold + Click Back Button** | **Play / Pause** Media |

### 3. Back Side Button (MB4) — Windows & Desktops

*The button closest to the back of the mouse.*

| Action | Function |
| :--- | :--- |
| **Click** | **Paste** (`Ctrl + V`) — *instant* |
| **Hold still, then release** | Toggle **Always On Top** 📌 |
| **Swipe Left** | **Move window** to previous desktop **and follow it** |
| **Swipe Right** | **Move window** to next desktop **and follow it** (creates one if needed) |
| **`Shift` + Swipe Left** | **Send window** to previous desktop, **stay where you are** |
| **`Shift` + Swipe Right** | **Send window** to next desktop, **stay where you are** |
| **Swipe Up** | **Pin / Unpin Window** (show on all desktops) |
| **Swipe Down** | **Show Desktop** (minimise all) |
| **Hold + Scroll Wheel** | **Switch Browser Tabs** (`Ctrl + Tab`) |
| **Hold + Click Front Button** | **Play / Pause** Media |

### 4. Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`Win`+`Ctrl`+`Shift`+`←`** | Move active window to **Previous Desktop** |
| **`Win`+`Ctrl`+`Shift`+`→`** | Move active window to **Next Desktop**. Double tap to create a fresh desktop and move there. |
| **`Win` + `1-9`** | Jump to Desktop 1-9 (falls back to the last one that exists) |
| **`Win` + `0`** | Jump to Desktop 10 |
| **`Ctrl`+`Alt`+`Shift`+`X`** | Open the **rules panel** for the current app |
| **`Ctrl`+`Alt`+`Shift`+`E`** | Show and copy the active window's **exe name** |

### 5. Task View Shortcuts

*While the Task View overlay is open:* press **`1-9`** or **`0`** to switch to that desktop and close Task View.

## 🎛️ Per-App Rules

Every feature can be switched off in specific applications — you don't have to choose between "the whole script" and "nothing".

**Press `Ctrl`+`Alt`+`Shift`+`X` while the app is focused.** A panel opens listing every feature as a tickbox. Ticked means it works in that app; untick whatever gets in your way. Changes save to `MouseFlow.ini` the moment you click — nothing to apply, no reload. Press the hotkey again, or `Esc`, to close.

The tickbox at the top switches the entire script off for that app. **Enable all here** wipes every rule for it. The three global settings sit at the bottom of the same panel.

Because the hotkey fires *while the app is still focused*, the panel always knows exactly which app it is editing. Both this hotkey and `Ctrl+Alt+Shift+E` sit outside every context check, so they keep working in an app where you've disabled everything else.

**Editing by hand.** The `BlockIn` map near the top of the script does the same job. Use `Ctrl+Alt+Shift+E` on any window to grab its exe name.

```autohotkey
global BlockIn := Map(
    "GLOBAL",        ["valorant.exe"],   ; whole script off in these apps
    "MiddleButton",  ["blender.exe"],    ; MMB gestures off, everything else stays
    "TabSwitch",     ["code.exe"],
    ...
)
```

`OnlyIn` is the inverse — a feature that works **only** in the apps you list:

```autohotkey
global OnlyIn := Map("TabSwitch", ["chrome.exe", "msedge.exe"])
```

Feature keys:

`MiddleButton` · `DesktopSwipe` · `TaskView` · `CopyPaste` · `ClipboardHistory` · `MediaSwipe` · `WindowSnap` · `Volume` · `Mute` · `PlayPause` · `TabSwitch` · `WindowMove` · `PinWindow` · `ShowDesktop` · `AlwaysOnTop` · `KeyboardVD` · `WinNumber` · `TaskViewNums`

When a click action is disabled in an app, the button passes through natively — so MB4 still does Back in your browser.

## ⚙️ Configuration

The three you'll actually change are at the bottom of the rules panel. The rest are in the `SETTINGS` block at the top of the script:

```autohotkey
global MoveThreshold     := 40      ; px of travel before a swipe triggers
global LongPressTime     := 350     ; ms held still before the long press arms
global DoubleTapTime     := 300     ; ms window for the MB5 double tap
global ActionCooldown    := 220     ; ms minimum between desktop actions
global OSDEnabled        := true    ; on-screen readout
global AutoCreateDesktop := true    ; swiping past the last desktop creates one
global WrapDesktops      := false   ; ...or wraps around (only if the above is off)
global RepeatSwipes      := false   ; keep holding and swipe again to repeat
```

Settings and per-app rules are stored in an `.ini` next to the script, named after it — rename `MouseFlow.ahk` and the ini follows.

## 🩺 Troubleshooting

| Symptom | Cause |
| :--- | :--- |
| Nothing works in one specific app | Press `Ctrl+Alt+Shift+X` there — something may be unticked. |
| Nothing works in Task Manager / installers | Elevated window. Run the script as admin (see above). |
| Swipes fire too easily | Raise `MoveThreshold`. |
| A gesture feels sluggish | It's waiting for the release. Add its id to `InstantActions`. |
| Long press fires when you didn't mean it | Raise `LongPressTime`, or untick it for that app in the panel. |
| Middle-drag doesn't work in some app | The click is sent on release, so drags can't pass through. Untick **All middle-button gestures** for that app. |
| OSD says "Desktop 3" instead of your desktop name | Your copy of `VirtualDesktop.ah2` doesn't expose desktop names. Harmless. |

## 📄 License

MIT.
