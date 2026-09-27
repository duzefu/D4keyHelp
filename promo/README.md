# D4KeyHelp 宣传视频（程序化生成）

成片：`D4KeyHelp_Promo.mp4`（1920×1080 · 60fps · 约 98 秒 · H.264 + AAC 320k，体积大不入库）
网页版：`D4KeyHelp_Promo_web.mp4`（1280×720 · 30fps · 9MB，满足 GitHub README 视频上传的 10MB 限制）

整条视频（画面、配乐、音效）都由代码实时生成，没有使用任何外部素材；
界面截图直接取自仓库里的 `mainPage.png` / `mainPage-dark.png`。

## 技术方案

| 层 | 实现 |
| --- | --- |
| 画面内容 | Canvas2D 逐帧绘制（`src/scenes1.js`、`src/scenes2.js`），所有动画都是时间 t 的纯函数，可任意帧复现 |
| 后期 | WebGL2 管线（`src/engine.js`）：域扭曲 fbm 烟雾背景 → 合成 → 双级高斯泛光 → 径向色散 / 燃烧转场 / 暗角 / 胶片颗粒 |
| 配乐与音效 | Web Audio `OfflineAudioContext` 纯合成（`src/audio.js`）：D 小调 i–VI–iv–V，100 BPM，太鼓 / 贝斯固定音型 / 琶音 / 人声 formant pad / 主旋律；所有音效与画面共用 `src/timeline.js` 里的提示点，帧级同步 |
| 渲染 | `render.js` 用 puppeteer-core 驱动无头 Edge（GPU WebGL），4 路并行逐帧截取 → ffmpeg x264 分段编码 → 拼接 + 混音 |

节奏：100 BPM，每小节 2.4 秒，每一幕都卡在小节线上；"连点 300ms" 刚好是八分音符，按键音效与鼓点对齐。

## 重新渲染

需要：Node 18+、ffmpeg、Microsoft Edge。

```bash
cd promo
npm install
node fetch-fonts.js          # 按源码实际用到的字符下载字体子集（改了文案后需重跑）
node render.js video 4       # 完整渲染（4 个并行 worker），输出 D4KeyHelp_Promo.mp4（约 120MB，不入库）
node render.js web 4         # 网页版：720p30、无颗粒、两遍编码 < 10MB，输出 D4KeyHelp_Promo_web.mp4（给 README 用）
node render.js stills 12.5 40  # 只渲染指定时刻的静帧到 stills/，调画面用
node render.js audio         # 只合成音频到 audio.wav
```

浏览器实时预览（带声音、可拖动进度）：用 Edge / Chrome 打开
`src/index.html?preview`（需要允许 file:// 访问，或在 `promo/` 下起一个静态服务器）。

## 分镜

| 时间 | 小节 | 内容 |
| --- | --- | --- |
| 0:00 | 0–3 | 开场：火星升起 → 符文法阵（六芒星 = 六个技能位）→ 金属标题 |
| 0:09 | 4–5 | 痛点：疯狂按键计数 → "把重复的按键，交给它" |
| 0:14 | 6–12 | 01 技能策略：连点（时间轨）/ 维持BUFF（取色点推近、绿条消失即补）/ 按住（蓄力环） |
| 0:31 | 13–19 | 02 智能喝药：自动定位血球 → 液面 → 圆缺面积换算 → 低于阈值按 Q → 护盾遮挡策略 |
| 0:48 | 20–23 | 03 F3 自动嬗变：单次截图扫描 → 逐个右键传奇 → 飞入魔盒 → 升级黄装 |
| 0:57 | 24–27 | 04 挂机与智能暂停：六点绕圈拾取魂魄、罗盘贡品计时、切窗口 / Tab / 手动点击暂停 |
| 1:07 | 28–30 | 05 配置与主题：真实界面 3D 展示，预设切换、右键重命名、浅深色擦除切换、自动保存 |
| 1:14 | 31–36 | 上手三步 + 热键一览 |
| 1:28 | 37–40 | 结尾：标题、GitHub 地址、MIT 开源 |
