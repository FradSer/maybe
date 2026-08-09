---
slug: app-views-budgets
timestamp: 2026-08-09T00:00:00Z
score: 3
p0: 0
p1: 4
p2: 6
---

# Critique: Budget Pages

## Score Summary

| Dimension | Score | Key Finding |
|-----------|-------|-------------|
| Reading Order | 3/4 | Donut 300px 高度视觉权重过大，右列 categories 列表被推到次要 |
| Hierarchy | 3/4 | Donut 只显示一个数据点，视觉重量远超信息量 |
| Grouping | 4/4 | 两列布局清晰分离宏观汇总和微观分类 |
| Density | 3/4 | Donut 300px 高度信息密度极低；3px 厚度的扇区难以辨读 |
| Consistency | 2/4 | 多处硬编码颜色（`text-green-600`, `bg-gray-900`）；CSS 变量未定义 |
| Empty States | 3/4 | 超分配警告和空分类状态良好；actuals 面板缺少空状态提示 |
| Mobile Adaptation | 3/4 | 移动端 donut 占据 60-70% 视口，分类列表推到首屏外 |
| Action Accessibility | 3/4 | 编辑预算的 'of $X' 链接不易发现 |
| **Total** | **24/32** | **Good — 解决 P1 问题** |

## 关键发现 (P1)

### P1: 零 ARIA 属性
- **位置**: 所有预算视图文件 + DS 组件（Tabs, Menu, Dialog, Toggle）
- **影响**: 屏幕阅读器完全无法访问所有交互区域
- **建议**: 为 DS::Tabs 添加 `role="tablist"`/`aria-selected`，DS::Menu 添加 `aria-expanded`/`aria-haspopup`，DS::Dialog 添加 `role="dialog"`/`aria-modal`，donut chart SVG 添加 `aria-label`

### P1: 多处硬编码颜色
- **位置**: `_budget_nav.html.erb:17,21` (`text-green-600`), `_allocation_progress.erb:8-9,30` (`bg-gray-900`, `bg-gray-100`), `budget_categories/show.html.erb:98,100` (`bg-gray-300`)
- **影响**: 深色模式下这些颜色不会适配，会破坏 UI
- **建议**: 替换为设计 token（`text-success`, `bg-inverse`, `bg-surface-inset` 等）

### P1: 对比度失败
- **位置**: 多处 — `text-subdued` (#9E9E9E) 2.68:1全面失败；`text-destructive` (#EC2222) 4.36:1；`text-warning` (#DC6803) 3.49:1；`text-success` (#10A861) 3.09:1/2.88:1
- **影响**: 全部低于 WCAG AA 4.5:1 标准
- **建议**: 提升 `text-subdued` 到更深的灰色，或调整语义色的色相/亮度

### P1: Donut chart 未定义 CSS 变量
- **位置**: `donut_chart_controller.js:139,146` 引用 `--budget-unused-fill` 和 `--budget-unallocated-fill`
- **影响**: 这些变量未在任何地方定义，hover 时 segment 颜色会回退到透明或黑色
- **建议**: 在 `application.css` 或视图模板中定义这些变量，或添加 inline fallback

## 中等发现 (P2)

### P2: Donut 高度过大（300px）
- 信息密度低，移动端占据 60-70% 视口。建议 `h-[200px] md:h-[220px]`

### P2: 触摸目标 < 44px
- Picker 导航箭头（`p-2`, ~32px）、步骤导航圆圈（`w-7 h-7`, 28px）、月份网格链接（~32px 高）

### P2: 编辑预算动作不易发现
- 'of $X' 链接看起来像标签，不是可点击的编辑链接

### P2: 缺少 actuals 面板空状态
- 当没有交易时，面板显示为空白区域，没有提示信息

### P2: 分类列表缺少"未分配分类"的空状态
- 当有分类但未分配到预算时，列表只显示未分类行

### P2: 步骤导航缺失 `aria-current`
- 屏幕阅读器无法知道当前步骤

## 优势

- 分组清晰（4/4）：两列布局干净分离宏观汇总和微观分类
- 超分配警告和空分类状态设计良好，有明确的可操作 CTA
- Donut chart controller 边缘情况处理完善（空 segments、zero total、Turbo 切换）
- 阅读顺序合理（3/4）：F 型扫描路径符合信息层次
- 响应式布局使用 `flex-col md:flex-row` 转换，干净有效

## 推荐下一步

1. **P1** `/impeccable harden` — 修复 ARIA、对比度、硬编码颜色、CSS 变量
2. **P2** `/impeccable adapt` — 修复移动端 donut 高度、触摸目标
3. **P2** `/impeccable polish` — 编辑预算动作发现性、空状态消息