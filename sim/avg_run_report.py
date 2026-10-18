#!/usr/bin/env python3
"""Aggregate average post-fight trajectory across many runs."""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict

from era1_sim import play_eras, ERA_BASE_DEFENCE

FIGHT_LABELS = [
    (1, "village"), (1, "town"), (1, "capital"),
    (2, "village"), (2, "town"), (2, "capital"),
    (3, "village"), (3, "town"), (3, "capital"),
]


def avg(xs):
    return round(sum(xs) / len(xs), 2) if xs else None


def pct(xs, p):
    if not xs:
        return None
    ys = sorted(xs)
    return ys[min(len(ys) - 1, int(p / 100 * (len(ys) - 1)))]


def aggregate(runs: list[dict], max_era: int) -> dict:
    # Index trajectories by fight_index among survivors of that fight
    by_fight: dict[int, list[dict]] = defaultdict(list)
    for r in runs:
        for step in r.get("trajectory", []):
            by_fight[step["fight_index"]].append(step)

    fight_rows = []
    for fi in range(1, max_era * 3 + 1):
        steps = by_fight.get(fi, [])
        if not steps:
            continue
        era = (fi - 1) // 3 + 1
        kind = ["village", "town", "capital"][(fi - 1) % 3]
        n = len(steps)

        sci_ups = [s["science_level_ups_this_fight"] for s in steps]
        civ_ups = [s["civic_level_ups_this_fight"] for s in steps]
        troop_any = sum(1 for s in steps if s["troop_upgrades_this_fight"]) / n
        troop_counts = Counter()
        for s in steps:
            for k, v in s["troop_upgrades_this_fight"].items():
                if v:
                    troop_counts[k] += 1
        sci_pick_counts = Counter()
        for s in steps:
            for p in s["science_picks"]:
                sci_pick_counts[p] += 1
        civ_pick_counts = Counter()
        for s in steps:
            for p in s["civic_picks"]:
                civ_pick_counts[p] += 1
        bp_gains = Counter()
        for s in steps:
            for b in s["new_blueprints"]:
                bp_gains[b] += 1
        doc_gains = Counter()
        for s in steps:
            for d in s["new_doctrines"]:
                doc_gains[d] += 1
        pol_gains = Counter()
        for s in steps:
            for p in s["new_policies"]:
                pol_gains[p] += 1
        occupy = Counter(s["occupy_or_raze"] for s in steps)
        occ_type = Counter(s["occupied_type"] for s in steps if s["occupied_type"])

        after = [s["after"] for s in steps]
        row = {
            "fight_index": fi,
            "era": era,
            "kind": kind,
            "survivors_n": n,
            "survivor_rate_of_starts": round(n / len(runs), 3),
            "defence": int(ERA_BASE_DEFENCE[era] * {"village": 1, "town": 1.5, "capital": 2.5}[kind]),
            "avg_damage": avg([s["damage"] for s in steps]),
            "avg_assaults_used": avg([s["assaults_used"] for s in steps]),
            # economy after post-fight resolution
            "avg_gold_after": avg([a["gold"] for a in after]),
            "avg_faith_after": avg([a["faith"] for a in after]),
            "avg_science_bank": avg([a["science_bank"] for a in after]),
            "avg_culture_bank": avg([a["culture_bank"] for a in after]),
            "avg_gold_delta": avg([s["gold_delta"] for s in steps]),
            "avg_faith_delta": avg([s["faith_delta"] for s in steps]),
            # level-ups this fight
            "pct_got_science_level_up": round(sum(1 for x in sci_ups if x > 0) / n, 3),
            "avg_science_level_ups": avg(sci_ups),
            "pct_got_civic_level_up": round(sum(1 for x in civ_ups if x > 0) / n, 3),
            "avg_civic_level_ups": avg(civ_ups),
            "avg_sci_levels_total": avg([a["sci_levels_taken"] for a in after]),
            "avg_civ_levels_total": avg([a["civ_levels_taken"] for a in after]),
            "top_science_picks": sci_pick_counts.most_common(8),
            "top_civic_picks": civ_pick_counts.most_common(6),
            # troops
            "pct_any_troop_upgrade": round(troop_any, 3),
            "troop_upgrade_rate_by_class": {k: round(v / n, 3) for k, v in troop_counts.most_common()},
            "avg_tiers_after": {
                k: avg([a["tiers"][k] for a in after]) for k in ("M", "R", "C", "S", "B")
            },
            "avg_tier_sum": avg([a["tier_sum"] for a in after]),
            "avg_form_level_sum": avg([a["form_level_sum"] for a in after]),
            # shop / modifiers
            "pct_bought_unit": round(sum(1 for s in steps if s["units_bought"] > 0) / n, 3),
            "avg_units_bought": avg([s["units_bought"] for s in steps]),
            "pct_gained_special_unit": round(sum(1 for s in steps if s["special_units_gained"] > 0) / n, 3),
            "avg_special_units_total": avg([a["special_unit_count"] for a in after]),
            "pct_gained_promotion": round(sum(1 for s in steps if s["promotions_gained"] > 0) / n, 3),
            "avg_promoted_cards": avg([a["promoted_card_count"] for a in after]),
            "pct_new_blueprint": round(sum(1 for s in steps if s["new_blueprints"]) / n, 3),
            "avg_blueprints": avg([a["blueprint_count"] for a in after]),
            "top_new_blueprints": bp_gains.most_common(6),
            "pct_new_doctrine": round(sum(1 for s in steps if s["new_doctrines"]) / n, 3),
            "avg_doctrines": avg([a["doctrine_count"] for a in after]),
            "top_new_doctrines": doc_gains.most_common(6),
            "pct_new_policy": round(sum(1 for s in steps if s["new_policies"]) / n, 3),
            "avg_policies": avg([a["policy_count"] for a in after]),
            "top_new_policies": pol_gains.most_common(6),
            "occupy_rate": round(occupy.get("occupy", 0) / n, 3),
            "raze_rate": round(occupy.get("raze", 0) / n, 3),
            "occupy_types": dict(occ_type),
            "avg_deck_size": avg([a["deck_size"] for a in after]),
            "avg_builder_scale": avg([a["builder_scale"] for a in after]),
            "avg_hand_size": avg([a["hand_size"] for a in after]),
            "avg_regroups": avg([a["base_regroups"] for a in after]),
        }
        fight_rows.append(row)

    # Cumulative upgrade density by end of each era (among era clearers)
    era_end = {}
    for e in range(1, max_era + 1):
        fi = e * 3
        steps = by_fight.get(fi, [])
        if not steps:
            era_end[e] = None
            continue
        after = [s["after"] for s in steps]
        era_end[e] = {
            "n": len(steps),
            "avg_sci_levels": avg([a["sci_levels_taken"] for a in after]),
            "avg_civ_levels": avg([a["civ_levels_taken"] for a in after]),
            "avg_tiers": {k: avg([a["tiers"][k] for a in after]) for k in ("M", "R", "C", "S", "B")},
            "avg_tier_sum": avg([a["tier_sum"] for a in after]),
            "avg_blueprints": avg([a["blueprint_count"] for a in after]),
            "avg_doctrines": avg([a["doctrine_count"] for a in after]),
            "avg_policies": avg([a["policy_count"] for a in after]),
            "avg_special_units": avg([a["special_unit_count"] for a in after]),
            "avg_form_levels": avg([a["form_level_sum"] for a in after]),
            "avg_gold": avg([a["gold"] for a in after]),
            "avg_faith": avg([a["faith"] for a in after]),
        }

    return {
        "starts": len(runs),
        "max_era": max_era,
        "defence_bases": ERA_BASE_DEFENCE,
        "per_fight": fight_rows,
        "era_end_loadout": {str(k): v for k, v in era_end.items()},
    }


def markdown_report(data: dict, strategy: str) -> str:
    lines = [
        f"# Average run trajectory — {strategy}",
        "",
        f"N={data['starts']} starts · eras 1–{data['max_era']} · Defence bases { {k: data['defence_bases'][k] for k in range(1, data['max_era']+1)} }",
        "",
        "Each row is averaged over bots that **won that fight** (survivor bias: later fights are the stronger runs).",
        "",
        "## Post-fight averages",
        "",
        "| Fight | Surv% | Dmg | Gold | Faith | Sci↑% | Civ↑% | Troop↑% | Sci lv | Civ lv | Tiers M/R/C/S/B | BP | Doc | Pol | Special | Promo | Deck |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for r in data["per_fight"]:
        t = r["avg_tiers_after"]
        tiers = f"{t['M']:.1f}/{t['R']:.1f}/{t['C']:.1f}/{t['S']:.1f}/{t['B']:.1f}"
        lines.append(
            f"| E{r['era']} {r['kind'][:3]} | {r['survivor_rate_of_starts']:.0%} | "
            f"{r['avg_damage']:.0f}/{r['defence']} | {r['avg_gold_after']:.0f} | {r['avg_faith_after']:.0f} | "
            f"{r['pct_got_science_level_up']:.0%} | {r['pct_got_civic_level_up']:.0%} | "
            f"{r['pct_any_troop_upgrade']:.0%} | {r['avg_sci_levels_total']:.1f} | {r['avg_civ_levels_total']:.1f} | "
            f"{tiers} | {r['avg_blueprints']:.1f} | {r['avg_doctrines']:.1f} | {r['avg_policies']:.1f} | "
            f"{r['avg_special_units_total']:.2f} | {r['avg_promoted_cards']:.2f} | {r['avg_deck_size']:.1f} |"
        )

    lines += ["", "## What you typically pick / buy (rate among survivors of that fight)", ""]
    for r in data["per_fight"]:
        lines.append(f"### E{r['era']} {r['kind']} (n={r['survivors_n']}, occupy {r['occupy_rate']:.0%})")
        lines.append(f"- Science picks: {r['top_science_picks'][:5]}")
        lines.append(f"- Civic picks: {r['top_civic_picks'][:4]}")
        lines.append(f"- Troop upgrade rates: {r['troop_upgrade_rate_by_class']}")
        lines.append(
            f"- Shop: unit buy {r['pct_bought_unit']:.0%}, special unit {r['pct_gained_special_unit']:.0%}, "
            f"promotion {r['pct_gained_promotion']:.0%}, blueprint {r['pct_new_blueprint']:.0%}, "
            f"doctrine {r['pct_new_doctrine']:.0%}, policy {r['pct_new_policy']:.0%}"
        )
        lines.append(f"- Top new BP: {r['top_new_blueprints'][:4]} · Doc: {r['top_new_doctrines'][:4]} · Pol: {r['top_new_policies'][:4]}")
        lines.append("")

    lines += ["## Loadout at end of each era (Capital survivors)", ""]
    for e, v in data["era_end_loadout"].items():
        if not v:
            lines.append(f"- Era {e}: no survivors")
            continue
        lines.append(
            f"- **Era {e}** (n={v['n']}): sci_levels={v['avg_sci_levels']}, civ={v['avg_civ_levels']}, "
            f"tiers={v['avg_tiers']}, BP={v['avg_blueprints']}, Doc={v['avg_doctrines']}, "
            f"Pol={v['avg_policies']}, specials={v['avg_special_units']}, "
            f"form_lv={v['avg_form_levels']}, gold={v['avg_gold']}, faith={v['avg_faith']}"
        )

    lines += [
        "",
        "## Read on upgrade stack density",
        "",
        "If `avg_sci_levels` after era 1 is ~1–2 and Blueprints/Doctrines stay near 0–1, "
        "the run is starved for the multipliers needed by Medieval Capital (5000 HP). "
        "That matches the era‑3 cliff in `ERA3_REPORT.md`.",
        "",
    ]
    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=300)
    ap.add_argument("--eras", type=int, default=3)
    ap.add_argument("--seed", type=int, default=7)
    ap.add_argument("--strategy", default="S3")
    ap.add_argument("--all-strategies", action="store_true")
    args = ap.parse_args()

    strategies = ["S1", "S2", "S3", "S4", "S5", "S6", "BALANCED"] if args.all_strategies else [args.strategy]
    combined = {}
    md_parts = []
    for strat in strategies:
        runs = []
        for i in range(args.runs):
            runs.append(play_eras(args.seed + i * 19 + hash(strat) % 9000, strat, max_era=args.eras))
        data = aggregate(runs, args.eras)
        combined[strat] = data
        md_parts.append(markdown_report(data, strat))
        end_sci = []
        for e in range(1, args.eras + 1):
            block = data.get("era_end_loadout", {}).get(str(e))
            end_sci.append(None if not block else block.get("avg_sci_levels"))
        print(f"{strat}: fights logged={[r['fight_index'] for r in data['per_fight']]} era_end_sci={end_sci}")

    out_json = "/workspace/sim/results/avg_run_trajectory.json"
    out_md = "/workspace/sim/results/AVERAGE_RUN_REPORT.md"
    with open(out_json, "w") as f:
        json.dump(combined, f, indent=2)
    with open(out_md, "w") as f:
        f.write("# Average run reports\n\n")
        f.write("Goal: see how often gold / Science / Civics / troop upgrades / specials / packs land after each fight.\n\n")
        f.write("---\n\n")
        f.write("\n\n---\n\n".join(md_parts))
    print(f"Wrote {out_json} and {out_md}")


if __name__ == "__main__":
    main()
