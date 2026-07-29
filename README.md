<div align="center">
    
```
 _______  _____  _     _ _______ _______      _______         _____  _  _  _
 |  |  | |     | |     | |______ |______      |______ |      |     | |  |  |
 |  |  | |_____| |_____| ______| |______      |       |_____ |_____| |__|__|
                                                             
G  E  S  T  U  R  E  S
```
</div>

<div align="center">

**Trackpad-like gestures, virtual desktops and window management — all from your mouse.**

![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2-334455?style=flat-square)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)

> Optimised for the **Razer Basilisk X Hyperspeed**, works with any 5-button mouse.

</div>

---

## ⚡ Install

```
   1   Install AutoHotkey v2   →   autohotkey.com
   2   Put MouseFlow.ahk and VirtualDesktop.ah2 in the same folder
   3   Double-click MouseFlow.ahk
   4   Optional — shortcut into  Win+R → shell:startup   to run at boot
```

> ⚠️ **Run it as admin.** Hotkeys are ignored while an elevated window is focused — Task Manager, installers, anything UAC'd. Cleanest fix is a Task Scheduler task at logon with *"Run with highest privileges"*. There's an `AutoElevate` flag in the script too, but it prompts UAC every boot.

---

## 🎯 How a gesture fires

```
   NAVIGATION                switch desktop · task view · skip track
   ──────────────────────────────────────────────────────────────────
     press ──▶ move 40px ──▶ FIRES IMMEDIATELY


   WINDOW ACTIONS            move · pin · snap · show desktop
   ──────────────────────────────────────────────────────────────────
     press ──▶ move 40px ──▶ ARMED ──▶ release ──▶ FIRES
                               │
                               ├──▶ drag back to centre ──▶ cancel
                               ├──▶ press Esc ────────────▶ cancel
                               └──▶ tap Shift ──▶ swaps to the Shift
                                                  action, live
```

While a window action is armed, an **OSD** near the bottom of the screen tells you exactly what is about to happen — *"Move to Desktop 3 ▸"*, *"Pin to all desktops"*, *"Snap left"*.

Which actions skip the preview is one line in the script:

```autohotkey
global InstantActions := ["vd_left", "vd_right", "taskview", "media_prev", "media_next"]
```

Pull an id out to give it a preview. Add one in — `"pin"`, `"showdesktop"`, `"move_next"` — to make it immediate.

---

## 🧭 Gesture map

### ║ &nbsp; Middle wheel — desktops

```
                             ▲
                         task view
                             │
       next desktop ◄────────●────────► prev desktop
                             │
                         task view
                             ▼

         click  · · · · · ·  normal middle click
```

*Ships disabled inside Blender, so your 3D orbit still works.*

### ● &nbsp; MB5 — front side button

```
                             ▲
                      ⇧ maximise
                             │
         next track ◄────────●────────► prev track
       ⇧ snap left           │          ⇧ snap right
                             │
                      ⇧ minimise
                             ▼

         click  · · · · · · · · ·  copy                  Ctrl+C
         hold + scroll  · · · · ·  volume up / down
         hold + click MB4  · · ·   play / pause
```

### ● &nbsp; MB4 — back side button

```
                             ▲
                   pin to all desktops
                             │
    ◄ move to prev desktop ──●──► move to next desktop ►
       ⇧ = send it, stay     │     ⇧ = send it, stay
                             │
                      show desktop
                             ▼

         click  · · · · · · · · ·  paste                 Ctrl+V
         hold + scroll  · · · · ·  switch tabs           Ctrl+Tab
         hold + click MB5  · · ·   play / pause
```

> **`⇧ Shift` on MB4** sends the window to another desktop *without dragging you along with it.* Swiping past the last desktop creates a new one.

### 📋 Copy & paste speed

Copy and paste fire on the **release** of the button, with nothing in the code path between that release and the keystroke — no timers, no window calls, no lookups. That's what makes a click read as a click.

If you want copy absolutely as early as physically possible, flip one setting and it fires on the **press** instead:

```autohotkey
global CopyOnPress := true
```

The trade: MB5 is also the modifier for volume, media and snapping — so with this on, every one of those overwrites your clipboard whenever something is selected. Off by default for that reason.

---

## ⌨️ Keyboard

| Shortcut | Action |
| :--- | :--- |
| `Win` `Ctrl` `Shift` `←` | Move active window to the **previous desktop** |
| `Win` `Ctrl` `Shift` `→` | Move active window to the **next desktop** · double-tap to create a fresh one and jump there |
| `Win` `1` … `9` | Jump to that desktop *(falls back to the last one that exists)* |
| `Win` `0` | Jump to desktop 10 |
| `1` … `9` `0` *inside Task View* | Jump to that desktop and close Task View |
| `Ctrl` `Alt` `Shift` `X` | 🎛️ Open the **rules panel** for the current app |
| `Ctrl` `Alt` `Shift` `E` | Show + copy the active window's **exe name** |

---

## 🎛️ Per-app rules

**You never have to choose between "the whole script" and "nothing".** Every single feature can be switched off in specific apps.

Press <kbd>Ctrl</kbd> <kbd>Alt</kbd> <kbd>Shift</kbd> <kbd>X</kbd> **while that app is focused**:

```
 ╔══ Mouse Flow Gestures ══════════════════════════════════════════╗
 ║                                                                 ║
 ║  Rules for blender.exe                                          ║
 ║  Ticked = works here. Untick to switch it off in this app only. ║
 ║                                                                 ║
 ║  [x] Enable Mouse Flow in this app                              ║
 ║                                                                 ║
 ║  Middle mouse                    Back side button (MB4)         ║
 ║    [ ] All middle-button           [x] Hold + scroll: tabs      ║
 ║    [x] Swipe L/R: switch desktop   [x] Swipe L/R: move desktop  ║
 ║    [x] Swipe U/D: task view        [x] Swipe up: pin window     ║
 ║                                    [x] Swipe down: show desktop ║
 ║  Front side button (MB5)                                        ║
 ║    [x] Swipe: prev / next track  Keyboard                       ║
 ║    [x] Shift+swipe: snap window    [x] Win+Ctrl+Shift+arrows    ║
 ║    [x] Hold + scroll: volume       [x] Win + number             ║
 ║                                    [x] Numbers in task view     ║
 ║  Both side buttons                                              ║
 ║    [x] Click: copy / paste                                      ║
 ║    [x] MB4+MB5: play / pause                                    ║
 ║  ─────────────────────────────────────────────────────────────  ║
 ║  Applies everywhere                                             ║
 ║    [x] Show on-screen readout    [x] Create desktop at the end  ║
 ║    [ ] Wrap around desktops                                     ║
 ║                                                                 ║
 ║                         [ Enable all here ]      [  Close  ]    ║
 ╚═════════════════════════════════════════════════════════════════╝

    ✓  saves the instant you click — no apply button, no reload
    ✓  the top tickbox kills the entire script in that app
    ✓  "Enable all here" wipes every rule for that app
    ✓  Esc, or the same hotkey again, closes it
```

Because the hotkey fires *while the app is still focused*, the panel always knows exactly which app it's editing. Both it and `Ctrl+Alt+Shift+E` sit outside every context check, so they keep working inside an app where you've disabled everything else.

When a **click** action is disabled in an app, the button passes through natively — so MB4 still does Back in your browser.

<details>
<summary><b>Editing the rules by hand</b> — the <code>BlockIn</code> and <code>OnlyIn</code> maps</summary>

<br>

Everything the panel does, you can do in the script. Use `Ctrl+Alt+Shift+E` on any window to grab its exe name.

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

**Every feature key**

| Middle mouse | MB5 | MB4 | Shared | Keyboard |
| :--- | :--- | :--- | :--- | :--- |
| `MiddleButton` | `MediaSwipe` | `TabSwitch` | `CopyPaste` | `KeyboardVD` |
| `DesktopSwipe` | `WindowSnap` | `WindowMove` | `PlayPause` | `WinNumber` |
| `TaskView` | `Volume` | `PinWindow` | | `TaskViewNums` |
| | | `ShowDesktop` | | |

`GLOBAL` is the master key — an app listed there gets the whole script disabled. The `.ini` written by the panel overrides whatever is set in the script.

</details>

---

## ⚙️ Settings

The three you'll actually touch live at the bottom of the rules panel. The rest sit in the `SETTINGS` block at the top of the script.

```autohotkey
global MoveThreshold     := 40      ; px of travel before a swipe triggers
global ActionCooldown    := 220     ; ms minimum between desktop actions
global OSDEnabled        := true    ; on-screen readout
global AutoCreateDesktop := true    ; swiping past the last desktop creates one
global WrapDesktops      := false   ; ...or wraps around (only if the above is off)
global RepeatSwipes      := false   ; keep holding and swipe again to repeat
global CopyOnPress       := false   ; fire copy on press instead of release
global AutoElevate       := false   ; relaunch as admin (UAC prompt every boot)
```

Settings and per-app rules persist to an `.ini` next to the script, named after it — rename `MouseFlow.ahk` and the ini follows.

---

## 🩺 Troubleshooting

| Symptom | Fix |
| :--- | :--- |
| Nothing works in one specific app | `Ctrl+Alt+Shift+X` there — something's unticked |
| Nothing works in Task Manager / installers | Elevated window — run the script as admin |
| Swipes fire too easily | Raise `MoveThreshold` |
| A gesture feels sluggish | It's waiting for the release — add its id to `InstantActions` |
| Middle-**drag** doesn't work in some app | The click is sent on release, so drags can't pass through. Untick *All middle-button gestures* there |
| OSD says "Desktop 3" instead of your name for it | Your `VirtualDesktop.ah2` doesn't expose desktop names. Harmless |

---

<div align="center">

**MIT** · built with [AutoHotkey v2](https://www.autohotkey.com/) and [VirtualDesktop.ah2](https://github.com/FuPeiJiang/VD.ahk)

</div>
