; ========== GUI创建（现代卡片风格） ==========
/**
 * 创建主GUI界面
 */
CreateMainGUI() {
    global myGui, statusText, statusBar, presetTab, presetNames, currentPreset
    global startStopHotkeyCtrl, startStopMouseCtrl, startStopButton
    global MUI_FontName, MUI_T, MUI_Theme, MUI_CardBg

    MUI_SetTheme(MUI_LoadThemeSetting(A_ScriptDir "\settings.ini"))
    MUI_Startup()

    title := "c" MUI_Hex(MUI_T.title)
    text := "c" MUI_Hex(MUI_T.text)
    muted := "c" MUI_Hex(MUI_T.muted)
    faint := "c" MUI_Hex(MUI_T.faint)

    ; 创建主窗口
    myGui := Gui("", L("app.title"))
    myGui.BackColor := MUI_Hex(MUI_T.window)
    myGui.SetFont("s10 " text, MUI_FontName)
    myGui.MarginX := 12
    myGui.MarginY := 12

    ; ========== 预设分段选择器 ==========
    presetTab := ModernSegmented(myGui, 12, 12, 92, 40, presetNames)
    presetTab.OnEvent("Change", OnPresetTabChange)
    presetTab.OnEvent("ContextMenu", OnPresetTabRightClick)

    myGui.SetFont("s9 " faint, MUI_FontName)
    myGui.AddText("x408 y24 w144 h20 Right", L("main.renameHint"))

    ; 主题切换（按钮上显示点击后会切到的主题）
    themeButton := ModernButton(myGui, 556, 16, 78, 32
        , MUI_Theme = "dark" ? L("main.theme.toLight") : L("main.theme.toDark")
        , "secondary", {bg: MUI_T.window, fontSize: 9, radius: 8})
    themeButton.OnEvent("Click", ToggleTheme)
    themeButton.ctrl.ToolTip := L("main.theme.tip")

    ; 界面语言切换（同样显示点击后会切到的语言：中文 ⇄ English）
    langButton := ModernButton(myGui, 642, 16, 66, 32, Lang_SwitchButtonText()
        , "secondary", {bg: MUI_T.window, fontSize: 9, radius: 8})
    langButton.OnEvent("Click", ToggleLanguage)
    langButton.ctrl.ToolTip := L("main.lang.tip")

    ; ========== 按键宏设置卡片 ==========
    MUI_AddCard(myGui, 12, 64, 696, 300)
    myGui.SetFont("s11 bold " title, MUI_FontName)
    myGui.AddText("x32 y78 w200 h24 " MUI_CardBg, L("main.section.skills"))

    ; 列标题
    myGui.SetFont("s9 bold " muted, MUI_FontName)
    myGui.AddText("x130 y108 w75 center " MUI_CardBg, L("main.col.hotkey"))
    myGui.AddText("x215 y108 w95 center " MUI_CardBg, L("main.col.strategy"))
    myGui.AddText("x320 y108 w125 center " MUI_CardBg, L("main.col.interval"))
    myGui.AddText("x450 y108 w100 center " MUI_CardBg, L("main.col.delay"))
    myGui.AddText("x555 y108 w70 center " MUI_CardBg, L("main.col.random"))

    ; 创建技能行
    myGui.SetFont("s10 norm " text, MUI_FontName)
    CreateSkillRows()

    ; ========== 额外设置卡片 ==========
    MUI_AddCard(myGui, 12, 376, 696, 284)
    myGui.SetFont("s11 bold " title, MUI_FontName)
    myGui.AddText("x32 y390 w200 h24 " MUI_CardBg, L("main.section.extra"))
    myGui.SetFont("s10 norm " text, MUI_FontName)
    CreateExtraSettings()

    ; ========== 底部控制卡片 ==========
    MUI_AddCard(myGui, 12, 672, 696, 60)
    myGui.SetFont("s11 bold", MUI_FontName)
    statusText := myGui.AddText("x32 y690 w180 h26 " MUI_CardBg, L("main.status.prefix") L("state.idle"))
    statusText.SetFont(muted)  ; 初始未运行=灰

    myGui.SetFont("s9 norm " text, MUI_FontName)
    myGui.AddText("x212 y693 w50 h22 right " MUI_CardBg, L("main.toggle.label"))
    startStopHotkeyCtrl := myGui.AddHotkey("x266 y688 w70", "F1")
    startStopMouseCtrl := myGui.AddDropDownList("x342 y688 w80 Choose1"
        , [L("main.toggle.keyboard"), L("main.toggle.middle"), L("main.toggle.side1"), L("main.toggle.side2")])

    startStopButton := ModernButton(myGui, 434, 682, 160, 40, L("main.start") "  (F1)", "primary", {fontSize: 11, radius: 10})
    startStopButton.OnEvent("Click", ToggleMacro)
    ModernButton(myGui, 602, 682, 94, 40, L("main.save"), "secondary", {fontSize: 10, radius: 10}).OnEvent("Click", SaveSettings)

    startStopHotkeyCtrl.OnEvent("Change", OnStartStopKeyboardChanged)
    startStopMouseCtrl.OnEvent("Change", OnStartStopMouseChanged)

    myGui.SetFont("s9 " faint, MUI_FontName)
    myGui.AddText("x16 y740 w688 h20", L("main.hint"))
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar, MUI_T, MUI_FontName

    ; 日志开关与轮转要在最早的日志写入之前初始化
    InitLogging()

    ; 全局异常兜底：记录并抑制错误弹窗，避免定时器线程因异常弹出对话框
    OnError(GlobalErrorHandler)

    ; 创建主GUI
    CreateMainGUI()

    ; 底部状态条（用 Text 代替 StatusBar，以便跟随主题配色）
    footerOpt := " +0x200 Background" MUI_Hex(MUI_T.footer)
    myGui.SetFont("s9 norm c" MUI_Hex(MUI_T.muted), MUI_FontName)
    myGui.AddText("x0 y762 w720 h28" footerOpt, "")
    statusBar := myGui.AddText("x14 y762 w700 h28" footerOpt, L("main.ready"))
    MUI_ApplyNativeTheme(myGui)

    ; 先加载设置（在Show之前，避免Tab2内的DropDownList渲染不刷新）
    LoadSettings()
    RegisterStartStopHotkey()

    ; 显示GUI（此时下拉框值已正确设置，首次渲染即为正确状态）
    myGui.Show("w720 h794")

    ; 强制重绘窗口，确保所有控件（尤其是Tab2内的DropDownList）正确显示
    WinRedraw(myGui.Hwnd)

    ; 设置窗口事件处理 - 退出时自动保存
    myGui.OnEvent("Close", OnGuiClose)
    myGui.OnEvent("Escape", OnGuiClose)

    ; 退出兜底：停止定时器并释放所有被按住的按键，避免退出后游戏里按键卡住
    OnExit(CleanupOnExit)
}

/**
 * 全局异常处理：写日志并抑制错误弹窗
 * 定时器/热键线程里未捕获的异常如果冒泡到默认处理器，会弹窗打断宏的运行
 * @param {Object} err - Error 对象
 * @param {String} mode - 出错时的执行模式
 * @returns {Boolean} - true 表示已处理，不再弹窗
 */
GlobalErrorHandler(err, mode) {
    global isRunning

    try {
        LogError("未处理异常 [" mode "] " err.Message
            . " | 位置: " (err.File = "" ? "?" : err.File) ":" err.Line
            . " | 宏运行中: " (isRunning ? "是" : "否"))
    } catch {
        ; 记录异常时再次出错，忽略（避免死循环）
    }

    return true
}

/**
 * 根据运行状态更新开始/停止按钮（运行中显示红色“停止”）
 */
UpdateStartStopButton() {
    global startStopButton, isRunning
    if (startStopButton = "")
        return
    key := GetStartStopHotkeyDisplay()
    startStopButton.Text := (isRunning ? L("main.stop") : L("main.start")) . "  (" . key . ")"
    startStopButton.SetStyle(isRunning ? "danger" : "primary")
}

/**
 * 切换浅色/深色主题（保存后重新加载脚本生效）
 */
ToggleTheme(*) {
    global isRunning, statusBar, MUI_Theme
    if (isRunning) {
        statusBar.Text := L("status.themeStopFirst")
        return
    }
    try {
        SaveSettings()
        IniWrite(MUI_Theme = "dark" ? "light" : "dark", A_ScriptDir "\settings.ini", "UI", "Theme")
    } catch as err {
        statusBar.Text := L("status.themeFailed", err.Message)
        DebugLog("切换主题失败: " . err.Message)
        return
    }
    Reload()
}

/**
 * 切换界面语言（保存后重新加载脚本生效）
 * 与切换主题同一套路：宏运行中不允许，避免运行中被重载打断
 */
ToggleLanguage(*) {
    global isRunning, statusBar, appLang
    if (isRunning) {
        statusBar.Text := L("status.langStopFirst")
        return
    }
    try {
        appLang := (appLang = "zh") ? "en" : "zh"
        SaveSettings()   ; SaveGeneralSettings 会把 [UI] Language 一起写入
    } catch as err {
        statusBar.Text := L("status.langFailed", err.Message)
        DebugLog("切换语言失败: " . err.Message)
        return
    }
    Reload()
}

/**
 * GUI关闭事件处理 - 退出前自动保存设置
 */
OnGuiClose(*) {
    try {
        SaveSettings()
        DebugLog("退出前已自动保存设置")
    } catch as err {
        DebugLog("退出前保存设置失败: " err.Message)
    }
    ExitApp()
}
