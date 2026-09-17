; ========== 现代化UI组件（GDI+ 绘制圆角按钮 / 卡片 / 分段选择器） ==========

global MUI_gdipToken := 0
global MUI_FontName := "Microsoft YaHei UI"
global MUI_CardBitmaps := []
global MUI_HotkeySubclassCb := 0

; 当前主题与调色板（RGB），由 MUI_SetTheme 设置
global MUI_Theme := "light"
global MUI_T := {}
global MUI_CardBg := ""     ; 卡片内 Text/Checkbox 的背景选项，如 " BackgroundFFFFFF"

MUI_Hex(color) {
    return Format("{:06X}", color)
}

/**
 * 读取保存的主题（light/dark）
 */
MUI_LoadThemeSetting(file) {
    theme := "light"
    try theme := IniRead(file, "UI", "Theme", "light")
    return (theme = "dark") ? "dark" : "light"
}

/**
 * 设置主题调色板与按钮样式（在创建 GUI 之前调用）
 */
MUI_SetTheme(name) {
    global MUI_Theme, MUI_T, MUI_CardBg
    MUI_Theme := (name = "dark") ? "dark" : "light"

    if (MUI_Theme = "dark") {
        MUI_T := {
            window: 0x18181B, card: 0x232326, cardBorder: 0x323238, segTrack: 0x2E2E33,
            title: 0xF4F4F5, text: 0xE4E4E7, muted: 0xA1A1AA, faint: 0x71717A,
            input: 0x2E2E33, inputText: 0xF4F4F5, footer: 0x131316
        }
        ModernButton.Styles := Map(
            "primary",   {fill: [0x2563EB, 0x1D4ED8, 0x1E40AF], text: 0xFFFFFF, border: "", bold: true},
            "danger",    {fill: [0xDC2626, 0xB91C1C, 0x991B1B], text: 0xFFFFFF, border: "", bold: true},
            "secondary", {fill: [0x2E2E33, 0x3A3A40, 0x46464D], text: 0xE4E4E7, border: 0x3F3F46, bold: false},
            "soft",      {fill: [0x1E2A44, 0x24345A, 0x2B3F6E], text: 0x93C5FD, border: "", bold: false},
            "segOn",     {fill: [0x45454D, 0x45454D, 0x4E4E57], text: 0xFFFFFF, border: "", bold: true},
            "segOff",    {fill: [0x2E2E33, 0x38383E, 0x42424A], text: 0xA1A1AA, border: "", bold: false}
        )
        ; 让下拉列表等系统弹出部分跟随深色（uxtheme 序号 135: SetPreferredAppMode, 2=ForceDark）
        try {
            hUx := DllCall("LoadLibrary", "Str", "uxtheme", "Ptr")
            if (pFn := DllCall("GetProcAddress", "Ptr", hUx, "Ptr", 135, "Ptr"))
                DllCall(pFn, "Int", 2)
        }
    } else {
        MUI_T := {
            window: 0xF3F4F6, card: 0xFFFFFF, cardBorder: 0xE5E7EB, segTrack: 0xE5E7EB,
            title: 0x111827, text: 0x1F2937, muted: 0x6B7280, faint: 0x9CA3AF,
            input: 0xFFFFFF, inputText: 0x1F2937, footer: 0xE5E7EB
        }
        ModernButton.Styles := Map(
            "primary",   {fill: [0x2563EB, 0x1D4ED8, 0x1E40AF], text: 0xFFFFFF, border: "", bold: true},
            "danger",    {fill: [0xEF4444, 0xDC2626, 0xB91C1C], text: 0xFFFFFF, border: "", bold: true},
            "secondary", {fill: [0xFFFFFF, 0xF3F4F6, 0xE5E7EB], text: 0x374151, border: 0xD1D5DB, bold: false},
            "soft",      {fill: [0xEFF6FF, 0xDBEAFE, 0xBFDBFE], text: 0x1D4ED8, border: "", bold: false},
            "segOn",     {fill: [0xFFFFFF, 0xFFFFFF, 0xF9FAFB], text: 0x2563EB, border: "", bold: true},
            "segOff",    {fill: [0xE5E7EB, 0xD7DAE0, 0xCBD0D8], text: 0x4B5563, border: "", bold: false}
        )
    }
    MUI_CardBg := " Background" MUI_Hex(MUI_T.card)
}

/**
 * 深色主题下处理原生控件（在所有控件创建完成后、Show 之前调用）
 */
MUI_ApplyNativeTheme(gui) {
    global MUI_Theme, MUI_T, MUI_HotkeySubclassCb
    if (MUI_Theme != "dark")
        return

    ; 深色标题栏（Win10 20H1+ 为 20，更早版本为 19）
    if DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", gui.Hwnd, "Int", 20, "Int*", 1, "Int", 4) != 0
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", gui.Hwnd, "Int", 19, "Int*", 1, "Int", 4)

    for ctrl in gui {
        switch ctrl.Type {
            case "Edit":
                ctrl.Opt("Background" MUI_Hex(MUI_T.input))
                ctrl.SetFont("c" MUI_Hex(MUI_T.inputText))
                DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
            case "DDL":
                DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
            case "UpDown":
                ; 去掉视觉样式，使用灰色经典箭头，避免亮白色块
                DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "", "Str", "")
            case "Hotkey":
                ; 系统快捷键控件不支持自定义颜色，改为子类化自绘
                if !MUI_HotkeySubclassCb
                    MUI_HotkeySubclassCb := CallbackCreate(MUI_HotkeySubclassProc, "F", 6)
                DllCall("comctl32\SetWindowSubclass", "Ptr", ctrl.Hwnd, "Ptr", MUI_HotkeySubclassCb, "UPtr", 1, "UPtr", 0)
                DllCall("uxtheme\SetWindowTheme", "Ptr", ctrl.Hwnd, "Str", "DarkMode_CFD", "Ptr", 0)
        }
    }
}

MUI_BGR(rgb) {
    return ((rgb & 0xFF) << 16) | (rgb & 0xFF00) | ((rgb >> 16) & 0xFF)
}

/**
 * 快捷键控件当前值的显示文本（与系统控件一致：修饰键 + 键名）
 */
MUI_HotkeyText(hwnd) {
    hk := DllCall("SendMessageW", "Ptr", hwnd, "UInt", 0x402, "Ptr", 0, "Ptr", 0, "Ptr")  ; HKM_GETHOTKEY
    vk := hk & 0xFF
    mods := (hk >> 8) & 0xFF
    if !vk
        return "无"
    text := ""
    if (mods & 0x2)
        text .= "Ctrl + "
    if (mods & 0x1)
        text .= "Shift + "
    if (mods & 0x4)
        text .= "Alt + "
    scan := DllCall("MapVirtualKeyW", "UInt", vk, "UInt", 0, "UInt")
    lp := (scan << 16) | ((mods & 0x8) ? (1 << 24) : 0)
    buf := Buffer(128, 0)
    if DllCall("GetKeyNameTextW", "Int", lp, "Ptr", buf, "Int", 64)
        name := StrGet(buf)
    else
        name := GetKeyName(Format("vk{:02X}", vk))
    return text . name
}

MUI_HotkeySubclassProc(hWnd, uMsg, wParam, lParam, uIdSubclass, dwRefData) {
    global MUI_T
    if (uMsg = 0x0014)  ; WM_ERASEBKGND
        return 1
    if (uMsg = 0x0085) {  ; WM_NCPAINT：边框改为深灰，避免系统绘制的白色 ClientEdge
        hdc := DllCall("GetWindowDC", "Ptr", hWnd, "Ptr")
        wr := Buffer(16, 0)
        DllCall("GetWindowRect", "Ptr", hWnd, "Ptr", wr)
        w := NumGet(wr, 8, "Int") - NumGet(wr, 0, "Int")
        h := NumGet(wr, 12, "Int") - NumGet(wr, 4, "Int")
        rc := Buffer(16, 0)
        ; 排除客户区，只绘制边框区域
        pt := Buffer(8, 0)
        DllCall("ClientToScreen", "Ptr", hWnd, "Ptr", pt)
        cx := NumGet(pt, 0, "Int") - NumGet(wr, 0, "Int")
        cy := NumGet(pt, 4, "Int") - NumGet(wr, 4, "Int")
        MUI_GetClientSize(hWnd, &cw, &ch)
        DllCall("ExcludeClipRect", "Ptr", hdc, "Int", cx, "Int", cy, "Int", cx + cw, "Int", cy + ch)
        NumPut("Int", 0, "Int", 0, "Int", w, "Int", h, rc)
        inner := DllCall("CreateSolidBrush", "UInt", MUI_BGR(MUI_T.input), "Ptr")
        outer := DllCall("CreateSolidBrush", "UInt", MUI_BGR(0x71717A), "Ptr")
        DllCall("FillRect", "Ptr", hdc, "Ptr", rc, "Ptr", inner)
        DllCall("FrameRect", "Ptr", hdc, "Ptr", rc, "Ptr", outer)
        DllCall("DeleteObject", "Ptr", inner)
        DllCall("DeleteObject", "Ptr", outer)
        DllCall("ReleaseDC", "Ptr", hWnd, "Ptr", hdc)
        return 0
    }
    if (uMsg = 0x000F) {  ; WM_PAINT
        ps := Buffer(A_PtrSize = 8 ? 72 : 64, 0)
        hdc := DllCall("BeginPaint", "Ptr", hWnd, "Ptr", ps, "Ptr")
        rc := Buffer(16, 0)
        DllCall("GetClientRect", "Ptr", hWnd, "Ptr", rc)
        brush := DllCall("CreateSolidBrush", "UInt", MUI_BGR(MUI_T.input), "Ptr")
        DllCall("FillRect", "Ptr", hdc, "Ptr", rc, "Ptr", brush)
        DllCall("DeleteObject", "Ptr", brush)

        hFont := DllCall("SendMessageW", "Ptr", hWnd, "UInt", 0x31, "Ptr", 0, "Ptr", 0, "Ptr")  ; WM_GETFONT
        oldFont := DllCall("SelectObject", "Ptr", hdc, "Ptr", hFont, "Ptr")
        DllCall("SetBkMode", "Ptr", hdc, "Int", 1)
        DllCall("SetTextColor", "Ptr", hdc, "UInt", MUI_BGR(MUI_T.inputText))

        text := MUI_HotkeyText(hWnd)
        pad := Round(2 * A_ScreenDPI / 96)
        NumPut("Int", pad, rc, 0)
        DllCall("DrawTextW", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", rc, "UInt", 0x824)  ; SINGLELINE|VCENTER|NOPREFIX

        ; 光标放在文字末尾
        calc := Buffer(16, 0)
        DllCall("DrawTextW", "Ptr", hdc, "Str", text, "Int", -1, "Ptr", calc, "UInt", 0xC20)  ; CALCRECT|SINGLELINE|NOPREFIX
        textH := NumGet(calc, 12, "Int")
        DllCall("SetCaretPos", "Int", pad + NumGet(calc, 8, "Int"), "Int", (NumGet(rc, 12, "Int") - textH) // 2)

        DllCall("SelectObject", "Ptr", hdc, "Ptr", oldFont)
        DllCall("EndPaint", "Ptr", hWnd, "Ptr", ps)
        return 0
    }
    return DllCall("comctl32\DefSubclassProc", "Ptr", hWnd, "UInt", uMsg, "Ptr", wParam, "Ptr", lParam, "Ptr")
}

/**
 * 启动 GDI+ 并注册鼠标消息（在创建 GUI 之前调用）
 */
MUI_Startup() {
    global MUI_gdipToken
    if MUI_gdipToken
        return
    DllCall("LoadLibrary", "Str", "gdiplus", "Ptr")
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", 1, si)
    token := 0
    DllCall("gdiplus\GdiplusStartup", "UPtr*", &token, "Ptr", si, "Ptr", 0)
    MUI_gdipToken := token

    OnMessage(0x0020, MUI_OnSetCursor)     ; WM_SETCURSOR
    OnMessage(0x0200, MUI_OnMouseMove)     ; WM_MOUSEMOVE
    OnMessage(0x0201, MUI_OnLButtonDown)   ; WM_LBUTTONDOWN
    OnMessage(0x0203, MUI_OnLButtonDown)   ; WM_LBUTTONDBLCLK
    OnMessage(0x0202, MUI_OnLButtonUp)     ; WM_LBUTTONUP
    OnMessage(0x0205, MUI_OnRButtonUp)     ; WM_RBUTTONUP
    OnExit(MUI_Shutdown)
}

MUI_Shutdown(*) {
    global MUI_gdipToken
    if MUI_gdipToken {
        DllCall("gdiplus\GdiplusShutdown", "UPtr", MUI_gdipToken)
        MUI_gdipToken := 0
    }
}

/**
 * 创建圆角矩形路径
 */
MUI_RoundRectPath(x, y, w, h, r) {
    path := 0
    DllCall("gdiplus\GdipCreatePath", "Int", 0, "Ptr*", &path)
    r := Min(r, w / 2, h / 2)
    if (r <= 0) {
        DllCall("gdiplus\GdipAddPathRectangle", "Ptr", path, "Float", x, "Float", y, "Float", w, "Float", h)
        return path
    }
    d := r * 2
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y, "Float", d, "Float", d, "Float", 180, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - d, "Float", y, "Float", d, "Float", d, "Float", 270, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x + w - d, "Float", y + h - d, "Float", d, "Float", d, "Float", 0, "Float", 90)
    DllCall("gdiplus\GdipAddPathArc", "Ptr", path, "Float", x, "Float", y + h - d, "Float", d, "Float", d, "Float", 90, "Float", 90)
    DllCall("gdiplus\GdipClosePathFigure", "Ptr", path)
    return path
}

/**
 * 绘制圆角矩形位图（可带居中文字），返回 HBITMAP
 * @param {Object} s - {bg, fill, border, radius, text, textColor, fontSize, bold}
 *                     border 为 "" 表示无边框；radius 为 96 DPI 下的像素值，fontSize 为磅值
 */
MUI_RenderRoundRect(wPx, hPx, s) {
    global MUI_FontName
    scale := A_ScreenDPI / 96

    pBitmap := 0, G := 0
    DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", wPx, "Int", hPx, "Int", 0, "Int", 0x26200A, "Ptr", 0, "Ptr*", &pBitmap)
    DllCall("gdiplus\GdipGetImageGraphicsContext", "Ptr", pBitmap, "Ptr*", &G)
    DllCall("gdiplus\GdipSetSmoothingMode", "Ptr", G, "Int", 4)
    DllCall("gdiplus\GdipSetPixelOffsetMode", "Ptr", G, "Int", 4)
    DllCall("gdiplus\GdipSetTextRenderingHint", "Ptr", G, "Int", 5)
    DllCall("gdiplus\GdipGraphicsClear", "Ptr", G, "UInt", 0xFF000000 | s.bg)

    hasBorder := s.HasProp("border") && s.border != ""
    bw := hasBorder ? Max(1, Round(scale)) : 0
    path := MUI_RoundRectPath(bw / 2, bw / 2, wPx - bw, hPx - bw, s.radius * scale)

    brush := 0
    DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000 | s.fill, "Ptr*", &brush)
    DllCall("gdiplus\GdipFillPath", "Ptr", G, "Ptr", brush, "Ptr", path)
    DllCall("gdiplus\GdipDeleteBrush", "Ptr", brush)

    if hasBorder {
        pen := 0
        DllCall("gdiplus\GdipCreatePen1", "UInt", 0xFF000000 | s.border, "Float", bw, "Int", 2, "Ptr*", &pen)
        DllCall("gdiplus\GdipDrawPath", "Ptr", G, "Ptr", pen, "Ptr", path)
        DllCall("gdiplus\GdipDeletePen", "Ptr", pen)
    }
    DllCall("gdiplus\GdipDeletePath", "Ptr", path)

    if (s.HasProp("text") && s.text != "") {
        family := 0, font := 0, fmt := 0, tBrush := 0
        if DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", MUI_FontName, "Ptr", 0, "Ptr*", &family) != 0
            DllCall("gdiplus\GdipCreateFontFamilyFromName", "WStr", "Segoe UI", "Ptr", 0, "Ptr*", &family)
        ; 字号：pt -> px（UnitPixel）
        DllCall("gdiplus\GdipCreateFont", "Ptr", family, "Float", s.fontSize * A_ScreenDPI / 72, "Int", s.bold ? 1 : 0, "Int", 2, "Ptr*", &font)
        DllCall("gdiplus\GdipCreateStringFormat", "Int", 0x1000, "Int", 0, "Ptr*", &fmt)  ; NoWrap
        DllCall("gdiplus\GdipSetStringFormatAlign", "Ptr", fmt, "Int", 1)
        DllCall("gdiplus\GdipSetStringFormatLineAlign", "Ptr", fmt, "Int", 1)
        DllCall("gdiplus\GdipCreateSolidFill", "UInt", 0xFF000000 | s.textColor, "Ptr*", &tBrush)
        rect := Buffer(16, 0)
        NumPut("Float", 0, "Float", 0, "Float", wPx, "Float", hPx, rect)
        DllCall("gdiplus\GdipDrawString", "Ptr", G, "WStr", s.text, "Int", -1, "Ptr", font, "Ptr", rect, "Ptr", fmt, "Ptr", tBrush)
        DllCall("gdiplus\GdipDeleteBrush", "Ptr", tBrush)
        DllCall("gdiplus\GdipDeleteStringFormat", "Ptr", fmt)
        DllCall("gdiplus\GdipDeleteFont", "Ptr", font)
        DllCall("gdiplus\GdipDeleteFontFamily", "Ptr", family)
    }

    hbm := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "Ptr*", &hbm, "UInt", 0)
    DllCall("gdiplus\GdipDeleteGraphics", "Ptr", G)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    return hbm
}

/**
 * 获取控件客户区的物理像素尺寸
 */
MUI_GetClientSize(hwnd, &w, &h) {
    rc := Buffer(16, 0)
    DllCall("GetClientRect", "Ptr", hwnd, "Ptr", rc)
    w := NumGet(rc, 8, "Int")
    h := NumGet(rc, 12, "Int")
}

/**
 * 添加圆角卡片背景（必须在卡片内的控件之前添加）
 * 卡片内的 Text/Checkbox 需追加 MUI_CardBg 背景选项
 * @param {Object} opts - 可选 {bg, fill, border, radius}
 */
MUI_AddCard(gui, x, y, w, h, opts := "") {
    global MUI_CardBitmaps, MUI_T
    if !IsObject(opts)
        opts := {}
    s := {
        bg: opts.HasProp("bg") ? opts.bg : MUI_T.window,
        fill: opts.HasProp("fill") ? opts.fill : MUI_T.card,
        border: opts.HasProp("border") ? opts.border : MUI_T.cardBorder,
        radius: opts.HasProp("radius") ? opts.radius : 12
    }
    pic := gui.AddPicture("x" x " y" y " w" w " h" h " +0x4E", "")
    MUI_GetClientSize(pic.Hwnd, &wPx, &hPx)
    hbm := MUI_RenderRoundRect(wPx, hPx, s)
    prev := SendMessage(0x172, 0, hbm, pic)  ; STM_SETIMAGE
    if prev
        DllCall("DeleteObject", "Ptr", prev)
    MUI_CardBitmaps.Push(hbm)
    return pic
}

; ========== 圆角按钮 ==========
class ModernButton {
    static byHwnd := Map()
    static hoverHwnd := 0
    static pressedHwnd := 0

    ; name -> {fill: [常态, 悬停, 按下], text, border, bold}，由 MUI_SetTheme 按主题填充
    static Styles := Map()

    /**
     * @param {Object} opts - 可选 {bg, radius, fontSize}，bg 默认为卡片色
     */
    __New(gui, x, y, w, h, text, style := "primary", opts := "") {
        global MUI_T
        if !IsObject(opts)
            opts := {}
        this._text := text
        this.style := style
        this.bg := opts.HasProp("bg") ? opts.bg : MUI_T.card
        this.radius := opts.HasProp("radius") ? opts.radius : 8
        this.fontSize := opts.HasProp("fontSize") ? opts.fontSize : 10
        this.handlers := Map()
        this.bitmaps := []
        this.state := 0   ; 0=常态 1=悬停 2=按下
        ; SS_NOTIFY | SS_CENTERIMAGE | SS_BITMAP
        this.ctrl := gui.AddPicture("x" x " y" y " w" w " h" h " +0x14E", "")
        this.Hwnd := this.ctrl.Hwnd
        ModernButton.byHwnd[this.Hwnd] := this
        this.Render()
    }

    Text {
        get => this._text
        set {
            if (value != this._text) {
                this._text := value
                this.Render()
            }
        }
    }

    SetStyle(style) {
        if (style != this.style) {
            this.style := style
            this.Render()
        }
    }

    SetState(state) {
        if (state != this.state) {
            this.state := state
            this._Apply()
        }
    }

    OnEvent(name, fn) {
        if !this.handlers.Has(name)
            this.handlers[name] := []
        this.handlers[name].Push(fn)
    }

    Fire(name) {
        if !this.handlers.Has(name)
            return
        for fn in this.handlers[name]
            fn(this)
    }

    Render() {
        MUI_GetClientSize(this.Hwnd, &wPx, &hPx)
        st := ModernButton.Styles[this.style]
        old := this.bitmaps
        this.bitmaps := []
        Loop 3 {
            this.bitmaps.Push(MUI_RenderRoundRect(wPx, hPx, {
                bg: this.bg, fill: st.fill[A_Index], border: st.border, radius: this.radius,
                text: this._text, textColor: st.text, fontSize: this.fontSize, bold: st.bold
            }))
        }
        this._Apply(old)
        for h in old
            DllCall("DeleteObject", "Ptr", h)
    }

    _Apply(pending := "") {
        hbm := this.bitmaps[this.state + 1]
        prev := SendMessage(0x172, 0, hbm, this.ctrl)  ; STM_SETIMAGE
        ; 32位位图可能被静态控件复制，释放不属于自己的旧句柄
        if (prev && !MUI_ArrayHas(this.bitmaps, prev) && !(IsObject(pending) && MUI_ArrayHas(pending, prev)))
            DllCall("DeleteObject", "Ptr", prev)
    }
}

MUI_ArrayHas(arr, val) {
    for v in arr
        if (v = val)
            return true
    return false
}

MUI_PointInClient(hwnd, lParam) {
    x := (lParam & 0xFFFF) << 48 >> 48          ; 带符号 LOWORD
    y := ((lParam >> 16) & 0xFFFF) << 48 >> 48  ; 带符号 HIWORD
    MUI_GetClientSize(hwnd, &w, &h)
    return (x >= 0 && y >= 0 && x < w && y < h)
}

MUI_OnSetCursor(wParam, lParam, msg, hwnd) {
    if ModernButton.byHwnd.Has(wParam) {
        DllCall("SetCursor", "Ptr", DllCall("LoadCursor", "Ptr", 0, "Ptr", 32649, "Ptr"))  ; IDC_HAND
        return true
    }
}

MUI_OnMouseMove(wParam, lParam, msg, hwnd) {
    if !ModernButton.byHwnd.Has(hwnd)
        return
    if (ModernButton.pressedHwnd = hwnd) {
        ModernButton.byHwnd[hwnd].SetState(MUI_PointInClient(hwnd, lParam) ? 2 : 0)
        return
    }
    if (ModernButton.hoverHwnd != hwnd) {
        MUI_ClearHover()
        ModernButton.hoverHwnd := hwnd
        ModernButton.byHwnd[hwnd].SetState(1)
        SetTimer(MUI_CheckHover, 50)
    }
}

MUI_CheckHover() {
    h := ModernButton.hoverHwnd
    if !h {
        SetTimer(MUI_CheckHover, 0)
        return
    }
    if (ModernButton.pressedHwnd = h)
        return
    under := 0
    try MouseGetPos(,,, &under, 2)
    if (under != h)
        MUI_ClearHover()
}

MUI_ClearHover() {
    h := ModernButton.hoverHwnd
    ModernButton.hoverHwnd := 0
    SetTimer(MUI_CheckHover, 0)
    if (h && ModernButton.byHwnd.Has(h))
        ModernButton.byHwnd[h].SetState(0)
}

MUI_OnLButtonDown(wParam, lParam, msg, hwnd) {
    if !ModernButton.byHwnd.Has(hwnd)
        return
    ModernButton.pressedHwnd := hwnd
    DllCall("SetCapture", "Ptr", hwnd)
    ModernButton.byHwnd[hwnd].SetState(2)
    return 0
}

MUI_OnLButtonUp(wParam, lParam, msg, hwnd) {
    p := ModernButton.pressedHwnd
    if !p
        return
    ModernButton.pressedHwnd := 0
    DllCall("ReleaseCapture")
    if !ModernButton.byHwnd.Has(p)
        return
    btn := ModernButton.byHwnd[p]
    if (hwnd = p && MUI_PointInClient(p, lParam)) {
        ModernButton.hoverHwnd := p
        btn.SetState(1)
        SetTimer(MUI_CheckHover, 50)
        ; 异步触发，避免在消息回调中执行耗时逻辑
        SetTimer(() => btn.Fire("Click"), -1)
    } else {
        btn.SetState(0)
    }
    return 0
}

MUI_OnRButtonUp(wParam, lParam, msg, hwnd) {
    if !ModernButton.byHwnd.Has(hwnd)
        return
    btn := ModernButton.byHwnd[hwnd]
    SetTimer(() => btn.Fire("ContextMenu"), -1)
    return 0
}

; ========== 分段选择器（替代 Tab2，兼容 Value/Choose/Delete/Add/OnEvent 用法） ==========
class ModernSegmented {
    __New(gui, x, y, segW, h, names) {
        global MUI_T
        pad := 4, gap := 4
        this.width := pad * 2 + names.Length * segW + (names.Length - 1) * gap
        MUI_AddCard(gui, x, y, this.width, h, {fill: MUI_T.segTrack, border: "", radius: 10})
        this._value := 1
        this.handlers := Map()
        this.buttons := []
        for i, name in names {
            bx := x + pad + (i - 1) * (segW + gap)
            btn := ModernButton(gui, bx, y + pad, segW, h - pad * 2, name, i = 1 ? "segOn" : "segOff", {bg: MUI_T.segTrack, radius: 7, fontSize: 10})
            btn.OnEvent("Click", this._OnSegClick.Bind(this, i))
            btn.OnEvent("ContextMenu", this._OnSegContext.Bind(this, i))
            this.buttons.Push(btn)
        }
    }

    Value => this._value

    Choose(index) {
        this._value := index
        for i, btn in this.buttons
            btn.SetStyle(i = index ? "segOn" : "segOff")
    }

    ; Tab2 兼容：名称通过 Add 重新设置
    Delete() {
    }

    Add(names) {
        for i, name in names {
            if (i <= this.buttons.Length)
                this.buttons[i].Text := name
        }
    }

    OnEvent(name, fn) {
        if !this.handlers.Has(name)
            this.handlers[name] := []
        this.handlers[name].Push(fn)
    }

    _Fire(name) {
        if !this.handlers.Has(name)
            return
        for fn in this.handlers[name]
            fn(this)
    }

    _OnSegClick(index, *) {
        if (index = this._value)
            return
        this.Choose(index)
        this._Fire("Change")
    }

    _OnSegContext(index, *) {
        this._Fire("ContextMenu")
    }
}
