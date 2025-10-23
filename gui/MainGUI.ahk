; ========== GUI创建 ==========
/**
 * 创建主GUI界面
 */
CreateMainGUI() {
    global myGui, statusText, statusBar

    ; 创建主窗口
    myGui := Gui("", "暗黑4助手 v2.1")
    myGui.BackColor := "FFFFFF"
    myGui.SetFont("s10", "Microsoft YaHei UI")

    ; 添加主要内容区域
    myGui.AddGroupBox("x10 y10 w460 h120", "状态")
    statusText := myGui.AddText("x30 y35 w200 h20", "状态: 未运行")
    myGui.AddButton("x30 y65 w120 h30", "开始/停止(F1)").OnEvent("Click", ToggleMacro)
    myGui.AddText("x30 y100 w300 h20", "提示：仅在暗黑破坏神4窗口活动时生效")

    ; 添加技能设置区域
    myGui.AddGroupBox("x10 y140 w460 h350", "键设置")

    ; 添加Shift键勾选框
    myGui.AddCheckbox("x30 y165 w100 h20", "按住Shift").OnEvent("Click", ToggleShift)

    ; 添加列标题
    myGui.AddText("x30 y195 w60 h20", "按键")
    myGui.AddText("x130 y195 w60 h20", "启用")
    myGui.AddText("x200 y195 w120 h20", "间隔(毫秒)")
}

/**
 * 初始化GUI
 */
InitializeGUI() {
    global myGui, statusBar

    ; 创建主GUI
    CreateMainGUI()

    ; 创建各种控件
    CreateSkillControls()
    CreateMouseControls()
    CreateUtilityControls()

    ; 添加保存按钮
    myGui.AddButton("x30 y500 w100 h30", "保存设置").OnEvent("Click", SaveSettings)

    ; 添加状态栏
    statusBar := myGui.AddStatusBar(, "就绪")

    ; 显示GUI
    myGui.Show("w480 h550")

    ; 加载设置
    LoadSettings()

    ; 设置窗口事件处理
    myGui.OnEvent("Close", (*) => ExitApp())
    myGui.OnEvent("Escape", (*) => ExitApp())
}