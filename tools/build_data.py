"""Generates ../data/*.json for Starlight Adventure.
Run:  python3 tools/build_data.py   (from the project root)"""
import json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import gx_story as S
from gx_tasks_2026 import T26
from gx_tasks_late import TL

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA = os.path.join(ROOT, "data")
ALL_TASKS = {}
ALL_TASKS.update(T26)
ALL_TASKS.update(TL)
PROF_IDS = [p[0] for p in S.PROFESSIONS]


def room(name, bg, optional_label):
    walls = [[0, 0, 1280, 16], [0, 624, 1280, 16], [0, 0, 16, 640], [1264, 0, 16, 640], [600, 150, 24, 220]]
    st = [
        {"id": "briefing", "label": "Briefing Table", "kind": "briefing", "pos": [150, 110]},
        {"id": "duty", "label": "Duty Station", "kind": "duty", "pos": [1080, 110]},
        {"id": "npc_1", "label": "Teammate", "kind": "npc", "pos": [420, 320]},
        {"id": "npc_2", "label": "Teammate", "kind": "npc", "pos": [760, 320]},
        {"id": "npc_3", "label": "Teammate", "kind": "npc", "pos": [960, 470]},
        {"id": "optional", "label": optional_label, "kind": "optional", "pos": [330, 500]},
        {"id": "finish", "label": "Close Shift", "kind": "finish", "pos": [1120, 560]},
    ]
    for s in st:
        s["size"] = [72, 72]
    return {"name": name, "bg": bg, "world": [1280, 640], "start": [80, 400], "walls": walls, "stations": st}


def mission(mid):
    title, rname, bg, duty, opt_text, opt_label, opt_fact, learn = S.MISSIONS[mid]
    talks = {c[0]: "%s_talk_%s" % (mid, c[0]) for c in S.CREW}
    eline = S.EMERGENCY_LINES[mid]
    return {
        "id": mid,
        "title": title,
        "intro": mid + "_intro",
        "ending": mid + "_end",
        "duty_text": duty,
        "optional": {"text": opt_text, "station": opt_label, "fact": opt_fact},
        "learn": learn,
        "team": [{"id": i, "note": n} for i, n in S.TEAM_NOTES[mid]],
        "talks": talks,
        "room": room(rname, bg, opt_label),
        "emergency_script": [
            {"speaker": "mira_vale", "text": "Alert. {warning}"},
            {"speaker": eline[0], "text": eline[1]},
            {"speaker": "mira_vale", "text": "Recovery is open. Do the critical step again. The shift is not over."}],
        "tasks": ALL_TASKS[mid],
    }


def dump(name, obj):
    with open(os.path.join(DATA, name), "w", encoding="utf-8") as f:
        json.dump(obj, f, indent="\t", ensure_ascii=False)
        f.write("\n")


def main():
    os.makedirs(DATA, exist_ok=True)
    dump("professions.json", [{"id": i, "name": n, "color": c, "short": sh, "duty": du, "tools": tl}
                               for i, n, c, sh, du, tl in S.PROFESSIONS])
    dump("crew.json", [{"id": i, "name": n, "profession": p, "color": S.COLOR[p], "bio": b}
                        for i, n, p, b in S.CREW])
    dump("dialogues.json", S.build_dialogues())
    dump("flag_lines.json", {k: {"speaker": v[0], "text": v[1]} for k, v in S.FLAG_LINES.items()})
    dump("achievements.json", [{"id": i, "title": t, "text": x, "hint": h} for i, t, x, h in S.ACHIEVEMENTS])
    for year, title, campaign, tech, mids in S.YEARS:
        dump("year_%d.json" % year, {
            "year": year, "title": title, "campaign": campaign,
            "tech": {"id": tech[0], "title": tech[1], "summary": tech[2], "effect": tech[3]},
            "missions": [mission(m) for m in mids]})
    print("wrote", len(os.listdir(DATA)), "files to", DATA)


if __name__ == "__main__":
    main()
