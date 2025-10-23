; ========== 热键设置 ==========
#HotIf WinActive("ahk_class Diablo IV Main Window Class")

*F1::ToggleMacro()  ; * 表示忽略所有修饰键

Tab::{
    global isRunning, isPaused

    ; 发送原始Tab键
    Send "{Tab}"

    ; 如果宏未运行，不做其他处理
    if !isRunning
        return

    ; 切换暂停状态
    isPaused := !isPaused

    if isPaused {
        StopAllTimers()
        UpdateStatus("已暂停", "宏已暂停")
    } else {
        StartAllTimers()
        UpdateStatus("运行中", "宏已继续")
    }
}

; 添加鼠标钩子监听
LButton::
RButton::{
    global isRunning, isPaused, pauseOnClickEnabled, temporaryPaused, pauseOnClick
    
    ; 获取当前按键
    key := A_ThisHotkey = "LButton" ? "LButton" : "RButton"
    
    ; 发送原始鼠标按下事件（允许长按）
    Send "{" key " down}"
    
    ; 等待直到释放按键
    KeyWait key
    
    ; 发送释放事件
    Send "{" key " up}"

    ; 检查是否需要暂停宏
    if (isRunning && !isPaused && pauseOnClickEnabled) {
        ; 暂停宏
        StopAllTimers()
        temporaryPaused := true
        UpdateStatus("临时暂停", "检测到鼠标点击，宏临时暂停")
        DebugLog("检测到鼠标点击，临时暂停宏")
        
        ; 设置恢复定时器
        pauseInterval := Integer(pauseOnClick.interval.Value)
        SetTimer(ResumeAfterClickPause, pauseInterval)
    }
}

#HotIf

; 设置窗口状态检查定时器
SetTimer CheckWindow, 100