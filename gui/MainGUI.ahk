; ========== GUI创建（现代明亮风格） ==========
/**
 * 创建主GUI界面
 */
CreateMainGUI() {
    global myGui, statusText, statusBar, presetTab, presetNames, currentPreset

    ; 创建主窗口
    myGui := Gui("", "暗黑4助手 v2.1")
    myGui.BackColor := "F5F7FA"
    myGui.SetFont("s10", "Segoe UI")
    myGui.MarginX := 8
    myGui.MarginY := 10

    ; ========== Tab2预设配置区域 ==========
    presetTab := myGui.AddTab2("x5 y5 w710 h620", [presetNames[1], presetNames[2], presetNames[3], presetNames[4]])
    presetTab.OnEvent("Change", OnPresetTabChange)
    presetTab.OnEvent("ContextMenu", OnPresetTabRightClick)
    presetTab.UseTab(0)

    ; 右键重命名提示（放在标签页右侧）
    myGui.SetFont("s9 c9CA3AF", "Segoe UI")
    myGui.AddText("x310 y10 w390 h20 BackgroundTrans Right", "右键标签可重命名")

    ; ========== 按键宏设置 GroupBox ==========
    myGui.SetFont("s11 bold c1F2937", "Segoe UI")
    myGui.AddGroupBox("x15 y45 w690 h290", "  按键宏设置")

    ; 列标题（加粗+主色调）
    myGui.SetFont("s9 bold c2563EB", "Segoe UI")
    myGui.AddText("x130 y75 w75 center", "快捷键")
    myGui.AddText("x215 y75 w95 center", "策略")
    myGui.AddText("x320 y75 w125 center", "执行间隔 (ms)")
    myGui.AddText("x450 y75 w100 center", "延迟 (ms)")
    myGui.AddText("x555 y75 w70 center", "延迟随机")

    ; 创建技能行
    myGui.SetFont("s10 norm c1F2937", "Segoe UI")
    CreateSkillRows()

    ; ========== 额外设置 GroupBox ==========
    myGui.SetFont("s11 bold c1F2937", "Segoe UI")
    myGui.AddGroupBox("x15 y350 w690 h225", "  额外设置")
    myGui.SetFont("s10 norm c1F2937", "Segoe UI")
    CreateExtraSettings()

    ; ========== 底部状态和控制区域 ==========
    myGui.SetFont("s11 bold c10B981", "Segoe UI")
    statusText := myGui.AddText("x25 y593 w260 h26 BackgroundTrans", "● 状态: 未运行")
    statusText.SetFont("c6B7280")  ; 初始未运行=灰

    myGui.SetFont("s11 bold", "Segoe UI")
    myGui.AddButton("x340 y588 w140 h34 Default", "开始 / 停止  (F1)").OnEvent("Click", ToggleMacro)
    myGui.SetFont("s10 norm")
    myGui.AddButton("x495 y588 w100 h34", "保存设置").OnEvent("Click", SaveSettings)

    myGui.SetFont("s9 c6B7280", "Segoe UI")
    myGui.AddText("x25 y630 w680 h20 BackgroundTrans", "提示：F1 启停宏 | F3 自动嬗变/取消（魔盒界面）| Tab 查看地图暂停 | 仅暗黑4窗口生效")
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar

    ; 创建主GUI
    CreateMainGUI()

    ; 添加状态栏
    statusBar := myGui.AddStatusBar(, "就绪")

    ; 先加载设置（在Show之前，避免Tab2内的DropDownList渲染不刷新）
    LoadSettings()

    ; 显示GUI（此时下拉框值已正确设置，首次渲染即为正确状态）
    myGui.Show("w720 h680")

    ; 强制重绘窗口，确保所有控件（尤其是Tab2内的DropDownList）正确显示
    WinRedraw(myGui.Hwnd)

    ; 设置窗口事件处理 - 退出时自动保存
    myGui.OnEvent("Close", OnGuiClose)
    myGui.OnEvent("Escape", OnGuiClose)
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
