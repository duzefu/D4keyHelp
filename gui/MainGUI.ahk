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
    myGui := Gui("", "暗黑4助手 v2.4")
    myGui.BackColor := MUI_Hex(MUI_T.window)
    myGui.SetFont("s10 " text, MUI_FontName)
    myGui.MarginX := 12
    myGui.MarginY := 12

    ; ========== 预设分段选择器 ==========
    presetTab := ModernSegmented(myGui, 12, 12, 100, 40, presetNames)
    presetTab.OnEvent("Change", OnPresetTabChange)
    presetTab.OnEvent("ContextMenu", OnPresetTabRightClick)

    myGui.SetFont("s9 " faint, MUI_FontName)
    myGui.AddText("x440 y24 w160 h20 Right", "右键配置名可重命名")

    ; 主题切换
    ModernButton(myGui, 612, 16, 96, 32, MUI_Theme = "dark" ? "浅色模式" : "深色模式", "secondary", {bg: MUI_T.window, fontSize: 9, radius: 8})
        .OnEvent("Click", ToggleTheme)

    ; ========== 按键宏设置卡片 ==========
    MUI_AddCard(myGui, 12, 64, 696, 300)
    myGui.SetFont("s11 bold " title, MUI_FontName)
    myGui.AddText("x32 y78 w200 h24 " MUI_CardBg, "按键宏设置")

    ; 列标题
    myGui.SetFont("s9 bold " muted, MUI_FontName)
    myGui.AddText("x130 y108 w75 center " MUI_CardBg, "快捷键")
    myGui.AddText("x215 y108 w95 center " MUI_CardBg, "策略")
    myGui.AddText("x320 y108 w125 center " MUI_CardBg, "执行间隔 (ms)")
    myGui.AddText("x450 y108 w100 center " MUI_CardBg, "延迟 (ms)")
    myGui.AddText("x555 y108 w70 center " MUI_CardBg, "延迟随机")

    ; 创建技能行
    myGui.SetFont("s10 norm " text, MUI_FontName)
    CreateSkillRows()

    ; ========== 额外设置卡片 ==========
    MUI_AddCard(myGui, 12, 376, 696, 252)
    myGui.SetFont("s11 bold " title, MUI_FontName)
    myGui.AddText("x32 y390 w200 h24 " MUI_CardBg, "额外设置")
    myGui.SetFont("s10 norm " text, MUI_FontName)
    CreateExtraSettings()

    ; ========== 底部控制卡片 ==========
    MUI_AddCard(myGui, 12, 640, 696, 60)
    myGui.SetFont("s11 bold", MUI_FontName)
    statusText := myGui.AddText("x32 y658 w180 h26 " MUI_CardBg, "● 状态: 未运行")
    statusText.SetFont(muted)  ; 初始未运行=灰

    myGui.SetFont("s9 norm " text, MUI_FontName)
    myGui.AddText("x212 y661 w50 h22 right " MUI_CardBg, "启停：")
    startStopHotkeyCtrl := myGui.AddHotkey("x266 y656 w70", "F1")
    startStopMouseCtrl := myGui.AddDropDownList("x342 y656 w80 Choose1", ["键盘", "中键", "侧键1", "侧键2"])

    startStopButton := ModernButton(myGui, 434, 650, 160, 40, "开始  (F1)", "primary", {fontSize: 11, radius: 10})
    startStopButton.OnEvent("Click", ToggleMacro)
    ModernButton(myGui, 602, 650, 94, 40, "保存设置", "secondary", {fontSize: 10, radius: 10}).OnEvent("Click", SaveSettings)

    startStopHotkeyCtrl.OnEvent("Change", OnStartStopKeyboardChanged)
    startStopMouseCtrl.OnEvent("Change", OnStartStopMouseChanged)

    myGui.SetFont("s9 " faint, MUI_FontName)
    myGui.AddText("x16 y708 w688 h20", "提示：启停键可配置 | F3 自动嬗变/取消（魔盒界面）| Tab 查看地图暂停 | 仅暗黑4窗口生效")
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar, MUI_T, MUI_FontName

    ; 日志开关与轮转要在最早的日志写入之前初始化
    InitLogging()

    ; 创建主GUI
    CreateMainGUI()

    ; 底部状态条（用 Text 代替 StatusBar，以便跟随主题配色）
    footerOpt := " +0x200 Background" MUI_Hex(MUI_T.footer)
    myGui.SetFont("s9 norm c" MUI_Hex(MUI_T.muted), MUI_FontName)
    myGui.AddText("x0 y732 w720 h28" footerOpt, "")
    statusBar := myGui.AddText("x14 y732 w700 h28" footerOpt, "就绪")
    MUI_ApplyNativeTheme(myGui)

    ; 先加载设置（在Show之前，避免Tab2内的DropDownList渲染不刷新）
    LoadSettings()
    RegisterStartStopHotkey()

    ; 显示GUI（此时下拉框值已正确设置，首次渲染即为正确状态）
    myGui.Show("w720 h760")

    ; 强制重绘窗口，确保所有控件（尤其是Tab2内的DropDownList）正确显示
    WinRedraw(myGui.Hwnd)

    ; 设置窗口事件处理 - 退出时自动保存
    myGui.OnEvent("Close", OnGuiClose)
    myGui.OnEvent("Escape", OnGuiClose)
}

/**
 * 根据运行状态更新开始/停止按钮（运行中显示红色“停止”）
 */
UpdateStartStopButton() {
    global startStopButton, isRunning
    if (startStopButton = "")
        return
    key := GetStartStopHotkeyDisplay()
    startStopButton.Text := (isRunning ? "停止  (" : "开始  (") . key . ")"
    startStopButton.SetStyle(isRunning ? "danger" : "primary")
}

/**
 * 切换浅色/深色主题（保存后重新加载脚本生效）
 */
ToggleTheme(*) {
    global isRunning, statusBar, MUI_Theme
    if (isRunning) {
        statusBar.Text := "请先停止宏再切换主题"
        return
    }
    try {
        SaveSettings()
        IniWrite(MUI_Theme = "dark" ? "light" : "dark", A_ScriptDir "\settings.ini", "UI", "Theme")
    } catch as err {
        statusBar.Text := "切换主题失败: " . err.Message
        DebugLog("切换主题失败: " . err.Message)
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
