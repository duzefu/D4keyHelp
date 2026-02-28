; ========== 技能控件（仿D3keyHelper表格风格） ==========
/**
 * 创建技能行（4个技能 + 左键技能 + 右键技能）
 * 每行包含：标签、快捷键、策略下拉框、执行间隔、延迟、延迟随机
 */
CreateSkillRows() {
    global myGui, skillControls, mouseControls, strategyNames

    skillControls := Map()

    ; 行标签
    skillLabels := ["技能一：", "技能二：", "技能三：", "技能四：", "左键技能：", "右键技能："]
    defaultKeys := ["1", "2", "3", "4", "LButton", "RButton"]

    Loop 6 {
        yPos := 82 + (A_Index - 1) * 34
        row := A_Index

        ; 行标签
        myGui.AddText("x25 y" (yPos + 3) " w85 right", skillLabels[row])

        ; 快捷键（技能1-4用Hotkey，左右键用禁用的Edit）
        if (row <= 4) {
            keyCtrl := myGui.AddHotkey("x115 y" yPos " w65", defaultKeys[row])
        } else {
            keyCtrl := myGui.AddEdit("x115 y" yPos " w65 Disabled", defaultKeys[row])
        }

        ; 策略下拉框（禁用/连点/维持BUFF/按住）
        strategyCtrl := myGui.AddDropDownList("x190 y" yPos " w85 Choose1", strategyNames)

        ; 执行间隔（Edit + UpDown）
        intervalEdit := myGui.AddEdit("x290 y" yPos " w110 Number", "300")
        intervalUpDown := myGui.AddUpDown("Range20-60000", 300)

        ; 延迟（Edit + UpDown）
        delayEdit := myGui.AddEdit("x420 y" yPos " w75", "10")
        delayUpDown := myGui.AddUpDown("Range-30000-30000", 10)

        ; 延迟随机复选框
        randomCheck := myGui.AddCheckbox("x520 y" (yPos + 2) " Checked", "")

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
        if (row <= 4) {
            skillControls[row] := rowData

            ; 注册自动保存事件
            skillControls[row].key.OnEvent("Change", ScheduleAutoSave)
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