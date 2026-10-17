; ========== 技能控件（仿D3keyHelper表格风格） ==========
/**
 * 创建技能行（4个技能 + 左键技能 + 右键技能）
 * 每行包含：标签、快捷键、策略下拉框、执行间隔、延迟、延迟随机
 */
CreateSkillRows() {
    global myGui, skillControls, mouseControls, strategyNames

    skillControls := Map()

    ; 行标签（文案随界面语言）
    skillLabels := [L("skill.1"), L("skill.2"), L("skill.3"), L("skill.4"), L("skill.left"), L("skill.right")]
    defaultKeys := ["1", "2", "3", "4", "LButton", "RButton"]

    Loop 6 {
        yPos := 134 + (A_Index - 1) * 38
        row := A_Index

        ; 行标签
        myGui.AddText("x25 y" (yPos + 4) " w95 right" MUI_CardBg, skillLabels[row])

        ; 快捷键（技能1-4用Hotkey；左右键用可输入的下拉框：下拉选鼠标左/右键，或直接输入键名）
        if (row <= 4) {
            keyCtrl := myGui.AddHotkey("x130 y" yPos " w75", defaultKeys[row])
        } else {
            keyCtrl := myGui.AddComboBox("x130 y" yPos " w75", GetMouseSlotKeyNames())
            SetMouseSlotKey(keyCtrl, defaultKeys[row])
            keyCtrl.ToolTip := L("mouseKey.tip")
            keyCtrl.OnEvent("Change", OnMouseSlotKeyChange)
            keyCtrl.OnEvent("LoseFocus", OnMouseSlotKeyBlur)
        }

        ; 策略下拉框（禁用/连点/维持BUFF/按住；名称随语言，存盘用的是序号）
        strategyCtrl := myGui.AddDropDownList("x215 y" yPos " w95 Choose1", strategyNames)

        ; 执行间隔（Edit + UpDown）
        intervalEdit := myGui.AddEdit("x325 y" yPos " w115 Number", "300")
        intervalUpDown := myGui.AddUpDown("0x80 Range20-60000", 300)

        ; 延迟（Edit + UpDown）
        delayEdit := myGui.AddEdit("x455 y" yPos " w85", "10")
        delayUpDown := myGui.AddUpDown("0x80 Range-30000-30000", 10)

        ; 延迟随机复选框
        randomCheck := myGui.AddCheckbox("x575 y" (yPos + 4) " Checked" MUI_CardBg, "")

        ; 构造行数据对象
        rowData := {
            key: keyCtrl,
            strategy: strategyCtrl,
            interval: intervalEdit,
            intervalUpDown: intervalUpDown,
            delay: delayEdit,
            delayUpDown: delayUpDown,
            random: randomCheck
        }

        ; 存储到对应的控件集合
        ; 注册按键变更的自动保存事件
        keyCtrl.OnEvent("Change", ScheduleAutoSave)

        if (row <= 4) {
            skillControls[row] := rowData
        } else if (row = 5) {
            mouseControls := {}
            mouseControls.left := rowData
        } else {
            mouseControls.right := rowData
        }

        ; 注册通用自动保存事件
        strategyCtrl.OnEvent("Change", ScheduleAutoSave)
        intervalEdit.OnEvent("Change", ScheduleAutoSave)
        delayEdit.OnEvent("Change", ScheduleAutoSave)
        randomCheck.OnEvent("Click", ScheduleAutoSave)
    }
}