; ========== 技能控件 ==========
/**
 * 创建技能控件
 */
CreateSkillControls() {
    global myGui, skillControls, skillModeNames, SKILL_MODE_CLICK

    skillControls := Map()
    Loop 4 {
        yPos := 236 + (A_Index-1) * 30
        myGui.AddText("x35 y" yPos " w60 h20", "技能" A_Index ":")
        skillControls[A_Index] := {
            key: myGui.AddHotkey("x95 y" yPos " w35 h20", A_Index),
            enable: myGui.AddCheckbox("x135 y" yPos " w60 h20", "启用"),
            interval: myGui.AddEdit("x205 y" yPos " w60 h20", "300"),
            mode: myGui.AddDropDownList("x275 y" yPos " w100 h120 Choose1", skillModeNames)
        }
    }
}