; ========== 全局变量定义 ==========
; 核心状态变量
global DEBUG := true
global debugLogFile := A_ScriptDir "\debugd4.log"
global isRunning := false
global isPaused := false
global previouslyPaused := false
global counter := 0

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
global skillActiveState := false
global mouseAutoMoveEnabled := false
global mouseAutoMoveCurrentPoint := 1
global pauseOnClickEnabled := false  ; 添加鼠标点击暂停功能状态变量
global temporaryPaused := false      ; 添加临时暂停状态变量

; 技能模式常量
global SKILL_MODE_CLICK := 1    ; 连点模式
global SKILL_MODE_BUFF := 2     ; 维持BUFF模式
global SKILL_MODE_HOLD := 3     ; 按住模式
global skillModeNames := ["连点", "维持BUFF", "按住"]

; 技能位置映射
global skillPositions := Map(
    1, {x: 1035, y: 1290},
    2, {x: 1035 + 84, y: 1290},
    3, {x: 1035 + 84 * 2, y: 1290},
    4, {x: 1035 + 84 * 3, y: 1290},
    "left", {x: 1035 + 84 * 4, y: 1290},
    "right", {x: 1035 + 84 * 5, y: 1290}
)

; 定时器相关变量
global boundSkillTimers := Map()  ; 存储绑定的技能定时器函数
global timerStates := Map()       ; 用于跟踪定时器状态

; 控件变量
global forceMove := {}            ; 强制移动控件
global mouseAutoMove := {}        ; 鼠标自动移动控件
global pauseOnClick := {}         ; 鼠标点击暂停控件