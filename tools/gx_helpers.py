"""Pattern builders for Starlight Adventure task configs.
Every builder returns a plain dict that includes "pattern". Answers that are
numbers are computed in code so the science stays correct."""
import math


def r(x, n=2):
    return round(x, n)


def part(pid, prompt, answer, tol, unit=""):
    return {"id": pid, "prompt": prompt, "answer": r(answer), "tolerance": r(tol), "unit": unit}


def pct(v, p):
    return abs(v) * p


def enc(plain, shift):
    out = ""
    for ch in plain.upper():
        if "A" <= ch <= "Z":
            out += chr((ord(ch) - 65 + shift) % 26 + 65)
        else:
            out += ch
    return out


def route(cols, rows, start, goal, hazards, waypoints=None, ping=None):
    d = {"pattern": "route", "cols": cols, "rows": rows, "start": list(start),
         "goal": list(goal), "hazards": [list(h) for h in hazards]}
    if waypoints:
        d["waypoints"] = [list(w) for w in waypoints]
    if ping:
        d["ping"] = list(ping)
    return d


def switches(steps, order, readings, rule):
    rd = []
    for i, label, v, unit, lo, hi in readings:
        rd.append({"id": i, "label": label, "value": v, "unit": unit, "lo": lo, "hi": hi,
                   "ok": lo <= v <= hi})
    return {"pattern": "switches",
            "steps": [{"id": i, "label": l} for i, l in steps],
            "order": list(order),
            "abort": {"rule": rule, "readings": rd,
                      "should_abort": any(not x["ok"] for x in rd)}}


def burn(parts, zone, speed, given=None):
    d = {"pattern": "burn", "parts": parts, "timing": {"zone": list(zone), "speed": speed}}
    if given:
        d["given"] = given
    return d


def build(parts, gauges, bad, malfunction):
    g = []
    for i, label, v, unit, lo, hi in gauges:
        g.append({"id": i, "label": label, "value": v, "unit": unit, "lo": lo, "hi": hi,
                  "ok": lo <= v <= hi})
    return {"pattern": "build", "parts": [{"id": i, "label": l} for i, l in parts],
            "order": [i for i, _ in parts], "gauges": g, "bad_gauge": bad,
            "malfunction": malfunction}


def inspect(items, rule):
    steps = []
    for i, label, v, unit, lo, hi in items:
        steps.append({"id": i, "label": label, "value": v, "unit": unit, "lo": lo, "hi": hi,
                      "ok": lo <= v <= hi})
    return {"pattern": "inspect", "rule": rule, "steps": steps,
            "must_flag": [s["id"] for s in steps if not s["ok"]]}


def repair(symptom, rows, answer):
    return {"pattern": "repair", "symptom": symptom,
            "rows": [{"id": i, "component": c, "clue": k} for i, c, k in rows],
            "answer": answer}


def measure(given, parts, bar=None, verdict=None):
    d = {"pattern": "measure", "given": given, "parts": parts}
    if bar:
        d["bar"] = {"zone": [bar[0], bar[1]], "speed": bar[2]}
    if verdict:
        d["verdict"] = {"prompt": verdict[0], "options": verdict[1], "answer": verdict[2]}
    return d


def figure(given, parts, table=None):
    d = {"pattern": "figure", "given": given, "parts": parts}
    if table:
        d["table"] = {"prompt": table[0], "columns": table[1],
                      "rows": [{"id": i, "cells": c} for i, c in table[2]], "answer": table[3]}
    return d


def procedure(steps, question, samples, answer, conclusions):
    return {"pattern": "procedure",
            "steps": [{"id": i, "label": l} for i, l in steps],
            "order": [i for i, _ in steps],
            "question": question,
            "samples": [{"id": i, "label": l, "view": v} for i, l, v in samples],
            "answer": answer,
            "conclusions": [{"id": i, "text": t, "ok": ok} for i, t, ok in conclusions]}


def triage(patients, actions):
    pts = [{"id": i, "name": n, "vitals": v, "abnormal": ab, "note": note}
           for i, n, v, ab, note in patients]
    acts = [{"id": i, "label": l, "correct": c, "effect": e} for i, l, c, e in actions]
    return {"pattern": "triage", "scan_first": True, "patients": pts, "actions": acts,
            "correct_patient": [p["id"] for p in pts if p["abnormal"]][0],
            "correct_action": [a["id"] for a in acts if a["correct"]][0]}


def tune(target, lo, hi, step, tol, unit, backup, cipher=None, interference=None):
    d = {"pattern": "tune",
         "frequency": {"min": lo, "max": hi, "step": step, "target": target,
                       "tolerance": tol, "unit": unit},
         "backup_frequency": backup}
    if cipher:
        plain, shift = cipher
        d["cipher"] = {"text": enc(plain, shift), "shift": shift, "answer": plain.upper()}
    if interference:
        d["interference"] = {"options": interference[0], "answer": interference[1]}
    return d


def channels(rule, items):
    return {"pattern": "channels", "rule": rule,
            "channels": [{"id": i, "label": l, "reading": rd, "expected": e}
                         for i, l, rd, e in items]}


def link(parts, messages, budget, decode=None):
    msgs = []
    for m in messages:
        mid, text, ok = m[0], m[1], m[2]
        e = {"id": mid, "text": text, "chars": len(text), "ok": ok}
        if len(m) > 3 and m[3]:
            e["flags"] = m[3]
        if len(m) > 4 and m[4]:
            e["lasting"] = m[4]
        if len(m) > 5 and m[5]:
            e["consequence"] = m[5]
        msgs.append(e)
    d = {"pattern": "link", "parts": parts, "budget_chars": budget, "messages": msgs}
    if decode:
        plain, shift, f_full, f_part = decode
        d["decode"] = {"text": enc(plain, shift), "shift": shift, "answer": plain.upper(),
                       "flag_full": f_full, "flag_partial": f_part}
    return d


def priority(events, total=45):
    return {"pattern": "priority", "seconds_total": total,
            "events": [{"id": i, "label": l, "kind": k, "rank": rk, "seconds": s, "needs": n}
                       for i, l, k, rk, s, n in events]}


def decision(prompt, choices):
    out = []
    for c in choices:
        cid, text, result, cons = c[0], c[1], c[2], c[3]
        e = {"id": cid, "text": text, "result": result, "consequence": cons}
        if len(c) > 4 and c[4]:
            e["flags"] = c[4]
            e["lasting"] = list(c[4].keys()) if (len(c) > 5 and c[5]) else []
        out.append(e)
    return {"pattern": "decision", "prompt": prompt, "choices": out}


def T(base, title, science, hint, eid, warning, mistake, fail_flag=None, **extra):
    t = dict(base)
    t["title"] = title
    t["science"] = science
    t["hint"] = hint
    t["mistake"] = mistake
    t["emergency"] = {"id": eid, "warning": warning}
    if fail_flag:
        t["emergency"]["fail_flag"] = fail_flag
    t.update(extra)
    return t


def ai(says, why):
    return {"says": says, "answer": "reject", "why": why, "flag": "ai_rejected"}
