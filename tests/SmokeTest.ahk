; 冒烟测试：加载全部模块 + 创建界面，1.5 秒后自动退出
; 用来确认改动后「脚本能正常加载、界面能正常创建、设置能正常保存」
; 运行：AutoHotkey64.exe tests\SmokeTest.ahk，结果写在 tests\smoke_result.txt
#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon

; 与应用完全一致的模块加载顺序
#Include "..\core\GlobalVars.ahk"
#Include "..\utils\Logger.ahk"
#Include "..\utils\Settings.ahk"
#Include "..\core\WindowManager.ahk"
#Include "..\core\TimerManager.ahk"
#Include "..\core\MacroControl.ahk"
#Include "..\core\HotkeyManager.ahk"
#Include "..\gui\ModernUI.ahk"
#Include "..\gui\MainGUI.ahk"
#Include "..\gui\SkillControls.ahk"
#Include "..\gui\MouseControls.ahk"
#Include "..\functions\SkillSystem.ahk"
#Include "..\functions\MouseActions.ahk"
#Include "..\functions\UtilityActions.ahk"
#Include "..\functions\HealthGlobe.ahk"
#Include "..\functions\ConditionSystem.ahk"
#Include "..\hotkeys\GameHotkeys.ahk"

report := A_ScriptDir "\smoke_result.txt"
if FileExist(report)
    FileDelete report
Append(text) {
    global report
    FileAppend text "`n", report, "UTF-8"
}

try {
    InitializeGUI()
    Append "GUI 创建成功"
} catch as err {
    Append "GUI 创建失败: " err.Message " @" err.File ":" err.Line
}

; 两个按钮的回调直接调用一遍（不依赖点击）
try {
    TestHealthDetect()
    DetectHealthGlobeDelayed()
    Append "检测血球回调正常: " statusBar.Text
} catch as err {
    Append "检测血球按钮回调异常: " err.Message " @" err.File ":" err.Line
}
try {
    OnHealthCheckToggled({Value: 1}, 0)
    OnHealthCheckToggled({Value: 0}, 0)
    Append "血量检测开关回调正常"
} catch as err {
    Append "血量检测开关回调异常: " err.Message " @" err.File ":" err.Line
}
try {
    SaveSettings()
    Append "保存设置正常"
} catch as err {
    Append "保存设置异常: " err.Message " @" err.File ":" err.Line
}

SetTimer(Quit, -1500)
Quit(*) {
    global myGui
    try {
        myGui.Destroy()
    }
    ExitApp
}
