#!/usr/bin/env python3
"""Contribution / ablation sims — what systems actually carry clear rates?

Compares baseline clear-through rates to runs with one system disabled.
Also aggregates utilization (offer/pick/buy counts) from baseline runs.

Usage:
  python3 sim/contribution_sim.py --eras 3 --runs 80 --seed 42
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import Counter, defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from era1_sim import play_eras, summarize, ERA_BASE_DEFENCE  # noqa: E402

STRATEGIES = ["S1", "S2", "S3", "S4", "S5", "S6"]

ABLATIONS = {
    "baseline": set(),
    "no_science": {"no_science"},
    "no_civics": {"no_civics"},
    "no_troop_upgrades": {"no_troop_upgrades"},
    "no_wonders": {"no_wonders"},
    "no_blueprints": {"no_blueprints"},
    "no_doctrines": {"no_doctrines"},
    "no_promotions": {"no_promotions"},
    "no_editions": {"no_editions"},
    "no_policies": {"no_policies"},
}


def run_batch(strategy: str, ablation: set, n: int, seed: int, eras: int) -> list[dict]:
    runs = []
    tag = ",".join(sorted(ablation)) or "baseline"
    for i in range(n):
        r = play_eras(
            seed + i * 31 + hash(strategy + tag) % 10000,
            strategy,
            max_era=eras,
            ablation=ablation,
        )
        runs.append(r)
    return runs


def merge_util(runs: list[dict]) -> dict:
    out: dict[str, Counter] = defaultdict(Counter)
    for r in runs:
        for bag, counts in (r.get("util") or {}).items():
            out[bag].update(counts)
    return {k: dict(v.most_common(40)) for k, v in out.items()}


def wonder_own_rate(runs: list[dict]) -> dict:
    n = len(runs)
    c = Counter(r.get("wonder") or "(none)" for r in runs)
    return {k: round(v / n, 3) for k, v in c.most_common()}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=60, help="Runs per strategy per ablation")
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--eras", type=int, default=3)
    ap.add_argument("--quick", action="store_true", help="Fewer ablations + strategies")
    args = ap.parse_args()

    strategies = STRATEGIES
    ablations = ABLATIONS
    if args.quick:
        strategies = ["S2", "S3", "S5"]
        ablations = {k: ABLATIONS[k] for k in (
            "baseline", "no_science", "no_civics", "no_troop_upgrades",
            "no_blueprints", "no_doctrines", "no_wonders", "no_promotions",
        )}

    report = {
        "meta": {
            "runs_per_cell": args.runs,
            "eras": args.eras,
            "seed": args.seed,
            "defence_bases": ERA_BASE_DEFENCE,
            "question": "Which systems carry clear rate / capital damage?",
        },
        "by_strategy": {},
        "ablation_delta_mean": {},
    }

    # Mean clear-through across strategies for each ablation
    mean_clear = defaultdict(lambda: defaultdict(list))

    for strat in strategies:
        cell = {}
        baseline_runs = run_batch(strat, set(), args.runs, args.seed, args.eras)
        base_sum = summarize(baseline_runs, max_era=args.eras)
        cell["baseline"] = {
            "clear_through_era": base_sum["clear_through_era"],
            "power_curve": base_sum["power_curve"],
            "wonder_own_rate": wonder_own_rate(baseline_runs),
            "util": merge_util(baseline_runs),
            "mean_sci_level": round(
                sum(r.get("sci_level", 0) for r in baseline_runs) / len(baseline_runs), 2),
            "mean_civ_level": round(
                sum(r.get("civ_level", 0) for r in baseline_runs) / len(baseline_runs), 2),
            "mean_bp": round(
                sum(len(r.get("blueprints") or []) for r in baseline_runs) / len(baseline_runs), 2),
            "mean_doc": round(
                sum(len(r.get("doctrines") or []) for r in baseline_runs) / len(baseline_runs), 2),
        }
        for e, rate in base_sum["clear_through_era"].items():
            mean_clear["baseline"][e].append(rate)

        for name, flags in ablations.items():
            if name == "baseline":
                continue
            runs = run_batch(strat, flags, args.runs, args.seed, args.eras)
            sm = summarize(runs, max_era=args.eras)
            deltas = {}
            for e, rate in sm["clear_through_era"].items():
                base = base_sum["clear_through_era"][e]
                deltas[e] = round(rate - base, 3)
                mean_clear[name][e].append(rate)
            # Capital damage ratio delta at max era
            emax = str(args.eras)
            base_ratio = (base_sum["power_curve"].get(emax) or {}).get("damage_to_hp_ratio_p50")
            abl_ratio = (sm["power_curve"].get(emax) or {}).get("damage_to_hp_ratio_p50")
            cell[name] = {
                "clear_through_era": sm["clear_through_era"],
                "clear_delta_vs_baseline": deltas,
                "cap_damage_hp_p50": abl_ratio,
                "cap_ratio_delta": (
                    round(abl_ratio - base_ratio, 3)
                    if abl_ratio is not None and base_ratio is not None else None
                ),
            }
            print(f"{strat} {name}: clearΔ={deltas} cap_ratioΔ={cell[name]['cap_ratio_delta']}")

        report["by_strategy"][strat] = cell

    for name, eras in mean_clear.items():
        report["ablation_delta_mean"][name] = {
            e: round(sum(xs) / len(xs), 3) for e, xs in eras.items()
        }
    # Express non-baseline as delta from baseline mean
    base_mean = report["ablation_delta_mean"]["baseline"]
    report["ablation_delta_mean_vs_baseline"] = {
        name: {e: round(rates[e] - base_mean[e], 3) for e in rates}
        for name, rates in report["ablation_delta_mean"].items()
        if name != "baseline"
    }

    # Era-tagged outputs so an 8-era run does not clobber the E3 report
    tag = f"E{args.eras}"
    out = Path(f"/workspace/sim/results/CONTRIBUTION_REPORT_{tag}.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2))
    # Keep legacy untagged names in sync for the default 3-era workflow
    if args.eras == 3:
        Path("/workspace/sim/results/CONTRIBUTION_REPORT.json").write_text(
            json.dumps(report, indent=2))

    # Markdown summary
    md = ["# Contribution / ablation report", "",
          f"Eras 1–{args.eras} · N={args.runs}/strategy/ablation · seed {args.seed}", "",
          "Negative Δ = that system was carrying clears (removing it hurts).", "",
          "## Mean clear-through Δ vs baseline", "",
          "| Ablation | " + " | ".join(f"E{e}" for e in range(1, args.eras + 1)) + " |",
          "|" + "---|" * (args.eras + 1)]
    for name, deltas in report["ablation_delta_mean_vs_baseline"].items():
        md.append("| " + name + " | " + " | ".join(
            f"{deltas.get(str(e), 0):+.3f}"
            for e in range(1, args.eras + 1)
        ) + " |")
    md += ["", "Baseline mean clear:",
           ", ".join(f"E{e}={base_mean.get(str(e))}" for e in range(1, args.eras + 1)),
           "", f"Per-strategy detail + utilization: `{out.name}`",
           "", "Interpretation guide: `BALANCE_HOTSPOTS.md` + `SIMULATION.md` § Contribution."]
    md_path = Path(f"/workspace/sim/results/CONTRIBUTION_REPORT_{tag}.md")
    md_path.write_text("\n".join(md) + "\n")
    if args.eras == 3:
        Path("/workspace/sim/results/CONTRIBUTION_REPORT.md").write_text(
            "\n".join(md) + "\n")
    print(f"Wrote {out} and {md_path}")
    print("Mean Δ:", json.dumps(report["ablation_delta_mean_vs_baseline"], indent=2))


if __name__ == "__main__":
    main()
