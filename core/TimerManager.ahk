; ========== 定时器管理 ==========
/**
 * 启动所有定时器
 */
StartAllTimers() {
    ; 先停止所有定时器，确保清理
    StopAllTimers()

    ; 启动技能定时器
    StartSkillTimers()

    ; 启动鼠标和功能键定时器
    StartUtilityTimers()

    ; 启动鼠标自动移动定时器
    StartMouseAutoMoveTimer()

    DebugLog("所有定时器已启动")
}

/**
 * 启动技能定时器
 */
StartSkillTimers() {
    global skillControls, boundSkillTimers, timerStates

    for i in [1, 2, 3, 4] {
        if (skillControls[i].enable.Value = 1) {
            interval := Integer(skillControls[i].interval.Value)
            if (interval > 0) {
                boundSkillTimers[i] := PressSkill.Bind(i)
                SetTimer(boundSkillTimers[i], interval)
                timerStates[i] := true
                DebugLog("启动技能" i "定时器，间隔: " interval)
            }
        }
    }
}

/**
 * 启动鼠标和功能键定时器
 */
StartUtilityTimers() {
    StartSingleTimer("leftClick", mouseControls.left, PressLeftClick)
    StartSingleTimer("rightClick", mouseControls.right, PressRightClick)
    StartSingleTimer("dodge", utilityControls.dodge, PressDodge)
    StartSingleTimer("potion", utilityControls.potion, PressPotion)
    StartSingleTimer("forceMove", utilityControls.forceMove, PressForceMove)
}

/**
 * 启动鼠标自动移动定时器
 */
StartMouseAutoMoveTimer() {
    global mouseAutoMoveEnabled, mouseAutoMove, timerStates

    DebugLog("鼠标自动移动状态: " . (mouseAutoMoveEnabled ? "启用" : "禁用") . ", GUI勾选状态: " . mouseAutoMove.enable.Value)

    if (mouseAutoMoveEnabled) {
        interval := Integer(mouseAutoMove.interval.Value)
        if (interval > 0) {
            SetTimer(MoveMouseToNextPoint, interval)
            timerStates["mouseAutoMove"] := true
            DebugLog("启动鼠标自动移动定时器 - 间隔: " interval)
        }
    }
}

/**
 * 启动单个定时器
 * @param {String} name - 定时器名称
 * @param {Object} control - 控件对象
 * @param {Function} timerFunc - 定时器函数
 */
StartSingleTimer(name, control, timerFunc) {
    global timerStates

    if (control.enable.Value = 1) {
        interval := Integer(control.interval.Value)
        if (interval > 0) {
            SetTimer(timerFunc, interval)
            timerStates[name] := true
            DebugLog("启动" name "定时器 - 间隔: " interval)
        }
    }
}

/**
 * 停止所有定时器
 */
StopAllTimers() {
    global boundSkillTimers, skillControls

    ; 停止技能定时器
    Loop 4 {
        if boundSkillTimers.Has(A_Index) {
            SetTimer(boundSkillTimers[A_Index], 0)
            boundSkillTimers.Delete(A_Index)
            DebugLog("停止技能" A_Index "定时器")
        }

        ; 如果是按住模式，确保释放按键
        key := skillControls[A_Index].key.Value
        if (key != "") {
            Send "{" key " up}"
        }
    }

    ; 停止所有其他定时器
    SetTimer PressLeftClick, 0
    SetTimer PressRightClick, 0
    SetTimer PressDodge, 0
    SetTimer PressPotion, 0
    SetTimer PressForceMove, 0
    SetTimer MoveMouseToNextPoint, 0
    SetTimer ResumeAfterClickPause, 0  ; 停止临时暂停的恢复定时器

    ; 重置所有按住模式的按键状态
    ResetAllHoldKeyStates()

    ; 重置鼠标按键状态
    ResetMouseButtonStates()

    DebugLog("已停止所有定时器并释放按键")
}