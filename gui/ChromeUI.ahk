; ========== 仿 D3keyHelper：无边框标题栏 + GDI+ 关闭按钮 + FillPixel 边框 ==========

global gChrome_gdipToken := 0
global gChrome_hCloseN := 0, gChrome_hCloseH := 0, gChrome_hCloseP := 0
global gChrome_hwndTitleBar := 0, gChrome_hwndTitleLine := 0
global gChrome_hwndBorders := []
global gChrome_hwndTitleText := 0, gChrome_hwndCloseBtn := 0
global gChrome_titleTextCtrl := 0
global gChrome_closeBtnState := 0
global gChrome_mouseHook := 0
global gChrome_mouseCb := 0
global gChrome_titleStr := ""

STM_SETIMAGE := 0x172
WM_LBUTTONDOWN := 0x201
WM_LBUTTONUP := 0x202
WM_RBUTTONDOWN := 0x204
WM_RBUTTONUP := 0x205
WM_MOUSEMOVE := 0x200
WH_MOUSE_LL := 14

global gChrome_b64CloseN := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAAM0lEQVRIiWMYBaNgFIyCUUAsYCSkrnLe2v/khGZ7UjBes5lGo2gUjIJRMApGAVbAwMAAAMjYBAQ0LnL/AAAAAElFTkSuQmCC"
global gChrome_b64CloseH := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAARklEQVRIiWN8Iaj8n2EAANNAWMowavGoxaMWj1pMCWAhpFfi/V2yjH8hqIxXfvD6mJDLyQWjqXrU4lGLRy0etZg4wMDAAACGJAZtrV+pPwAAAABJRU5ErkJggg=="
global gChrome_b64CloseP := "iVBORw0KGgoAAAANSUhEUgAAAB4AAAAZCAYAAAAmNZ4aAAAARklEQVRIiWO85B32n2EAANNAWMowavGoxaMWj1pMCWAhpNftwjGyjN9lYIVXfvD6mJDLyQWjqXrU4lGLRy0etZg4wMDAAACzuwbMPgoPPgAAAABJRU5ErkJggg=="

/**
 * 启动 GDI+ 并解码关闭按钮位图（在创建 Gui 之前调用）
 */
Chrome_PreCreate() {
    global gChrome_gdipToken, gChrome_hCloseN, gChrome_hCloseH, gChrome_hCloseP
    global gChrome_b64CloseN, gChrome_b64CloseH, gChrome_b64CloseP
    DllCall("LoadLibrary", "Str", "Crypt32.dll", "Ptr")
    DllCall("LoadLibrary", "Str", "Shlwapi.dll", "Ptr")
    DllCall("LoadLibrary", "Str", "Gdiplus.dll", "Ptr")
    si := Buffer(A_PtrSize = 8 ? 24 : 16, 0)
    NumPut("UInt", 1, si, 0)
    pToken := 0
    if DllCall("gdiplus\GdiplusStartup", "Ptr*", &pToken, "Ptr", si, "Ptr", 0) = 0
        gChrome_gdipToken := pToken
    gChrome_hCloseN := Chrome_GdipCreateHBitmapFromBase64(gChrome_b64CloseN)
    gChrome_hCloseH := Chrome_GdipCreateHBitmapFromBase64(gChrome_b64CloseH)
    gChrome_hCloseP := Chrome_GdipCreateHBitmapFromBase64(gChrome_b64CloseP)
}

Chrome_GdipCreateHBitmapFromBase64(b64) {
    size := 0
    if !DllCall("crypt32\CryptStringToBinaryW", "WStr", b64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        return 0
    bin := Buffer(size, 0)
    if !DllCall("crypt32\CryptStringToBinaryW", "WStr", b64, "UInt", 0, "UInt", 0x01, "Ptr", bin, "UInt*", &size, "Ptr", 0, "Ptr", 0)
        return 0
    pStream := DllCall("shlwapi\SHCreateMemStream", "Ptr", bin, "UInt", size, "Ptr")
    if !pStream
        return 0
    pBitmap := 0
    if (DllCall("gdiplus\GdipCreateBitmapFromStreamICM", "Ptr", pStream, "Ptr*", &pBitmap) != 0) || !pBitmap {
        ObjRelease(pStream)
        return 0
    }
    hbm := 0
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "Ptr", pBitmap, "UInt*", &hbm, "Int", 0x00FFFFFF)
    DllCall("gdiplus\GdipDisposeImage", "Ptr", pBitmap)
    ObjRelease(pStream)
    return hbm
}

Chrome_FillPixel(hwnds, color) {
    hBitmap := DllCall("CreateBitmap", "Int", 1, "Int", 1, "UInt", 1, "UInt", 32, "UInt", color, "Ptr")
    if !hBitmap
        return
    hBM := DllCall("CopyImage", "Ptr", hBitmap, "UInt", 0, "Int", 0, "Int", 0, "UInt", 0x2000 | 0x8 | 0x4, "Ptr")
    if IsObject(hwnds) {
        for h in hwnds
            SendMessage STM_SETIMAGE, 0, hBM,, "ahk_id " h
    } else
        SendMessage STM_SETIMAGE, 0, hBM,, "ahk_id " hwnds
    DllCall("DeleteObject", "Ptr", hBitmap)
}

/**
 * 添加标题栏与边框（在 myGui 创建后、其余控件之前调用）
 */
Chrome_AddTitleBar(gui, winW, winH, titleStr) {
    global chromeTop, gChrome_hwndTitleBar, gChrome_hwndTitleLine, gChrome_hwndBorders
    global gChrome_hwndTitleText, gChrome_hwndCloseBtn, gChrome_hCloseN, gChrome_titleTextCtrl
    global gChrome_titleStr
    gChrome_titleStr := titleStr
    gChrome_hwndBorders := []
    tw := winW - 2
    th := chromeTop - 2
    pTitle := gui.Add("Picture", "x1 y1 w" tw " h" th " +0x4E +BackgroundTrans", "")
    gChrome_hwndTitleBar := pTitle.Hwnd
    pLine := gui.Add("Picture", "x1 y" chromeTop - 1 " w" tw " h1 +0x4E +BackgroundTrans", "")
    gChrome_hwndTitleLine := pLine.Hwnd
    gChrome_hwndBorders.Push(gui.Add("Picture", "x0 y0 w" winW " h1 +0x4E +BackgroundTrans", "").Hwnd)
    gChrome_hwndBorders.Push(gui.Add("Picture", "x0 y" winH - 1 " w" winW " h1 +0x4E +BackgroundTrans", "").Hwnd)
    gChrome_hwndBorders.Push(gui.Add("Picture", "x0 y1 w1 h" winH - 2 " +0x4E +BackgroundTrans", "").Hwnd)
    gChrome_hwndBorders.Push(gui.Add("Picture", "x" winW - 1 " y1 w1 h" winH - 2 " +0x4E +BackgroundTrans", "").Hwnd)
    gui.SetFont("s11 Norm cFFFFFF", "Segoe UI")
    t := gui.AddText("x0 y4 w" winW " h22 +Center +BackgroundTrans", titleStr)
    gChrome_hwndTitleText := t.Hwnd
    gChrome_titleTextCtrl := t
    bx := winW - 31
    pClose := gui.Add("Picture", "x" bx " y1 w30 h" th " +0x4E +BackgroundTrans", "HBITMAP:*" gChrome_hCloseN)
    gChrome_hwndCloseBtn := pClose.Hwnd
    Chrome_ApplyTitleBarActive(true)
}

Chrome_ApplyTitleBarActive(active) {
    global gChrome_hwndTitleBar, gChrome_hwndTitleLine, gChrome_hwndBorders, gChrome_titleTextCtrl
    if !gChrome_hwndTitleBar
        return
    if active {
        Chrome_FillPixel(gChrome_hwndTitleBar, 0x34495e)
        Chrome_FillPixel(gChrome_hwndTitleLine, 0x000000)
        Chrome_FillPixel(gChrome_hwndBorders, 0x000000)
        if gChrome_titleTextCtrl
            gChrome_titleTextCtrl.SetFont("cFFFFFF")
    } else {
        Chrome_FillPixel([gChrome_hwndTitleBar, gChrome_hwndTitleLine], 0x607e9d)
        Chrome_FillPixel(gChrome_hwndBorders, 0x607e9d)
        if gChrome_titleTextCtrl
            gChrome_titleTextCtrl.SetFont("cEEEEEE")
    }
}

Chrome_OnActivate(wParam, lParam, msg, hwnd) {
    global myGui
    if !IsSet(myGui) || !myGui
        return
    if !(g := GuiFromHwnd(hwnd)) || g != myGui
        return
    wa := wParam & 0xFFFF
    Chrome_ApplyTitleBarActive(wa != 0)
}

Chrome_CloseBtnSetImage(hbmp) {
    global gChrome_hwndCloseBtn
    if gChrome_hwndCloseBtn
        SendMessage STM_SETIMAGE, 0, hbmp,, "ahk_id " gChrome_hwndCloseBtn
}

Chrome_LowLevelMouseProc(nCode, wParam, lParam, *) {
    global myGui, gChrome_hwndCloseBtn, gChrome_hwndTitleBar, gChrome_hwndTitleText
    global gChrome_hCloseN, gChrome_hCloseH, gChrome_hCloseP, gChrome_closeBtnState
    if nCode < 0
        return DllCall("user32\CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "Ptr", lParam, "Ptr")
    if !IsSet(myGui) || !myGui
        return DllCall("user32\CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "Ptr", lParam, "Ptr")
    cm := A_CoordModeMouse
    CoordMode "Mouse", "Screen"
    MouseGetPos(,,, &hCtrl, 2)
    CoordMode "Mouse", cm
    switch wParam {
        case WM_MOUSEMOVE:
            if hCtrl = gChrome_hwndCloseBtn {
                if gChrome_closeBtnState != 1 {
                    Chrome_CloseBtnSetImage(gChrome_hCloseH)
                    gChrome_closeBtnState := 1
                }
            } else {
                if gChrome_closeBtnState != 0 {
                    Chrome_CloseBtnSetImage(gChrome_hCloseN)
                    gChrome_closeBtnState := 0
                }
                if (hCtrl = gChrome_hwndTitleBar || hCtrl = gChrome_hwndTitleText)
                    PostMessage 0xA1, 2,,, "ahk_id " myGui.Hwnd
            }
        case WM_LBUTTONDOWN, WM_RBUTTONDOWN:
            if hCtrl = gChrome_hwndCloseBtn {
                Chrome_CloseBtnSetImage(gChrome_hCloseP)
                gChrome_closeBtnState := 2
            }
        case WM_LBUTTONUP, WM_RBUTTONUP:
            if hCtrl = gChrome_hwndCloseBtn && gChrome_closeBtnState = 2 {
                Chrome_CloseBtnSetImage(gChrome_hCloseN)
                gChrome_closeBtnState := 0
                SetTimer(Chrome_DoGuiClose, -1)
            } else if gChrome_closeBtnState = 2 {
                Chrome_CloseBtnSetImage(gChrome_hCloseN)
                gChrome_closeBtnState := 0
            }
    }
    return DllCall("user32\CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "Ptr", lParam, "Ptr")
}

Chrome_DoGuiClose(*) {
    OnGuiClose()
}

Chrome_PostShowInstall() {
    global gChrome_mouseHook, gChrome_mouseCb
    OnMessage 0x0006, Chrome_OnActivate
    gChrome_mouseCb := CallbackCreate(Chrome_LowLevelMouseProc, "Fast")
    gChrome_mouseHook := DllCall("user32\SetWindowsHookExW", "Int", WH_MOUSE_LL, "Ptr", gChrome_mouseCb, "Ptr", 0, "UInt", 0, "Ptr")
}

Chrome_Shutdown() {
    global gChrome_mouseHook, gChrome_mouseCb, gChrome_gdipToken
    global gChrome_hCloseN, gChrome_hCloseH, gChrome_hCloseP
    OnMessage 0x0006, Chrome_OnActivate, 0
    if gChrome_mouseHook {
        DllCall("user32\UnhookWindowsHookEx", "Ptr", gChrome_mouseHook)
        gChrome_mouseHook := 0
    }
    if gChrome_mouseCb {
        CallbackFree(gChrome_mouseCb)
        gChrome_mouseCb := 0
    }
    if gChrome_gdipToken {
        DllCall("gdiplus\GdiplusShutdown", "Ptr", gChrome_gdipToken)
        gChrome_gdipToken := 0
    }
    for h in [gChrome_hCloseN, gChrome_hCloseH, gChrome_hCloseP] {
        if h
            DllCall("DeleteObject", "Ptr", h)
    }
    gChrome_hCloseN := 0, gChrome_hCloseH := 0, gChrome_hCloseP := 0
}
