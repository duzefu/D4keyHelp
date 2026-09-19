; 血球识别回归测试：用四张 2K 参考截图的真实像素跑一遍定位与血量估算
; 先跑 tests/ExportGlobeWindows.py 生成 tests/data/*.bin，再双击本脚本（或用 AutoHotkey64.exe 运行）
; 期望结果：screenShot=满血、screenShot2=护盾遮挡、lowblood≈26%、sample2=满血、live=满血
#Requires AutoHotkey v2.0
#SingleInstance Off
#NoTrayIcon

; 与应用一致的加载顺序（保证函数与全局变量都能解析，不产生加载期告警）
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

; 2K 下的取景参数，与 ExportGlobeWindows.py 保持一致
rad := 90
halfW := rad * 145 // 100
size := halfW * 2 + 1
stride := ((size * 3 + 3) // 4) * 4
originX := 685
originY := 1179
priorCx := 815
priorCy := 1324

report := A_ScriptDir "\result.txt"
if FileExist(report)
    FileDelete report

for name in ["screenShot", "screenShot2", "lowblood", "sample2", "live"] {
    binPath := A_ScriptDir "\data\" name ".bin"
    if !FileExist(binPath) {
        FileAppend name ": 缺少 " binPath "（先运行 ExportGlobeWindows.py）`n", report, "UTF-8"
        continue
    }

    bits := Buffer(stride * size + 8)
    f := FileOpen(binPath, "r")
    f.RawRead(bits, stride * size)
    f.Close()

    cap := {bits: bits, stride: stride, width: size, height: size
        , originX: originX, originY: originY, ok: 1}
    elapsed := A_TickCount
    r := AnalyzeHealthWindow(cap, rad, priorCx, priorCy)
    elapsed := A_TickCount - elapsed

    line := name ": state=" r.state " pct=" Round(r.pct) " 护盾占比=" Round(r.shield, 2)
        . " 球心=(" r.cx "," r.cy ") 液面y=" r.surface " 液体底y=" r.yB " 耗时=" elapsed "ms"
    if (r.reason != "")
        line .= " 备注=" r.reason
    FileAppend line "`n", report, "UTF-8"
}

FileAppend "done`n", report, "UTF-8"
ExitApp
