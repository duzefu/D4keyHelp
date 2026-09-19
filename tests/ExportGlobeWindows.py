"""生成血球识别回归测试用的原始位图（tests/data/*.bin）。

用法：在本目录执行 `python ExportGlobeWindows.py`
数据来源：仓库根目录的四张 2K 参考截图（screenShot.png 满血 / screenShot2.png 护盾 /
lowblood.png 低血量 / sample2.PNG 满血）。截图为本地资源且被 .gitignore 忽略，
所以这个脚本与 *bin 都不需要提交，只用于本地验证血球算法。

输出格式与 AHK 的 CaptureScreenRegion 完全一致：24 位 BGR、行按 4 字节对齐、自上而下。
"""
import os
from PIL import Image

SCREEN_W, SCREEN_H = 2560, 1440
RAD = 90                                  # 2K 下血球半径
HALF_W = RAD * 145 // 100                 # 取景半径（与应用一致）
SIZE = HALF_W * 2 + 1
PRIOR_CX = round(SCREEN_W / 2 - 465)      # 应用推算的血球圆心
PRIOR_CY = round(SCREEN_H - 116)

ORIGIN_X = min(max(PRIOR_CX - HALF_W, 0), max(0, SCREEN_W - HALF_W * 2 - 1))
ORIGIN_Y = min(max(PRIOR_CY - HALF_W, 0), max(0, SCREEN_H - HALF_W * 2 - 1))
STRIDE = ((SIZE * 3 + 3) // 4) * 4

# 全屏搜索区域（与 HealthGlobe.LocateHealthGlobe 一致）
SEARCH_X = round(SCREEN_W * 0.03)
SEARCH_Y = round(SCREEN_H * 0.45)
SEARCH_W = round(SCREEN_W * 0.47)
SEARCH_H = SCREEN_H - SEARCH_Y
SEARCH_STRIDE = ((SEARCH_W * 3 + 3) // 4) * 4

SOURCES = {
    "screenShot": "screenShot.png",
    "screenShot2": "screenShot2.png",
    "lowblood": "lowblood.png",
    "sample2": "sample2.PNG",
    "live": "test.png",
}

def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
    os.makedirs(out_dir, exist_ok=True)
    print(f"取景窗口: ({ORIGIN_X}, {ORIGIN_Y}) 尺寸 {SIZE}x{SIZE} 步长 {STRIDE}")

    for name, filename in SOURCES.items():
        path = os.path.join(root, filename)
        if not os.path.exists(path):
            print(f"跳过 {name}: 找不到 {path}")
            continue

        image = Image.open(path).convert("RGB")
        window = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))       # 画面外的部分补黑
        visible = (max(ORIGIN_X, 0), max(ORIGIN_Y, 0),
                   min(SCREEN_W, ORIGIN_X + SIZE), min(SCREEN_H, ORIGIN_Y + SIZE))
        window.paste(image.crop(visible), (visible[0] - ORIGIN_X, visible[1] - ORIGIN_Y))

        pixels = window.tobytes()                                 # RGB，自上而下
        assert len(pixels) == SIZE * SIZE * 3
        buf = bytearray(STRIDE * SIZE)
        for y in range(SIZE):                                     # RGB -> BGR
            src = pixels[y * SIZE * 3:(y + 1) * SIZE * 3]
            line = bytearray(SIZE * 3)
            line[0::3] = src[2::3]
            line[1::3] = src[1::3]
            line[2::3] = src[0::3]
            buf[y * STRIDE:y * STRIDE + SIZE * 3] = line

        out_path = os.path.join(out_dir, f"{name}.bin")
        with open(out_path, "wb") as handle:
            handle.write(buf)
        print(f"已生成 {out_path}")

def dump(window, stride):
    pixels = window.tobytes()
    buf = bytearray(stride * window.height)
    for y in range(window.height):
        src = pixels[y * window.width * 3:(y + 1) * window.width * 3]
        line = bytearray(window.width * 3)
        line[0::3] = src[2::3]
        line[1::3] = src[1::3]
        line[2::3] = src[0::3]
        buf[y * stride:y * stride + window.width * 3] = line
    return buf

def main_search():
    """导出搜索区域：偏移版本用来模拟"游戏窗口没铺满屏幕"的情况"""
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "data")
    os.makedirs(out_dir, exist_ok=True)
    print(f"搜索区域: ({SEARCH_X}, {SEARCH_Y}) {SEARCH_W}x{SEARCH_H}")

    for name, filename in SOURCES.items():
        path = os.path.join(root, filename)
        if not os.path.exists(path):
            continue
        image = Image.open(path).convert("RGB")
        for tag, dx, dy in (("", 0, 0), ("_shift", -180, 90)):
            window = Image.new("RGB", (SEARCH_W, SEARCH_H), (0, 0, 0))
            ox, oy = SEARCH_X + dx, SEARCH_Y + dy
            visible = (max(ox, 0), max(oy, 0),
                       min(SCREEN_W, ox + SEARCH_W), min(SCREEN_H, oy + SEARCH_H))
            if visible[2] > visible[0] and visible[3] > visible[1]:
                window.paste(image.crop(visible), (visible[0] - ox, visible[1] - oy))
            out_path = os.path.join(out_dir, f"search_{name}{tag}.bin")
            with open(out_path, "wb") as handle:
                handle.write(dump(window, SEARCH_STRIDE))
            print(f"已生成 {out_path}")

if __name__ == "__main__":
    main()
