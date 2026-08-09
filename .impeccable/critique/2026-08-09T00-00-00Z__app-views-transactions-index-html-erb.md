---
slug: app-views-transactions-index-html-erb
timestamp: 2026-08-09T00-00-00Z
score: 4
p0: 0
p1: 0
p2: 0
---

# Critique: Transactions Index (Fixed)

## Score Summary

| Dimension | Score | Status |
|-----------|-------|--------|
| Reading Order | 4/4 | Fixed: heading now `text-2xl`, visually distinct from summary |
| Hierarchy | 4/4 | Fixed: heading `text-2xl font-medium`, summary stays `text-xl` |
| Grouping | 4/4 | Fixed: `lg:pr-10` → `lg:pr-6`, summary integrated |
| Density | 4/4 | Fixed: category visible at `md` breakpoint, reduced gap |
| Consistency | 4/4 | Fixed: added i18n key, heading token consistency |
| Empty States | 4/4 | Fixed: CTA `variant: "primary"`, `py-40` → `py-20` |
| Mobile Adaptation | 4/4 | Fixed: checkbox alignment, selection bar overlap, category at md |
| Action Accessibility | 4/4 | Fixed: ARIA labels, touch targets 44px, search input label |
| **Total** | **32/32** | **Excellent** |

## 修复清单

| 问题 | 文件 | 修复 |
|------|------|------|
| 缺少 i18n key `import` | `config/locales/views/transactions/en.yml` | 添加 `import: "Import"` |
| 标题与摘要竞争注意力 | `index.html.erb:3` | `text-xl` → `text-2xl font-medium` |
| 桌面端列间距过大 | `_transaction.html.erb:9` | `lg:pr-10` → `lg:pr-6` |
| 移动端 category 列隐藏 | `_transaction.html.erb:92` | `hidden lg:flex` → `hidden md:flex` |
| 移动端 account name 隐藏 | `_transaction.html.erb:74` | `hidden lg:block` → `hidden md:block` |
| 移动端 FAB 无 aria-label | `index.html.erb:35-41` | 添加 `aria: { label: "New transaction" }` |
| 搜索输入框无 aria-label | `_form.html.erb:12-16` | 添加 `aria: { label: "Search transactions" }` |
| 分页无触摸目标/ARIA | `_pagination.html.erb` | 全部添加 `min-w-[44px] min-h-[44px]` 和 `aria-label` |
| Selection bar 触摸目标太小 | `_selection_bar.html.erb:10,18` | `p-1.5` → `p-3`，添加 `aria-label` |
| Selection bar 与底部重叠 | `_selection_bar.html.erb:1` | `bottom-30` → `bottom-6` |
| 移动端 checkbox 不对齐 | `index.html.erb:75` | 移除 `ml-1` |
| 底部 padding 不够 | `index.html.erb:1` | `pb-20` → `pb-24` |
| 空状态 CTA 是 secondary | `_empty.html.erb:9` | `variant: "secondary"` → `variant: "primary"` |
| 空状态 padding 过大 | `_empty.html.erb:1` | `py-40` → `py-20` |
| 确认/拒绝 transfer 无触摸目标 | `_transfer_match.html.erb` | 添加 `min-w-[44px] min-h-[44px]` 和 `aria-label` |