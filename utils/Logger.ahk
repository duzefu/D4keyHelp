; ========== 日志功能 ==========
; 三层控制，避免日志无限增长：
;   1) DEBUG 总开关（settings.ini [General] DebugLog，界面里可勾选）
;   2) 日志级别：1=关键（启停、保存、状态切换、错误），2=高频明细（每次按键）
;      高频明细由 LOG_VERBOSE 控制，默认关闭
;   3) 单文件超过 LOG_MAX_BYTES 时自动轮转为 debugd4.old.log

/**
 * 初始化日志设置（启动时调用，早于其他日志写入）
 * 同时检查一次日志大小，避免上次运行留下的超大日志继续增长
 */
InitLogging() {
    global DEBUG, LOG_VERBOSE
    settingsFile := A_ScriptDir "\settings.ini"

    try {
        DEBUG := (IniRead(settingsFile, "General", "DebugLog", 1) = 1)
        LOG_VERBOSE := (IniRead(settingsFile, "General", "DebugLogVerbose", 0) = 1)
    } catch {
        DEBUG := true
        LOG_VERBOSE := false
    }

    RotateLogIfNeeded()
    WriteLogLine("日志初始化 - 记录日志: " (DEBUG ? "开启" : "关闭")
        . "，明细日志: " (LOG_VERBOSE ? "开启" : "关闭"))
}

/**
 * 调试日志记录函数
 * @param {String} message - 要记录的消息
 * @param {Integer} level - 1=关键信息（默认），2=高频明细（仅在开启明细日志时记录）
 */
DebugLog(message, level := 1) {
    global DEBUG, LOG_VERBOSE
    if (!DEBUG || (level >= 2 && !LOG_VERBOSE))
        return
    WriteLogLine(message)
}

/**
 * 错误日志：不受 DEBUG 开关影响，保证异常一定能留下记录
 */
LogError(message) {
    WriteLogLine("[错误] " message)
}

/**
 * 实际写入一行日志（并定期检查是否需要轮转）
 */
WriteLogLine(message) {
    global debugLogFile, logWriteCount
    try {
        timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
        FileAppend timestamp " - " message "`n", debugLogFile

        ; 每 200 行检查一次大小，避免频繁读取文件属性
        logWriteCount += 1
        if (logWriteCount >= 200) {
            logWriteCount := 0
            RotateLogIfNeeded()
        }
    } catch as err {
        ; 如果日志写入失败，不要让程序崩溃
        OutputDebug "日志写入失败: " err.Message
    }
}

/**
 * 日志超过上限时轮转为 debugd4.old.log（只保留一份历史）
 */
RotateLogIfNeeded() {
    global debugLogFile, logWriteCount, LOG_MAX_BYTES
    logWriteCount := 0

    try {
        if (!FileExist(debugLogFile))
            return
        if (FileGetSize(debugLogFile) < LOG_MAX_BYTES)
            return

        oldFile := A_ScriptDir "\debugd4.old.log"
        if FileExist(oldFile)
            FileDelete oldFile
        FileMove debugLogFile, oldFile

        FileAppend FormatTime(, "yyyy-MM-dd HH:mm:ss")
            . " - 日志超过 " Round(LOG_MAX_BYTES / 1024 / 1024, 1) "MB，已轮转为 debugd4.old.log`n", debugLogFile
    } catch as err {
        OutputDebug "日志轮转失败: " err.Message
    }
}

/**
 * 清理超大的历史日志（界面提供的手动清理入口）
 * @returns {Integer} 清理掉的字节数
 */
ClearLogs() {
    global debugLogFile, DEBUG
    freed := 0

    for file in [debugLogFile, A_ScriptDir "\debugd4.old.log"] {
        try {
            if FileExist(file) {
                freed += FileGetSize(file)
                FileDelete file
            }
        } catch as err {
            OutputDebug "删除日志失败: " err.Message
        }
    }

    ; 日志开关关闭时不再重新创建日志文件
    if DEBUG
        WriteLogLine("日志已清理，释放 " Round(freed / 1024, 1) "KB")

    return freed
}

/**
 * 切换调试日志开关（界面勾选框调用）
 * @param {Integer} enabled - 1=开启，0=关闭
 */
SetLogEnabled(enabled) {
    global DEBUG, logWriteCount
    newState := (enabled = 1)

    ; 用 WriteLogLine 记录切换动作本身，不受开关影响
    if (newState != DEBUG)
        WriteLogLine("调试日志已" (newState ? "开启" : "关闭"))

    DEBUG := newState
    logWriteCount := 199   ; 下次写入后立即做一次大小检查

    try {
        IniWrite(newState ? 1 : 0, A_ScriptDir "\settings.ini", "General", "DebugLog")
    } catch as err {
        OutputDebug "保存日志开关失败: " err.Message
    }

    return DEBUG
}
