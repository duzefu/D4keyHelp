; ========== 日志功能 ==========
/**
 * 调试日志记录函数
 * @param {String} message - 要记录的消息
 */
DebugLog(message) {
    global DEBUG, debugLogFile
    if DEBUG {
        try {
            timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
            FileAppend timestamp " - " message "`n", debugLogFile
        } catch as err {
            ; 如果日志写入失败，不要让程序崩溃
            OutputDebug "日志写入失败: " err.Message
        }
    }
}