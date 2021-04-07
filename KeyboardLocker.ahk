#Persistent
FileInstall, Locked.ico, Locked.ico, 0
FileInstall, Unlocked.ico, Unlocked.ico, 0
Init()

;Works only if the keyboard is not locked.
^!l::
  KeyWait, Ctrl
  KeyWait, Alt
  KeyWait, l
  LockKeyboard()
return

LockKeyboard:
  LockKeyboard()
return

Exit:
  LockKeyboard(false)
  ExitApp
return

Init()
{
  global locked := 0
  Menu, Tray, Icon, Unlocked.ico
  Menu, Tray, NoStandard
  Menu, Tray, Tip, Keyboard Locker`nPress Ctrl+Alt+L to lock keyboard
  Menu, Tray, Add, Lock Keyboard, LockKeyboard
  Menu, Tray, Icon, Lock Keyboard, Locked.ico 
  Menu, Tray, Add, Exit, Exit
}

LockKeyboard(block = -1) ;-1, true or false.
{
  global locked
  static hook := 0, callback := 0
  WH_KEYBOARD_LL := 13

  if !callback { ;register callback once only.
    callback := RegisterCallback("LockKeyboardHookCallback")
  }

  if (block = -1) {
    block := (hook = 0)
  }

  if ((hook != 0) = (block != 0)) { ;already (un)locked, no action necessary.
    return
  } 

  if (block) {
    Menu, Tray, Icon, Locked.ico ;Change tray icon
    Menu, Tray, Tip, Keyboard Locker`nPress Ctrl+Alt+L to unlock keyboard
    Menu, Tray, Rename, Lock Keyboard, Unlock Keyboard
    Menu, Tray, Icon, Unlock Keyboard, Unlocked.ico 

    hook := SetWindowsHookEx(WH_KEYBOARD_LL, callback)

    locked = 1
  }
  else {
    Menu, Tray, Icon, Unlocked.ico ;Change tray icon
    Menu, Tray, Tip, Keyboard Locker`nPress Ctrl+Alt+L to lock keyboard
    Menu, Tray, Rename, Unlock Keyboard, Lock Keyboard
    Menu, Tray, Icon, Lock Keyboard, Locked.ico 

    UnhookWindowsHookEx(hook)

    hook := 0
    locked := 0
  }
}

SetWindowsHookEx(idHook, callback)
{
  return DllCall("SetWindowsHookEx"
    , "int", idHook ;Hook type https://docs.microsoft.com/en-us/windows/win32/winmsg/about-hooks#hook-types
    , "uint", callback ;lpfn (callback)
    , "uint", 0 ;hMod (NULL)
    , "uint", 0) ;dwThreadId (all threads)
}

UnhookWindowsHookEx(hook)
{
  return DllCall("UnhookWindowsHookEx", "Uint", hook)
}

LockKeyboardHookCallback(nCode, wParam, lParam)
{
  static ctrlAltKey := 0, lKey := 0
  isKeyDown := (wParam = 0x0100)

  if (isKeyDown) {
    keyPressed := NumGet(lParam+4)

    if (keyPressed = 0x38) {
      ctrlAltKey := 1
    }

    if (keyPressed = 0x26) {
      lKey := 1
    }
  } else {
    ;TODO: Wait for Ctrl+Alt+L release, so it works like locking
    if (ctrlAltKey = 1 && lKey = 1) {
      LockKeyboard(false)
    }
    ctrlAltKey := 0
    lKey := 0
  }
  return 1
}
