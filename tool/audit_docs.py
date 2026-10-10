#!/usr/bin/env python3
"""docs/ 文档审计工具：断链检测 + 孤儿文档检测 + 过时 lib/ 路径检测。

用法（项目根目录执行）：
    python3 tool/audit_docs.py            # 全量审计
    python3 tool/audit_docs.py --links    # 仅断链 + 孤儿
    python3 tool/audit_docs.py --paths    # 仅过时 lib/ 路径

退出码：发现问题返回 1，干净返回 0（可接入 CI）。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOCS = ROOT / "docs"

LINK_RE = re.compile(r"\[[^\]]*\]\(([^)\s]+?\.md(?:#[^)\s]*)?)\)")
LIB_PATH_RE = re.compile(r"`(lib/[A-Za-z0-9_/.{}]+)`")

# 有意保留的失效路径：所在行或上一行含这些标记 → 历史记录/否定陈述，非真过时
STALE_MARKERS = (
    "已删除", "已移除", "已被移除", "已不存在", "已废弃", "历史路径",
    "不使用", "虚构", "已成功集成", "替换为",
)
# 教程「待创建」路径白名单：create_new_feature 教程以虚构 product 功能为例逐文件创建
TUTORIAL_PREFIXES = ("lib/features/product/",)


def resolve(src: Path, raw: str):
    """相对 文件所在目录 / docs / 仓库根 三处解析链接目标。"""
    p = raw.split("#")[0].lstrip("/")
    for base in (src.parent, DOCS, ROOT):
        cand = (base / p).resolve()
        try:
            cand.relative_to(ROOT)
        except ValueError:
            continue
        if cand.exists():
            return cand
    return None


def audit_links():
    """断链 + 孤儿检测。"""
    all_files = sorted(DOCS.rglob("*.md"))
    links_by_file = {}
    broken = []
    for f in all_files:
        text = f.read_text(encoding="utf-8", errors="replace")
        links = LINK_RE.findall(text)
        links_by_file[f] = links
        for raw in links:
            part = raw.split("#")[0]
            if part.startswith(("http://", "https://", "mailto:")):
                continue
            if resolve(f, raw) is None:
                broken.append((f.relative_to(ROOT).as_posix(), raw))

    ref_from_others = set()
    for f, links in links_by_file.items():
        for raw in links:
            part = raw.split("#")[0]
            if part.startswith(("http://", "https://", "mailto:")) or not part:
                continue
            cand = resolve(f, raw)
            if cand is not None and cand != f.resolve():
                ref_from_others.add(cand)
    orphans = [
        f for f in all_files
        if f.resolve() not in ref_from_others
        and f.name != "README.md"
        and not f.name.startswith("_")
    ]

    print("=== 断链 ===")
    for src, link in broken:
        print(f"{src} -> {link}")
    print(f"TOTAL_BROKEN={len(broken)}")
    print("\n=== 孤儿文档（未被引用且非 README）===")
    for f in orphans:
        print(f.relative_to(ROOT).as_posix())
    print(f"TOTAL_ORPHANS={len(orphans)}")
    return len(broken) + len(orphans)


def audit_paths():
    """过时 lib/ 路径检测（带降噪：跳过历史标注/否定陈述/教程占位/_ 前缀本地文件）。"""
    bad = {}
    for f in sorted(DOCS.rglob("*.md")):
        # `_` 前缀为本地滚动文档（如审计报告自身），不入库不审计
        if f.name.startswith("_"):
            continue
        lines = f.read_text(encoding="utf-8", errors="replace").splitlines()
        for i, line in enumerate(lines):
            context = line + (lines[i - 1] if i > 0 else "")
            if any(m in context for m in STALE_MARKERS):
                continue
            for m in LIB_PATH_RE.findall(line):
                if any(m.startswith(p) for p in TUTORIAL_PREFIXES):
                    continue
                p = ROOT / m.split("#")[0]
                if "{" in m or "..." in m:
                    continue
                if not p.exists():
                    bad.setdefault(f.relative_to(ROOT).as_posix(), set()).add(m)
    print("=== 过时 lib/ 路径 ===")
    for k in sorted(bad):
        print(k)
        for p in sorted(bad[k]):
            print("   ", p)
    print(f"TOTAL_FILES={len(bad)}")
    return len(bad)


def main():
    mode = sys.argv[1] if len(sys.argv) > 1 else ""
    issues = 0
    if mode in ("", "--links"):
        issues += audit_links()
    if mode in ("", "--paths"):
        issues += audit_paths()
    sys.exit(1 if issues else 0)


if __name__ == "__main__":
    main()
