#!/usr/bin/env python3
"""Auto memory extraction — runs at Stop hook. Reads JSONL, updates session.md + decisions.md."""
import os, json, datetime, glob, re

try:
    PD = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    root = os.popen(
        'git -C "' + PD + '" rev-parse --show-toplevel 2>/dev/null'
    ).read().strip() or os.path.expanduser("~/claude-os")
    jdir = os.path.expanduser("~/.claude/projects/" + PD.replace("/", "-"))
    jfiles = sorted(glob.glob(jdir + "/*.jsonl"), key=os.path.getmtime, reverse=True)

    msgs, files, decs = [], [], []
    DKW = [
        "决定",
        "改成",
        "选择",
        "原因是",
        "因为",
        "不用",
        "换成",
        "decided",
        "chose",
        "reason",
        "instead",
    ]

    if jfiles:
        for line in open(jfiles[0]).readlines()[-200:]:
            try:
                e = json.loads(line)
                if e.get("type") == "assistant":
                    for c in e.get("message", {}).get("content") or []:
                        if isinstance(c, dict) and c.get("type") == "text":
                            t = c["text"][:150]
                            msgs.append(t)
                            if any(k in t for k in DKW):
                                decs.append(t)
                fp = (e.get("tool_input") or e.get("input") or {}).get("file_path", "")
                if fp:
                    files.append(fp)
            except Exception:
                pass

    today = datetime.date.today().isoformat()
    pname = os.path.basename(PD) or PD
    sf = os.path.join(root, "memory", "session.md")

    # Feature 1 & 3: Update session.md with Active Project + Last Session
    if os.path.exists(sf):
        c = open(sf).read()
        ls_f = (
            ", ".join(dict.fromkeys(os.path.basename(x) for x in files[-5:])) or "none"
        )
        lm = ((msgs[-1] if msgs else "no record")[:80]).replace("\n", " ")
        ap = (
            "## Active Project\n项目："
            + pname
            + "\n路径："
            + PD
            + "\n最后活跃："
            + today
            + "\n\n"
        )
        ls = (
            "\n## Last Session（自动生成，" + today + "）\n"
            "- 项目：" + pname + "\n"
            "- 做了：" + lm + "\n"
            "- 改了：" + ls_f + "\n"
            "- 状态：自动提取\n"
        )
        c = re.sub(
            r"\n*## Active Project.*?(?=\n## |\Z)", "", c, flags=re.DOTALL
        ).lstrip()
        c = re.sub(
            r"\n*## Last Session.*?(?=\n## |\Z)", "", c, flags=re.DOTALL
        ).rstrip()
        open(sf, "w").write(ap + c + ls)

    # Feature 2: Append decisions to decisions.md
    if decs:
        df = os.path.join(root, "memory", "decisions.md")
        with open(df, "a") as f:
            f.write("\n## " + today + " 自动提取（JSONL）\n")
            for d in decs[:5]:
                f.write(
                    "- ["
                    + today
                    + "]["
                    + pname
                    + "] "
                    + d[:100].replace("\n", " ")
                    + "\n"
                )

    # Log
    lf = os.path.expanduser("~/claude-os/logs/memory-auto.log")
    with open(lf, "a") as f:
        f.write(
            "["
            + datetime.datetime.now().isoformat()
            + "] session结束 → 提取"
            + str(len(decs[:5]))
            + "条决策，更新project："
            + pname
            + "\n"
        )
    print(
        "[claude-os] auto-memory: "
        + str(len(decs[:5]))
        + " decisions, project="
        + pname
    )

except Exception:
    pass
