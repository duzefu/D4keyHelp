; ========== 全局变量定义 ==========
; 核心状态变量
global DEBUG := true
global debugLogFile := A_ScriptDir "\debugd4.log"
global LOG_VERBOSE := false              ; 是否记录高频明细日志（每次按键）
global LOG_MAX_BYTES := 2 * 1024 * 1024  ; 单个日志文件大小上限，超过则轮转
global logWriteCount := 0                ; 写入计数（用于降低大小检查频率）
global isRunning := false
global isPaused := false
global previouslyPaused := false

; GUI相关变量
global myGui := ""
global statusText := ""
global statusBar := ""
global skillControls := Map()
global skillBuffControls := Map()
global mouseControls := {}
global utilityControls := {}

; 功能状态变量
global shiftEnabled := false
global mouseAutoMoveEnabled := false
global mouseAutoMoveCurrentPoint := 1
global pauseOnClickEnabled := false  ; 添加鼠标点击暂停功能状态变量
global temporaryPaused := false      ; 添加临时暂停状态变量
global compassEnabled := false       ; 罗盘专用功能状态变量
global compassPaused := false        ; 罗盘操作时的暂停状态
global isAutoTransmuting := false    ; 自动嬗变运行状态（F3再次按下可取消）

; 技能模式常量
global SKILL_MODE_CLICK := 1    ; 连点模式
global SKILL_MODE_BUFF := 2     ; 维持BUFF模式
global SKILL_MODE_HOLD := 3     ; 按住模式
; 名称随界面语言变化，只用于显示；逻辑判定一律用上面的模式编号
global skillModeNames := [L("strategy.click"), L("strategy.buff"), L("strategy.hold")]

; 策略下拉框选项（禁用=1, 连点=2, 维持BUFF=3, 按住=4）
; 存到 settings.ini 的是下拉框序号，所以翻译不会影响已有配置
global strategyNames := [L("strategy.off"), L("strategy.click"), L("strategy.buff"), L("strategy.hold")]

; 条件喝药（血量检测）
global healthCheckEnabled := false                                  ; 是否启用血量检测
global healthStatusText := ""                                       ; 界面上显示血量/识别结果的控件
global healthLastState := ""                                        ; 最近一次识别状态：ok / shield / fail
global healthLastPct := -1                                          ; 最近一次血量读数
global healthUiTick := 0                                            ; 界面文本刷新节流时间戳
global healthUiState := ""                                          ; 界面上一次显示的状态（变化时立即刷新）
global healthCacheTick := 0                                         ; 血球识别结果的缓存时间
global healthCacheState := ""                                       ; 血球识别结果缓存
global HEALTH_CACHE_MS := 500                                       ; 识别结果缓存时长，避免喝药间隔过小时反复截图
global lastPotionTick := 0                                          ; 上次喝药时间（防止连按）

; 动作栏（技能栏）槽位坐标：不再写死在 2K 上，改为按屏幕尺寸推算
; 标定值与算法见 functions/SkillSystem.ahk 顶部注释和 GetSkillSlotPos()

; 定时器相关变量
global boundSkillTimers := Map()       ; 存储绑定的技能定时器函数
global boundCheckHoldTimers := Map()   ; 存储绑定的Hold模式检查定时器（用于SetTimer停止）
global timerStates := Map()            ; 用于跟踪定时器状态

; Hold模式按键状态（在PressSkill/CheckHoldKey/ResetAllHoldKeyStates之间共享）
global holdKeyStates := Map()
global mouseHoldStates := Map("left", false, "right", false)

; 全局热键设置（不随预设切换）
global startStopHotkey := "F1"
global startStopHotkeyCtrl := ""
global startStopMouseCtrl := ""
global startStopButton := ""
global hotkeyChangeInProgress := false
global registeredStartStopHotkey := ""

; 控件变量
global mouseAutoMove := {}        ; 鼠标自动移动控件
global pauseOnClick := {}         ; 鼠标点击暂停控件
global compassControl := {}       ; 罗盘专用控件

; 预设配置变量
global currentPreset := 1                                    ; 当前选中的预设索引 (1-4)
global presetNames := [L("preset.default", 1), L("preset.default", 2)
    , L("preset.default", 3), L("preset.default", 4)]        ; 预设名称数组（默认名跟随界面语言）
global presetTab := ""                                         ; 预设Tab控件
global suppressTabChange := false                              ; 抑制Tab切换事件标志
