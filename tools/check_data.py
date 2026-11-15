"""Checks ../data against the rules in scripts/model/content_validator.gd
plus extra sanity checks (paths exist, answers are consistent, no em dashes).
Run:  python3 tools/check_data.py   (from the project root). Exit code 1 on errors."""
import json, os, re, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA = os.path.join(ROOT, "data")
PROFS = ["astronaut", "engineer", "physicist", "mathematician", "biologist", "medical", "comms", "director"]
ACH_IDS = ["first_shift", "clean_sheet", "steady_hands", "classified", "frontier",
           "verified", "first_contact", "long_listen", "cross_train"]
TOKENS = {"{callsign}", "{profession_name}", "{year}", "{warning}"}
errors = []


def err(msg):
    errors.append(msg)


def load(name):
    with open(os.path.join(DATA, name), encoding="utf-8") as f:
        return json.load(f)


def all_strings(o):
    if isinstance(o, str):
        yield o
    elif isinstance(o, dict):
        for k, v in o.items():
            yield k
            yield from all_strings(v)
    elif isinstance(o, list):
        for v in o:
            yield from all_strings(v)


def find_path(cols, rows, start, goal, hazards, waypoints):
    hz = {tuple(h) for h in hazards}
    wps = [tuple(w) for w in waypoints]
    start, goal = tuple(start), tuple(goal)
    if start in hz or goal in hz or any(w in hz for w in wps):
        return None
    sys.setrecursionlimit(10000)
    seen = {start}

    def dfs(cell, idx):
        if cell == goal and idx == len(wps):
            return [cell]
        for dx, dy in ((1, 0), (0, -1), (0, 1), (-1, 0)):
            n = (cell[0] + dx, cell[1] + dy)
            if not (0 <= n[0] < cols and 0 <= n[1] < rows) or n in hz or n in seen:
                continue
            nidx = idx + 1 if idx < len(wps) and n == wps[idx] else idx
            if n == goal and nidx != len(wps):
                continue
            seen.add(n)
            res = dfs(n, nidx)
            if res:
                return [cell] + res
            seen.discard(n)
        return None

    return dfs(start, 1 if wps and start == wps[0] else 0)


def check_task(prefix, t, year):
    for f in ["pattern", "title", "science", "hint", "emergency", "mistake"]:
        if f not in t:
            err("%s missing %s" % (prefix, f))
    em = t.get("emergency", {})
    if not isinstance(em, dict) or "id" not in em or "warning" not in em:
        err("%s emergency needs id and warning" % prefix)
    p = t.get("pattern")
    need = {"route": ["cols", "rows", "start", "goal", "hazards"], "switches": ["steps", "order"],
            "burn": ["parts", "timing"], "build": ["parts", "order", "gauges"], "inspect": ["steps"],
            "repair": ["symptom", "rows"], "measure": ["parts"], "figure": ["parts"],
            "procedure": ["steps", "question", "samples", "answer", "conclusions"],
            "triage": ["patients", "actions"], "tune": ["frequency"], "channels": ["channels"],
            "link": ["parts", "messages"], "priority": ["events"], "decision": ["prompt", "choices"]}
    if p not in need:
        err("%s unknown pattern %s" % (prefix, p))
        return
    for f in need[p]:
        if f not in t:
            err("%s %s missing %s" % (prefix, p, f))
    for part in (t.get("parts", []) if p in ("burn", "measure", "figure", "link") else []):
        for f in ["id", "prompt", "answer", "tolerance"]:
            if f not in part:
                err("%s part missing %s" % (prefix, f))
    if p == "route":
        if find_path(t["cols"], t["rows"], t["start"], t["goal"], t["hazards"], t.get("waypoints", [])) is None:
            err("%s route has no valid path" % prefix)
    if p == "switches":
        ids = [s["id"] for s in t["steps"]]
        if sorted(ids) != sorted(t["order"]):
            err("%s switch order does not match steps" % prefix)
    if p == "build":
        bad = [g["id"] for g in t["gauges"] if not g["ok"]]
        if bad != [t.get("bad_gauge")]:
            err("%s build must have exactly one bad gauge (the named one)" % prefix)
    if p == "inspect" and not t.get("must_flag"):
        err("%s inspect has nothing to flag" % prefix)
    if p == "repair" and t["answer"] not in [r["id"] for r in t["rows"]]:
        err("%s repair answer not in rows" % prefix)
    if p == "procedure":
        if t["answer"] not in [s["id"] for s in t["samples"]]:
            err("%s procedure answer not in samples" % prefix)
        if sum(1 for c in t["conclusions"] if c["ok"]) != 1:
            err("%s procedure needs exactly one ok conclusion" % prefix)
        if t["order"][0] not in ("sterilize", "check"):
            err("%s procedure should start with a sterilize or check step" % prefix)
    if p == "triage":
        if sum(1 for x in t["patients"] if x["abnormal"]) != 1 or sum(1 for a in t["actions"] if a["correct"]) != 1:
            err("%s triage needs one abnormal patient and one correct action" % prefix)
    if p == "tune":
        f = t["frequency"]
        if not (f["min"] <= f["target"] <= f["max"]) or not (f["min"] <= t["backup_frequency"] <= f["max"]):
            err("%s tune target or backup outside the range" % prefix)
        if "cipher" in t:
            c = t["cipher"]
            dec = "".join(chr((ord(ch) - 65 - c["shift"]) % 26 + 65) if "A" <= ch <= "Z" else ch for ch in c["text"])
            if dec != c["answer"]:
                err("%s cipher does not decode to its answer" % prefix)
    if p == "channels":
        for c in t["channels"]:
            if c["expected"] not in ("GO", "HOLD"):
                err("%s channel expected must be GO or HOLD" % prefix)
    if p == "link":
        oks = [m for m in t["messages"] if m["ok"]]
        if len(oks) != 1:
            err("%s link needs exactly one ok message" % prefix)
        for m in t["messages"]:
            if m["chars"] != len(m["text"]):
                err("%s message chars mismatch" % prefix)
        for m in oks:
            if m["chars"] > t["budget_chars"]:
                err("%s ok message is over budget" % prefix)
        if "decode" in t:
            d = t["decode"]
            dec = "".join(chr((ord(ch) - 65 - d["shift"]) % 26 + 65) if "A" <= ch <= "Z" else ch for ch in d["text"])
            if dec != d["answer"]:
                err("%s decode mismatch" % prefix)
    if p == "priority":
        ranks = [e["rank"] for e in t["events"]]
        if sorted(ranks) != list(range(1, len(ranks) + 1)) or not any(e["kind"] == "life" and e["rank"] == 1 for e in t["events"]):
            err("%s priority ranks must be 1..n with life safety first" % prefix)
    if p == "decision":
        if sum(1 for c in t["choices"] if c["result"] == "success") < 1 and year != 2026:
            pass
        if not any(c["result"] in ("success", "success_cost") for c in t["choices"]):
            err("%s decision has no passing choice" % prefix)
        for c in t["choices"]:
            if c["result"] not in ("success", "success_cost", "fail"):
                err("%s decision result invalid" % prefix)
    if year == 2027 and "ai" not in t:
        err("%s missing ai block for 2027" % prefix)


def main():
    professions = load("professions.json")
    crew = load("crew.json")
    dialogues = load("dialogues.json")
    flag_lines = load("flag_lines.json")
    achievements = load("achievements.json")
    years = [load("year_%d.json" % y) for y in range(2026, 2032)]

    if sorted(p["id"] for p in professions) != sorted(PROFS):
        err("professions.json must have exactly the 8 profession ids")
    crew_ids = {c["id"] for c in crew}
    prof_of = {c["id"]: c["profession"] for c in crew}
    if sorted(prof_of.values()) != sorted(PROFS):
        err("crew must cover each profession once")
    if prof_of.get("samira_shah") == prof_of.get("alex_rivera"):
        err("samira_shah and alex_rivera must have different professions")
    ach_ids = {a["id"] for a in achievements}
    for i in ACH_IDS:
        if i not in ach_ids:
            err("Missing achievement text for %s." % i)

    seen = set()
    flags_set = set()
    mission_ids = []
    for yd in years:
        if "tech" not in yd:
            err("Year %s has no technology." % yd.get("year"))
        for m in yd["missions"]:
            mid = m["id"]
            mission_ids.append(mid)
            if not mid or mid in seen:
                err("Duplicate or blank mission id %s." % mid)
            seen.add(mid)
            if m["intro"] not in dialogues:
                err("%s is missing its intro dialogue." % mid)
            if m["ending"] not in dialogues:
                err("%s is missing its ending dialogue." % mid)
            for crew_id, did in m.get("talks", {}).items():
                if did not in dialogues:
                    err("%s talk %s missing" % (mid, did))
                if crew_id not in crew_ids:
                    err("%s talk crew %s unknown" % (mid, crew_id))
            tasks = m["tasks"]
            for prof in PROFS:
                if prof not in tasks:
                    err("%s has no %s duty." % (mid, prof))
                    continue
                check_task("%s/%s" % (mid, prof), tasks[prof], yd["year"])
            blob = json.dumps(m).lower()
            if yd["year"] < 2030 and "first contact" in blob:
                err("%s mentions first contact before 2030." % mid)
            if yd["year"] <= 2026 and "we found aliens" in blob:
                err("%s claims an alien encounter." % mid)
            for s in m["room"]["stations"]:
                if not (0 < s["pos"][0] < 1280 and 0 < s["pos"][1] < 640):
                    err("%s station %s out of bounds" % (mid, s["id"]))
            for tk in m["tasks"].values():
                for key in ("flags",):
                    pass
    # flags set anywhere
    def collect_flags(o):
        if isinstance(o, dict):
            for k, v in o.items():
                if k in ("flags", "lasting") and isinstance(v, dict):
                    flags_set.update(v.keys())
                elif k == "fail_flag" and isinstance(v, str):
                    flags_set.add(v)
                elif k == "flag" and isinstance(v, str):
                    flags_set.add(v)
                else:
                    collect_flags(v)
        elif isinstance(o, list):
            for v in o:
                collect_flags(v)
    collect_flags(years)
    collect_flags(dialogues)
    for needed in ("ai_rejected", "jumped_to_aliens", "premature_hail"):
        if needed not in flags_set:
            err("Nothing sets the flag %s, so its achievement logic cannot work." % needed)

    # dialogues
    for did, d in dialogues.items():
        if d.get("next") and d["next"] not in dialogues:
            err("dialogue %s next %s missing" % (did, d["next"]))
        for ln in d.get("lines", []):
            if "choices" in ln:
                for ch in ln["choices"]:
                    if ch.get("goto") and ch["goto"] not in dialogues:
                        err("dialogue %s goto %s missing" % (did, ch["goto"]))
                    if ch.get("flag"):
                        flags_set.add(ch["flag"])
            else:
                sp = ln.get("speaker")
                if sp != "player" and sp not in crew_ids:
                    err("dialogue %s unknown speaker %s" % (did, sp))
    for k, v in flag_lines.items():
        if v["speaker"] not in crew_ids:
            err("flag_lines %s speaker unknown" % k)
    if "new_beginnings_end" in dialogues:
        if "ORIGIN UNCONFIRMED" not in json.dumps(dialogues["new_beginnings_end"]):
            err("The 2026 ending does not classify the signal.")
    else:
        err("new_beginnings_end missing")

    # text hygiene
    for name in os.listdir(DATA):
        if not name.endswith(".json"):
            continue
        for s in all_strings(load(name)):
            if "\u2014" in s or "\u2013" in s:
                err("%s contains a dash character: %s" % (name, s[:60]))
            for tok in re.findall(r"\{[a-z_]+\}", s):
                if tok not in TOKENS:
                    err("%s unknown token %s in: %s" % (name, tok, s[:60]))

    if errors:
        print("%d problem(s):" % len(errors))
        for e in errors:
            print(" -", e)
        sys.exit(1)
    print("OK: %d missions, %d tasks, %d dialogues." % (len(mission_ids), len(mission_ids) * 8, len(dialogues)))


if __name__ == "__main__":
    main()
