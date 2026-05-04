#!/usr/bin/env python3
"""seed-demo.py — 一键灌入官网录屏/截图用的演示数据,录完一键还原。

用法:
  python3 seed-demo.py seed      # 备份当前 + 注入演示数据
  python3 seed-demo.py restore   # 还原最近一次备份(录完用)
  python3 seed-demo.py status    # 看当前是 demo 还是真实数据,有几份备份

设计这套 demo 的原则:
- 中英文混排(主英文 + 1-2 中文,展示 CJK 渲染)
- 8 个 active + 2 个 done,正好填满 700px 高的面板
- 优先级旗:1 高 / 2 中 / 1 低 / 4 无 — 不至于花哨
- 时间分布:1 逾期(红) / 1 today / 1 tomorrow / 2 +Nd / 3 无日期
- 标签:4 色,不超过(避免标签栏挤)
- 子任务:1 个有 4 个 subs(展示嵌套层级)
- 描述:1 个有完整描述(展示详情页)
- 4 个 snippets:含邮箱 / GitHub / 签名 / 常用回复

修改演示内容:直接改 DEMO_* 常量。
"""

import json
import shutil
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

STORE = Path.home() / "Library/Application Support/Nook/data/tasks.json"
BACKUP_DIR = STORE.parent / "_demo_backups"


def now_utc():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def date_offset(days: int) -> str:
    return (datetime.now().date() + timedelta(days=days)).isoformat()


# ─── Tags(4 色,精心搭配,不刺眼) ────────────────────────────────
DEMO_TAGS = {
    "Work":     {"color": "#5C5C6E"},   # 中性石墨
    "Side":     {"color": "#FFB74D"},   # 暖橙(独立项目)
    "Personal": {"color": "#81C784"},   # 沉静绿
    "Reading":  {"color": "#BA68C8"},   # 柔紫
}


# ─── Active tasks ─ 全英文,丰富场景(books / dev tooling / personal / 工作) ─
DEMO_TASKS = [
    # 1. 高优 + today + 4 子任务 + 描述 — 详情页主角
    {
        "id": 2001,
        "title": "Ship Nook v1.0 to the world",
        "description": "Notarize, build DMG, push v1.0 tag, draft Hacker News post for Tuesday morning launch (PT).",
        "completed": False,
        "priority": "high",
        "tags": ["Side"],
        "subtasks": [
            {"id": 1, "title": "Sign with Developer ID + hardened runtime", "completed": True},
            {"id": 2, "title": "xcrun notarytool submit + staple", "completed": True},
            {"id": 3, "title": "Test on a clean macOS install (no dev tools)", "completed": False},
            {"id": 4, "title": "Draft Show HN post + reach out to 3 friends to upvote", "completed": False},
        ],
        "nextSubId": 5,
        "dueDate": date_offset(0),
        "listId": "inbox",
        "createdAt": "2026-04-30T09:00:00Z",
        "completedAt": None,
    },

    # 2. 高优 + tomorrow + 描述 — 工作类
    {
        "id": 2002,
        "title": "Q2 OKR check-in prep",
        "description": "Pull engagement metrics, flag accounts dropped >30% MoM",
        "completed": False,
        "priority": "high",
        "tags": ["Work"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": date_offset(1),
        "listId": "inbox",
        "createdAt": "2026-05-01T10:00:00Z",
        "completedAt": None,
    },

    # 3. 中优 + 逾期(红色) + 简短 — 让 UI 显示警告色
    {
        "id": 2003,
        "title": "Reply to Stripe onboarding email",
        "description": "",
        "completed": False,
        "priority": "medium",
        "tags": ["Side"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": date_offset(-1),   # 昨天 → 逾期
        "listId": "inbox",
        "createdAt": "2026-04-28T14:00:00Z",
        "completedAt": None,
    },

    # 4. 中优 + +3d + 多标签 + 子任务 — 读书场景
    {
        "id": 2004,
        "title": "Re-read 'A Philosophy of Software Design' Ch. 5–7",
        "description": "Re-reading after writing more macOS code than originally — curious if Ousterhout's modules-as-deep advice still hits the same.",
        "completed": False,
        "priority": "medium",
        "tags": ["Reading", "Side"],
        "subtasks": [
            {"id": 1, "title": "Take notes on Ch.5: Information Hiding", "completed": False},
            {"id": 2, "title": "Try the refactor exercise on Nook codebase", "completed": False},
        ],
        "nextSubId": 3,
        "dueDate": date_offset(3),
        "listId": "inbox",
        "createdAt": "2026-04-29T20:00:00Z",
        "completedAt": None,
    },

    # 5. 中优 + +5d — 读书场景 2
    {
        "id": 2005,
        "title": "Finish 'Designing Data-Intensive Apps' Ch. 4 (Encoding)",
        "description": "",
        "completed": False,
        "priority": "medium",
        "tags": ["Reading"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": date_offset(5),
        "listId": "inbox",
        "createdAt": "2026-05-02T07:00:00Z",
        "completedAt": None,
    },

    # 6. 低优 + +7d — 独立开发琐事
    {
        "id": 2006,
        "title": "Renew melliefan.com (Cloudflare auto-renew set to off)",
        "description": "",
        "completed": False,
        "priority": "low",
        "tags": ["Side"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": date_offset(7),
        "listId": "inbox",
        "createdAt": "2026-05-02T11:00:00Z",
        "completedAt": None,
    },

    # 7. 中优 + +2d — Dev tooling
    {
        "id": 2007,
        "title": "Try Cursor 0.50 multi-edit on Nook codebase",
        "description": "",
        "completed": False,
        "priority": "medium",
        "tags": ["Side"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": date_offset(2),
        "listId": "inbox",
        "createdAt": "2026-05-03T22:00:00Z",
        "completedAt": None,
    },

    # 8. 无优先级 + 无日期 — 学习
    {
        "id": 2008,
        "title": "Watch 3Blue1Brown's intro to transformers",
        "description": "",
        "completed": False,
        "priority": "none",
        "tags": ["Reading"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-05-04T08:00:00Z",
        "completedAt": None,
    },

    # 9. 长标题 + 多标签 — 测试换行
    {
        "id": 2009,
        "title": "Catch up on 'Hard Fork' podcast — last 4 episodes on AI agents",
        "description": "",
        "completed": False,
        "priority": "none",
        "tags": ["Reading"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-05-04T09:00:00Z",
        "completedAt": None,
    },

    # 10. 低优 + +14d — Personal 决策类
    {
        "id": 2010,
        "title": "Cancel Notion sub, give Obsidian 30 days",
        "description": "",
        "completed": False,
        "priority": "low",
        "tags": ["Personal"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": date_offset(14),
        "listId": "inbox",
        "createdAt": "2026-05-04T10:00:00Z",
        "completedAt": None,
    },

    # 11. 无优先级 + 无日期 — 朴素
    {
        "id": 2011,
        "title": "Book a haircut — the stylist who actually gets it",
        "description": "",
        "completed": False,
        "priority": "none",
        "tags": ["Personal"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-05-04T11:00:00Z",
        "completedAt": None,
    },

    # 12. 最朴素的状态 — 验证空属性渲染没问题
    {
        "id": 2012,
        "title": "Buy soy milk + sweet potatoes",
        "description": "",
        "completed": False,
        "priority": "none",
        "tags": ["Personal"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-05-04T07:00:00Z",
        "completedAt": None,
    },

    # ─── Completed (展示完成态视觉:删除线 + 灰色) ───
    {
        "id": 2013,
        "title": "Submit weekly summary",
        "description": "",
        "completed": True,
        "priority": "none",
        "tags": ["Work"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-05-01T09:00:00Z",
        "completedAt": "2026-05-03T17:00:00Z",
    },
    {
        "id": 2014,
        "title": "Cancel Linear annual subscription",
        "description": "",
        "completed": True,
        "priority": "none",
        "tags": ["Side"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-04-30T15:00:00Z",
        "completedAt": "2026-05-02T10:00:00Z",
    },
    {
        "id": 2015,
        "title": "Read 'Hooked' by Nir Eyal",
        "description": "",
        "completed": True,
        "priority": "none",
        "tags": ["Reading"],
        "subtasks": [],
        "nextSubId": 1,
        "dueDate": None,
        "listId": "inbox",
        "createdAt": "2026-04-25T08:00:00Z",
        "completedAt": "2026-05-01T22:00:00Z",
    },
]


# ─── Snippets(底部快捷粘贴,4 个常用) ──────────────────────────
DEMO_SNIPPETS = [
    {
        "id": 1,
        "label": "Email",
        "value": "hello@melliefan.com",
        "type": "email",
        "createdAt": "2026-04-22T08:00:00Z",
    },
    {
        "id": 2,
        "label": "Nook on GitHub",
        "value": "https://github.com/melliefan/Nook",
        "type": "url",
        "createdAt": "2026-04-22T08:01:00Z",
    },
    {
        "id": 3,
        "label": "Email signature",
        "value": "— melliefan · Building Nook · https://melliefan.com",
        "type": "text",
        "createdAt": "2026-04-22T08:02:00Z",
    },
    {
        "id": 4,
        "label": "Quick reply",
        "value": "Thanks for the note! Will follow up by EOD.",
        "type": "text",
        "createdAt": "2026-04-22T08:03:00Z",
    },
]


# ─── Settings(用面板默认就好,不动 corner 偏好) ────────────────
def _default_settings():
    """读现有 settings,如果不存在用合理默认。"""
    if STORE.exists():
        try:
            current = json.loads(STORE.read_text(encoding="utf-8"))
            if isinstance(current.get("settings"), dict):
                return current["settings"]
        except (json.JSONDecodeError, OSError):
            pass
    return {
        "cornerTrigger": "top-left",
        "panelHeightRatio": 0.75,
        "panelWidth": 380,
    }


def build_demo_payload():
    return {
        "tasks": DEMO_TASKS,
        "nextId": 2100,
        "tags": DEMO_TAGS,
        "snippets": DEMO_SNIPPETS,
        "nextSnippetId": 100,
        "settings": _default_settings(),
    }


# ─── Commands ────────────────────────────────────────────────────
def cmd_seed():
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    if STORE.exists():
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        backup = BACKUP_DIR / f"tasks-{ts}.json"
        shutil.copy(STORE, backup)
        print(f"✓ backed up current store → {backup.name}")
    else:
        print("(no existing store to back up)")

    payload = build_demo_payload()
    STORE.parent.mkdir(parents=True, exist_ok=True)
    tmp = STORE.with_suffix(".json.tmp")
    tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(STORE)
    print(f"✓ wrote demo data: {len(DEMO_TASKS)} tasks · {len(DEMO_TAGS)} tags · {len(DEMO_SNIPPETS)} snippets")
    print("→ Nook 应该会自动刷新(file watcher),不需要重启 app")
    print("→ 录完后跑: python3 seed-demo.py restore")


def cmd_restore():
    if not BACKUP_DIR.exists():
        print("✘ no backup directory found — nothing to restore")
        sys.exit(1)
    backups = sorted(BACKUP_DIR.glob("tasks-*.json"), reverse=True)
    if not backups:
        print("✘ no backup files found in", BACKUP_DIR)
        sys.exit(1)
    latest = backups[0]
    shutil.copy(latest, STORE)
    print(f"✓ restored from {latest.name}")
    print(f"  ({len(backups)} backup(s) total in {BACKUP_DIR.name}/)")
    print("→ Nook 自动 reload,你的真实任务回来了")


def cmd_status():
    if not STORE.exists():
        print("✘ store does not exist:", STORE)
        return
    data = json.loads(STORE.read_text(encoding="utf-8"))
    n_tasks = len(data.get("tasks", []))
    n_tags = len(data.get("tags", {}))
    n_snippets = len(data.get("snippets", []))

    # 启发式判断是不是 demo 状态:看 task IDs 是不是 2001-2099 范围
    task_ids = {t.get("id") for t in data.get("tasks", [])}
    is_demo = task_ids and task_ids.issubset(set(range(2001, 2100)))
    state = "📦 DEMO" if is_demo else "👤 REAL"
    print(f"current store: {state}")
    print(f"  {n_tasks} tasks · {n_tags} tags · {n_snippets} snippets")
    print(f"  file: {STORE}")

    if BACKUP_DIR.exists():
        backups = sorted(BACKUP_DIR.glob("tasks-*.json"), reverse=True)
        print(f"\n  {len(backups)} backup(s) in {BACKUP_DIR.name}/:")
        for b in backups[:5]:
            print(f"    · {b.name}")
        if len(backups) > 5:
            print(f"    ... +{len(backups) - 5} older")


COMMANDS = {"seed": cmd_seed, "restore": cmd_restore, "status": cmd_status}


def main():
    if len(sys.argv) != 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(1)
    COMMANDS[sys.argv[1]]()


if __name__ == "__main__":
    main()
