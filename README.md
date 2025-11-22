# 🖱️ Mouse Flow Gestures

**Turn your mouse into a productivity powerhouse.**

This AutoHotkey v2 script brings trackpad-like gestures, seamless virtual desktop management, and advanced window controls to your mouse. While optimized for the **Razer Basilisk X Hyperspeed**, it works with any 5-button mouse.

## 🚀 Features

* **Gesture Navigation:** Switch desktops and open Task View by simply holding the middle mouse button and swiping.
* **Instant Window Management:** Move windows across desktops or snap them to sides using intuitive swipes.
* **Smart Media Controls:** Play/Pause, Next/Prev track without touching your keyboard.
* **Productivity Boosters:** Instant Copy/Paste, "Always on Top" pinning, and rapid Browser Tab switching.
* **Infinite Desktop Creation:** Automatically creates new virtual desktops when you move a window past the last one.

## 🛠️ Prerequisites

1.  **[AutoHotkey v2](https://www.autohotkey.com/)** installed.
2.  **Windows 10 or 11**.

## 📦 Installation

1.  Clone or download this repository.
2.  Ensure `VirtualDesktop.ah2` and `MouseFlow.ahk` are in the same folder.
3.  Double-click `MouseFlow.ahk` to start.
4.  *(Optional)* Right-click the script and create a shortcut, then place it in your Windows Startup folder (`Win+R` -> `shell:startup`) to run automatically on boot.

## 🎮 Controls Manual

### 1. Middle Mouse Button (Desktop Manager)
*Hold the wheel down and move the mouse.*

| Gesture | Action |
| :--- | :--- |
| **Click** | Standard Middle Click |
| **Hold + Swipe Left** | Switch to **Right Desktop** |
| **Hold + Swipe Right** | Switch to **Left Desktop** |
| **Hold + Swipe Up/Down** | Open **Task View** |

### 2. Front Side Button (MB5) (Media & Copy)
*The button closest to the front of the mouse.*

| Action | Function |
| :--- | :--- |
| **Click** | **Copy** (`Ctrl + C`) |
| **Hold + Click Back Button** | **Play / Pause** Media |
| **Hold + Swipe Left** | **Next Track** ⏭️ |
| **Hold + Swipe Right** | **Previous Track** ⏮️ |

### 3. Back Side Button (MB4) (Productivity & Paste)
*The button closest to the back of the mouse.*

| Action | Function |
| :--- | :--- |
| **Click** | **Paste** (`Ctrl + V`) |
| **Hold + Click Front Button** | **Play / Pause** Media |
| **Hold + Scroll Wheel** | **Switch Browser Tabs** (`Ctrl + Tab`) |
| **Hold + Swipe Left** | **Move Window** to Previous Desktop |
| **Hold + Swipe Right** | **Move Window** to Next Desktop (Creates new if needed) |
| **Hold + Swipe Up** | **Pin Window** (Show on All Desktops) |
| **Hold + Swipe Down** | **Show Desktop** (Minimize All) |

### 4. Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **`Win`+`Ctrl`+`Shift`+`←`** | Move active window to **Previous Desktop**. |
| **`Win`+`Ctrl`+`Shift`+`→`** | Move active window to **Next Desktop**. (Auto-creates new desktop if at the end). |
| **`Win`+`Ctrl`+`Shift`+`→`** (Double Tap) | **Instantly create** a new desktop, move window there, and follow it. |

## ⚙️ Configuration

Open `MouseFlow.ahk` in a text editor to adjust the sensitivity:

```autohotkey
global MoveThreshold := 40  ; Lower = More sensitive swipes
