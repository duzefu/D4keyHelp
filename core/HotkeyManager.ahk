; ========== 启停热键管理 ==========

NormalizeStartStopHotkey(hotkey) {
    hotkey := Trim(hotkey)
    return RegExReplace(hotkey, "^\*+", "")
}

IsMouseStartStopHotkey(hotkey) {
    hotkey := NormalizeStartStopHotkey(hotkey)
    keyName := RegExReplace(hotkey, "[\^\!\+#]", "")
    return keyName = "MButton" || keyName = "XButton1" || keyName = "XButton2"
}

IsForbiddenStartStopHotkey(hotkey) {
    hotkey := NormalizeStartStopHotkey(hotkey)
    if (hotkey = "")
        return true

    keyName := RegExReplace(hotkey, "[\^\!\+#]", "")
    keyName := StrUpper(keyName)
    return (keyName = "LBUTTON"
        || keyName = "RBUTTON"
        || keyName = "F3"
        || keyName = "TAB")
}

GetStartStopHotkeyDisplay(hotkey := "") {
    global startStopHotkey

    if (hotkey = "")
        hotkey := startStopHotkey

    hotkey := NormalizeStartStopHotkey(hotkey)
    display := StrReplace(hotkey, "^", "Ctrl+")
    display := StrReplace(display, "!", "Alt+")
    display := StrReplace(display, "+", "Shift+")
    display := StrReplace(display, "#", "Win+")
    return display
}

UpdateStartStopHotkeyUi() {
    global startStopHotkey, startStopHotkeyCtrl, startStopMouseCtrl, startStopButton
    global hotkeyChangeInProgress

    hotkeyChangeInProgress := true
    try {
        if (startStopHotkeyCtrl != "") {
            if (IsMouseStartStopHotkey(startStopHotkey))
                startStopHotkeyCtrl.Value := ""
            else
                startStopHotkeyCtrl.Value := startStopHotkey
        }

        if (startStopMouseCtrl != "") {
            mouseKey := NormalizeStartStopHotkey(startStopHotkey)
            if (mouseKey = "MButton")
                startStopMouseCtrl.Choose(2)
            else if (mouseKey = "XButton1")
                startStopMouseCtrl.Choose(3)
            else if (mouseKey = "XButton2")
                startStopMouseCtrl.Choose(4)
            else
                startStopMouseCtrl.Choose(1)
        }

        if (startStopButton != "") {
            buttonText := "开始 / 停止  (" . GetStartStopHotkeyDisplay() . ")"
            try {
                startStopButton.Text := buttonText
            } catch {
                try {
                    startStopButton.Value := buttonText
                }
            }
        }
    } finally {
        hotkeyChangeInProgress := false
    }
}

RegisterStartStopHotkey(newHotkey := "") {
    global startStopHotkey, registeredStartStopHotkey, statusBar

    if (newHotkey = "")
        newHotkey := startStopHotkey

    newHotkey := NormalizeStartStopHotkey(newHotkey)
    if (IsForbiddenStartStopHotkey(newHotkey)) {
        if (statusBar != "")
            statusBar.Text := "启停键无效，已保留: " . GetStartStopHotkeyDisplay()
        UpdateStartStopHotkeyUi()
        return false
    }

    oldRegistered := registeredStartStopHotkey
    try {
        HotIfWinActive("ahk_class Diablo IV Main Window Class")
        if (oldRegistered != "")
            Hotkey("*" . oldRegistered, ToggleMacro, "Off")

        Hotkey("*" . newHotkey, ToggleMacro, "On")
        HotIf()
    } catch as err {
        try {
            HotIf()
        }
        if (oldRegistered != "") {
            try {
                HotIfWinActive("ahk_class Diablo IV Main Window Class")
                Hotkey("*" . oldRegistered, ToggleMacro, "On")
                HotIf()
            }
        }
        if (statusBar != "")
            statusBar.Text := "启停键注册失败: " . err.Message
        UpdateStartStopHotkeyUi()
        return false
    }

    startStopHotkey := newHotkey
    registeredStartStopHotkey := newHotkey
    UpdateStartStopHotkeyUi()
    DebugLog("启停热键已注册: " . startStopHotkey)
    return true
}

ApplyStartStopHotkey(newHotkey, shouldSave := true) {
    global statusBar

    if (RegisterStartStopHotkey(newHotkey)) {
        if (shouldSave)
            SaveSettings()
        if (statusBar != "")
            statusBar.Text := "启停键已设置为: " . GetStartStopHotkeyDisplay()
        return true
    }
    return false
}

OnStartStopKeyboardChanged(ctrl, *) {
    global hotkeyChangeInProgress

    if (hotkeyChangeInProgress)
        return

    newHotkey := NormalizeStartStopHotkey(ctrl.Value)
    if (newHotkey != "")
        ApplyStartStopHotkey(newHotkey)
    else
        UpdateStartStopHotkeyUi()
}

OnStartStopMouseChanged(ctrl, *) {
    global hotkeyChangeInProgress

    if (hotkeyChangeInProgress)
        return

    value := ctrl.Value
    if (value = 1) {
        UpdateStartStopHotkeyUi()
        return
    }

    mouseHotkeys := ["", "MButton", "XButton1", "XButton2"]
    ApplyStartStopHotkey(mouseHotkeys[value])
}
