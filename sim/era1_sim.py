#!/usr/bin/env python3
"""Ancient-era (era 1) Monte Carlo for Ages.

Simulates Village -> Town -> Capital with greedy combat, pack shops,
Science/Civics level-ups, and strategy-biased choices.

Provisional numbers from GAME_DESIGN.md / SCIENCE_UPGRADES.md / CONTENT_CATALOG.md.
"""

from __future__ import annotations

import argparse
import itertools
import json
import random
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from typing import Any, Callable, Optional

# --- Constants / Balance v2 (tuned for eras 1–3 viability) ---------------------

CLASSES = ("M", "R", "C", "S")  # Melee, Ranged, Cavalry, Siege
SUPPORTS = ("B", "Y")  # Builder, MissionarY

# Early-weighted unit buff (~+30–40% at tier I, tapering at high tiers)
UNIT_MIGHT = {"M": [0, 7, 15, 24, 36, 55], "R": [0, 3, 5, 8, 12, 18],
              "C": [0, 11, 20, 30, 44, 65], "S": [0, 4, 8, 12, 18, 26]}
UNIT_MOM = {"M": [0, 0, 0, 0, 0, 0], "R": [0, 1, 2, 2, 3, 3],
            "C": [0, 0, 0, 0, 0, 0], "S": [0, 0, 0, 0, 0, 0]}

FORM_LEVEL_BONUS = {
    "skirmish": (3, 0), "pair": (3, 0), "triple": (3, 0),
    "battle_line": (5, 0), "combined_arms": (5, 0),
    "phalanx": (5, 1), "grand_army": (5, 1),
    "vanguard": (8, 1), "imperial_guard": (8, 1), "legion": (8, 1),
}

ERA_SOFT_CAP = {1: 2, 2: 3, 3: 3, 4: 4, 5: 4, 6: 5, 7: 5, 8: 5}
ERA_BASE_DEFENCE = {1: 500, 2: 800, 3: 1400, 4: 4500, 5: 12000, 6: 30000, 7: 75000, 8: 150000}

# Cheaper / earlier level-ups so stacks build before Medieval
SCIENCE_COSTS = [8, 12, 16, 22, 28, 36, 46, 58, 72, 88, 106, 126, 148, 172, 198]
CIVIC_COSTS = [8, 12, 16, 22, 28, 36, 46, 58, 72, 88, 106, 126, 148, 172, 198]

# Settlement rewards (was 25/8/8/5)
REWARD_GOLD = 38
REWARD_SCIENCE = 16
REWARD_CULTURE = 16
REWARD_FAITH = 12
RAZE_GOLD = 28
CITY_YIELD = 7
PACK_SIZE = 5  # was 3
WONDER_SHOP_CHANCE = 0.04  # low chance per pack offer

BLUEPRINTS = {
    "battering_ram": ("C", 10, "siege_might"),
    "scaffolding": ("C", 10, "ignore_walls_next"),
    "supply_lines": ("C", 10, "draw2"),
    "watchtower": ("C", 10, "next_might10"),
    "forge": ("U", 22, "next_unit_might_50"),
    "siege_tower": ("U", 22, "remove_walls"),
    "roads": ("U", 22, "plus_regroup"),
    "magazine": ("U", 22, "next_mom2"),
    "aqueduct": ("R", 45, "plus_assault"),
    "arsenal": ("R", 45, "next_unit_might_25"),
    "observatory": ("R", 45, "sci_mom_scale"),  # next formation Mom *= (1+0.1*sci_lv)
}
DOCTRINES = {
    "tithe": ("C", 8, "gold15"),
    "scriptorium": ("C", 8, "sci_pct"),
    "pilgrimage": ("C", 8, "faith10"),
    "alms": ("C", 8, "cul8"),
    "zeal": ("U", 18, "might15_2"),
    "relic_hunt": ("U", 18, "prophet"),
    "crusade": ("U", 18, "capital_might20"),
    "missionary_zeal": ("R", 35, "scale_gold_faith"),
    "scholastic_order": ("U", 18, "sci20_cul5"),
}
POLICIES = {
    "agoge": ("C", "melee_might4"),
    "drill_manual": ("C", "ranged_mom1"),
    "horse_breeding": ("C", "cav_might5"),
    "sappers": ("C", "siege_might6"),
    "militia_act": ("C", "skirmish_pair_might8"),
    "line_officers": ("C", "battle_line_might6"),
    "conscription": ("U", "first_scores_twice"),
    "professional_army": ("U", "ranged_deck_mom"),
    "chivalry": ("U", "cav_mom1"),
    "siegecraft": ("U", "siege_any_shape"),
    "logistics": ("U", "hand_plus1"),
    "combined_edict": ("U", "ca_ga_mom2"),
    "phalanx_law": ("U", "phalanx_might10"),
    "leveee": ("R", "vg_legion_mom3"),
    "rationalism": ("R", "sci25"),
    "total_war": ("R", "capital_might15pct"),
    # Scaling / exponential-style
    "research_corps": ("C", "might_per_sci"),    # Might *= (1 + 0.05 * sci_levels) — common scaler
    "workshop_network": ("U", "might_per_bp"),   # +6 Might per owned Blueprint
    "liturgical_fire": ("U", "mom_per_doc"),     # +1 Mom per owned Doctrine
    "academy_momentum": ("R", "mom_per_sci"),      # Mom *= (1 + 0.1 * sci_levels)
}

WONDERS = {
    "colosseum": ("plus_assault", 90),
    "great_library": ("free_sci_level", 90),
    "pyramids": ("builder_scale", 90),
    "hanging_gardens": ("hand_size", 85),
    "stonehenge": ("faith_burst", 85),
    "terracotta_army": ("cheap_units", 95),
    "big_ben": ("interest", 95),
    "forbidden_palace": ("policy_slot", 90),
}

NON_TROOP_SCI = [
    ("battle_line_drill", 1),
    ("skirmish_drill", 1),
    ("combined_arms_primer", 1),
    ("writing", 1),
    ("surveying", 1),
    ("phalanx_drill", 2),
    ("vanguard_primer", 2),
    ("natural_philosophy", 2),
    ("grand_army_drill", 3),
    ("legion_primer", 3),
    ("imperial_standards", 3),
    ("machinery", 3),
]


@dataclass
class Card:
    kind: str  # M R C S B Y
    cid: int
    # promotions / editions (simplified)
    bonus_might: int = 0
    bonus_mom: int = 0
    edition: str = "standard"  # standard, gilded, scholarly, devout, mercantile

    def combat(self) -> bool:
        return self.kind in CLASSES


@dataclass
class FightMods:
    siege_might: int = 0
    siege_mom: int = 0
    ignore_walls_next: bool = False
    walls_removed: bool = False
    next_might: int = 0
    next_unit_might_pct: float = 0.0
    next_mom: int = 0
    next_mom_mult: float = 1.0
    plus_assault: int = 0
    plus_regroup: int = 0
    blueprints_fired: set = field(default_factory=set)
    doctrines_fired: list = field(default_factory=list)


@dataclass
class RunState:
    rng: random.Random
    strategy: str
    era: int = 1
    deck: list[Card] = field(default_factory=list)
    next_cid: int = 0
    gold: int = 0
    science: int = 0
    culture: int = 0
    faith: int = 0
    sci_level: int = 0
    civ_level: int = 0
    tiers: dict = field(default_factory=lambda: {"M": 1, "R": 1, "C": 1, "S": 1, "B": 1})
    form_levels: dict = field(default_factory=lambda: defaultdict(int))
    policies: list[str] = field(default_factory=list)
    blueprints: list[str] = field(default_factory=list)
    doctrines: list[str] = field(default_factory=list)
    blueprint_slots: int = 2
    doctrine_slots: int = 1
    policy_slots: int = 2
    hand_size: int = 8
    base_assaults: int = 4
    base_regroups: int = 3
    zeal_settlements_left: int = 0  # +15% might
    capital_might_bonus: float = 0.0
    occupied: list[str] = field(default_factory=list)  # scholar/artisan/temple/trade
    writing: bool = False
    last_troop_upgrade: Optional[str] = None
    disband_cost: int = 5
    missionaries_tier: int = 1
    builder_scale: float = 1.0  # from builder tier: 1.0, 1.5, 2.0
    settlement_index: int = 0
    damage_log: list = field(default_factory=list)
    events: list = field(default_factory=list)
    era_just_began: bool = True
    wonder: Optional[str] = None
    era_wonder_available: Optional[str] = None  # forced offer once per era
    era_wonder_offered: bool = False
    cheap_units: bool = False
    interest_cap: int = 5

    def soft_cap(self) -> int:
        return ERA_SOFT_CAP.get(self.era, 5)

    def tier_of(self, kind: str) -> int:
        if kind in ("M", "R", "C", "S"):
            return self.tiers[kind]
        return 1

    def new_card(self, kind: str, **kw) -> Card:
        c = Card(kind=kind, cid=self.next_cid, **kw)
        self.next_cid += 1
        return c


def starting_deck(run: RunState) -> None:
    for kind, n in [("M", 6), ("R", 5), ("C", 3), ("S", 2), ("B", 2), ("Y", 2)]:
        for _ in range(n):
            run.deck.append(run.new_card(kind))


# --- Formations ---------------------------------------------------------------

def _counts(kinds: list[str]) -> Counter:
    return Counter(kinds)


def best_formation(combat_kinds: list[str], tiers: list[int], soft_cap: int,
                   siegecraft: bool) -> tuple[str, int, list[int]]:
    """Return (form_id, rank, scoring_indices)."""
    n = len(combat_kinds)
    if n == 0:
        return ("none", 0, [])

    # Optionally treat Siege as wild for shape only
    def shapes_from(kinds: list[str]):
        return _counts(kinds)

    candidates: list[tuple[int, str, list[int]]] = []

    # Try with siegecraft wilds: assign each S to a class to maximize rank
    wild_idx = [i for i, k in enumerate(combat_kinds) if k == "S"] if siegecraft else []
    base_kinds = list(combat_kinds)

    assignments = [base_kinds]
    if wild_idx:
        options = []
        for assigns in itertools.product(CLASSES, repeat=len(wild_idx)):
            k2 = list(base_kinds)
            for i, a in zip(wild_idx, assigns):
                k2[i] = a
            options.append(k2)
        assignments = options

    best: tuple[int, str, list[int]] = (0, "none", [])

    for kinds in assignments:
        ct = _counts(kinds)
        idxs = {cls: [i for i, k in enumerate(kinds) if k == cls] for cls in CLASSES}

        def take(cls: str, need: int) -> list[int]:
            return idxs[cls][:need]

        # Legion
        for cls, c in ct.items():
            if c >= 5:
                sc = take(cls, 5)
                best = max(best, (10, "legion", sc), key=lambda x: x[0])
        # Imperial Guard: 5 combat all >= soft_cap
        if n >= 5 and all(t >= soft_cap for t in tiers[:5]) and len(tiers) >= 5:
            # use first 5 combat cards in play order — caller passes aligned lists
            sc = list(range(min(5, n)))
            if all(tiers[i] >= soft_cap for i in sc):
                best = max(best, (9, "imperial_guard", sc), key=lambda x: x[0])
        # Vanguard
        for cls, c in ct.items():
            if c >= 4:
                sc = take(cls, 4)
                best = max(best, (8, "vanguard", sc), key=lambda x: x[0])
        # Grand Army: 1 each of 4
        if all(ct[c] >= 1 for c in CLASSES):
            sc = [take(c, 1)[0] for c in CLASSES]
            best = max(best, (7, "grand_army", sc), key=lambda x: x[0])
        # Phalanx 3+2
        threes = [c for c, v in ct.items() if v >= 3]
        twos = [c for c, v in ct.items() if v >= 2]
        for a in threes:
            for b in twos:
                if a == b and ct[a] < 5:
                    continue
                if a != b:
                    sc = take(a, 3) + take(b, 2)
                    best = max(best, (6, "phalanx", sc), key=lambda x: x[0])
        # Combined Arms: 3 different classes
        present = [c for c in CLASSES if ct[c] >= 1]
        if len(present) >= 3:
            # all combat units of those classes score
            sc = [i for i, k in enumerate(kinds) if k in present[:3] or k in present]
            # simpler: all indices whose class is among the top 3 present classes
            use = present[:3] if len(present) == 3 else present
            # if 4 classes, still Combined Arms unless Grand Army already hit
            sc = [i for i, k in enumerate(kinds) if k in present]
            best = max(best, (5, "combined_arms", sc), key=lambda x: x[0])
        # Battle Line 2+2
        pair_cls = [c for c, v in ct.items() if v >= 2]
        if len(pair_cls) >= 2:
            a, b = pair_cls[0], pair_cls[1]
            sc = take(a, 2) + take(b, 2)
            best = max(best, (4, "battle_line", sc), key=lambda x: x[0])
        # Triple / Pair / Skirmish
        for cls, c in ct.items():
            if c >= 3:
                best = max(best, (3, "triple", take(cls, 3)), key=lambda x: x[0])
            if c >= 2:
                best = max(best, (2, "pair", take(cls, 2)), key=lambda x: x[0])
            if c >= 1:
                best = max(best, (1, "skirmish", take(cls, 1)), key=lambda x: x[0])

    # Map scoring indices back through wild assignment: indices refer to combat list positions
    return best[1], best[0], sorted(set(best[2]))


FORM_BASE = {
    "none": (0, 0),
    "skirmish": (5, 1),
    "pair": (10, 2),
    "triple": (20, 3),
    "battle_line": (30, 3),
    "combined_arms": (35, 3),
    "phalanx": (45, 4),
    "grand_army": (60, 4),
    "vanguard": (60, 6),
    "imperial_guard": (70, 6),
    "legion": (80, 8),
}


def evaluate_play(run: RunState, cards: list[Card], fight: FightMods,
                  settlement: dict, consume_burst: bool) -> dict:
    combat = [(i, c) for i, c in enumerate(cards) if c.combat()]
    supports = [c for c in cards if not c.combat()]
    kinds = [c.kind for _, c in combat]
    tiers = [run.tier_of(c.kind) for _, c in combat]
    siegecraft = "siegecraft" in run.policies

    form_id, rank, scoring_local = best_formation(kinds, tiers, run.soft_cap(), siegecraft)
    scoring_cards = [combat[i][1] for i in scoring_local] if rank else []

    base_m, base_o = FORM_BASE[form_id]
    lv = run.form_levels[form_id]
    lm, lo = FORM_LEVEL_BONUS.get(form_id, (0, 0))
    base_m += lm * lv
    base_o += lo * lv

    might = float(base_m)
    mom = float(base_o)

    garrison = settlement["garrison"]
    walls = settlement["walls"] and not fight.walls_removed
    has_siege_scoring = any(c.kind == "S" for c in scoring_cards)
    # For walls: "formations containing no Siege unit" — any Siege in play or scoring?
    # Design: containing no Siege unit in the formation play — use any combat Siege played
    has_siege_played = any(c.kind == "S" for c in cards if c.combat())

    first_double = "conscription" in run.policies
    for j, c in enumerate(scoring_cards):
        um = UNIT_MIGHT[c.kind][run.tier_of(c.kind)] + c.bonus_might
        uo = UNIT_MOM[c.kind][run.tier_of(c.kind)] + c.bonus_mom
        if c.kind == "M" and "agoge" in run.policies:
            um += 4
        if c.kind == "R" and "drill_manual" in run.policies:
            uo += 1
        if c.kind == "C" and "horse_breeding" in run.policies:
            um += 5
        if c.kind == "C" and "chivalry" in run.policies:
            uo += 1
        if c.kind == "S" and "sappers" in run.policies:
            um += 6
        if c.kind == "S":
            um += int(fight.siege_might * run.builder_scale)
            uo += fight.siege_mom

        # garrisons
        if garrison == "pikemen" and c.kind == "C":
            um = 0
        if garrison == "archers" and c.kind == "M":
            um = um / 2
        if garrison == "horsemen" and c.kind == "R":
            uo = 0

        mult = 2 if (first_double and j == 0) else 1
        might += um * mult
        mom += uo * mult

    if "professional_army" in run.policies:
        n_r = sum(1 for c in run.deck if c.kind == "R")
        mom += n_r // 4
    if form_id in ("skirmish", "pair") and "militia_act" in run.policies:
        might += 8
    if form_id == "battle_line" and "line_officers" in run.policies:
        might += 6
    if form_id == "phalanx" and "phalanx_law" in run.policies:
        might += 10
    if form_id in ("combined_arms", "grand_army") and "combined_edict" in run.policies:
        mom += 2
    if form_id in ("vanguard", "legion") and "leveee" in run.policies:
        mom += 3

    # Baseline Tech Literacy — Science levels always scale Momentum slightly
    # (stacks with Academy Momentum policy). At 5 sci levels: ×1.2 Mom.
    mom *= 1.0 + 0.04 * run.sci_level

    # Scaling / exponential-style policies (stack with sci levels & owned cards)
    if "workshop_network" in run.policies:
        might += 6 * len(run.blueprints)
    if "liturgical_fire" in run.policies:
        mom += 1 * len(run.doctrines)
    if "research_corps" in run.policies:
        might *= 1.0 + 0.05 * run.sci_level
    if "academy_momentum" in run.policies:
        # Mom *= (1 + 0.1 * science levels taken) — e.g. 10 Mom @ 7 sci → 17
        mom *= 1.0 + 0.1 * run.sci_level

    # fight bursts
    might += fight.next_might
    mom += fight.next_mom
    if fight.next_unit_might_pct:
        unit_part = might - base_m
        might = base_m + unit_part * (1 + fight.next_unit_might_pct)
    mom *= fight.next_mom_mult

    if run.zeal_settlements_left > 0:
        might *= 1.15
    if settlement["kind"] == "capital":
        if "total_war" in run.policies:
            might *= 1.15
        might *= 1 + run.capital_might_bonus

    dmg = might * mom

    if walls and not has_siege_played and not fight.ignore_walls_next:
        dmg *= 0.5

    if consume_burst:
        fight.next_might = 0
        fight.next_mom = 0
        fight.next_unit_might_pct = 0.0
        fight.next_mom_mult = 1.0
        fight.ignore_walls_next = False

    return {
        "damage": max(0, int(dmg)),
        "form": form_id,
        "rank": rank,
        "might": might,
        "mom": mom,
        "supports": len(supports),
        "scoring": len(scoring_cards),
    }


def trigger_blueprint(run: RunState, name: str, fight: FightMods, hand: list[Card],
                      draw: list[Card], discard: list[Card]) -> None:
    if name in fight.blueprints_fired or name not in run.blueprints:
        return
    fight.blueprints_fired.add(name)
    effect = BLUEPRINTS[name][2]
    sc = run.builder_scale
    if effect == "siege_might":
        fight.siege_might += int(10 * sc)
    elif effect == "ignore_walls_next":
        fight.ignore_walls_next = True
    elif effect == "draw2":
        draw_cards(hand, draw, discard, 2, run.rng)
    elif effect == "next_might10":
        fight.next_might += int(10 * sc)
    elif effect == "next_unit_might_50":
        fight.next_unit_might_pct = max(fight.next_unit_might_pct, 0.5)
    elif effect == "remove_walls":
        fight.walls_removed = True
    elif effect == "plus_regroup":
        fight.plus_regroup += 1
    elif effect == "next_mom2":
        fight.next_mom += int(2 * sc) if sc >= 1 else 2
        fight.next_mom += 2
    elif effect == "plus_assault":
        fight.plus_assault += 1
    elif effect == "next_unit_might_25":
        fight.next_unit_might_pct = max(fight.next_unit_might_pct, 0.25)
    elif effect == "sci_mom_scale":
        fight.next_mom_mult = max(fight.next_mom_mult, 1.0 + 0.1 * run.sci_level)


def trigger_doctrine(run: RunState, name: str, fight: FightMods) -> None:
    if name in fight.doctrines_fired or name not in run.doctrines:
        return
    fight.doctrines_fired.append(name)


def apply_doctrine_rewards(run: RunState, fight: FightMods, total_damage: int,
                           settlement: dict, occupied_choice: str) -> None:
    for name in fight.doctrines_fired:
        effect = DOCTRINES[name][2]
        if effect == "gold15":
            run.gold += 15
        elif effect == "sci_pct":
            run.science += min(40, int(total_damage * 0.08))
        elif effect == "faith10":
            run.faith += 10
            if occupied_choice == "temple":
                pass  # yield handled in occupy
        elif effect == "cul8":
            run.culture += 8
        elif effect == "might15_2":
            run.zeal_settlements_left = max(run.zeal_settlements_left, 2)
        elif effect == "prophet":
            # Sow Dissent free next fight approx: store as capital bonus or gold
            run.gold += 8  # stub prophet value
        elif effect == "capital_might20":
            run.capital_might_bonus = max(run.capital_might_bonus, 0.20)
        elif effect == "scale_gold_faith":
            run.gold += 10
            run.faith += 5
        elif effect == "sci20_cul5":
            run.science += 20
            run.culture += 5


# --- Deck helpers -------------------------------------------------------------

def shuffle_draw(draw: list[Card], discard: list[Card], rng: random.Random) -> None:
    if not draw:
        draw.extend(discard)
        discard.clear()
        rng.shuffle(draw)


def draw_cards(hand: list[Card], draw: list[Card], discard: list[Card],
               n: int, rng: random.Random) -> None:
    for _ in range(n):
        shuffle_draw(draw, discard, rng)
        if not draw:
            return
        hand.append(draw.pop())


def refill_hand(hand: list[Card], draw: list[Card], discard: list[Card],
                hand_size: int, rng: random.Random) -> None:
    while len(hand) < hand_size:
        shuffle_draw(draw, discard, rng)
        if not draw:
            break
        hand.append(draw.pop())


# --- Combat AI ----------------------------------------------------------------

def greedy_assault(run: RunState, hand: list[Card], fight: FightMods,
                   settlement: dict) -> tuple[list[Card], dict]:
    """Enumerate subsets size 1..5 preferring damage; also try using supports for BP/Doc."""
    best_dmg = -1
    best_play: list[Card] = []
    best_eval: dict = {"damage": 0, "form": "none"}

    # Limit enumeration: if hand large, sample + prioritize combat-heavy
    idxs = list(range(len(hand)))
    candidates = []
    for k in range(1, min(5, len(hand)) + 1):
        if len(hand) <= 8:
            candidates.extend(itertools.combinations(idxs, k))
        else:
            # shouldn't happen
            candidates.extend(itertools.combinations(idxs, k))

    # Cap combinations if somehow huge
    if len(candidates) > 2000:
        candidates = random.sample(candidates, 2000) if False else candidates[:2000]

    for comb in candidates:
        play = [hand[i] for i in comb]
        # Simulate blueprint triggers without mutating much — dry eval first
        # Actually apply supports: prefer firing unused BP/Doc if present
        # Dry-run fight copy
        fe = FightMods(
            siege_might=fight.siege_might, siege_mom=fight.siege_mom,
            ignore_walls_next=fight.ignore_walls_next, walls_removed=fight.walls_removed,
            next_might=fight.next_might, next_unit_might_pct=fight.next_unit_might_pct,
            next_mom=fight.next_mom, next_mom_mult=fight.next_mom_mult,
            blueprints_fired=set(fight.blueprints_fired),
            doctrines_fired=list(fight.doctrines_fired),
        )
        # Trigger one BP/Doc per support in play (order: builders then missionaries)
        bps = [b for b in run.blueprints if b not in fe.blueprints_fired]
        docs = [d for d in run.doctrines if d not in fe.doctrines_fired]
        for c in play:
            if c.kind == "B" and bps:
                # pick best blueprint heuristically
                pick = pick_blueprint(run, bps, settlement, fe)
                # apply numeric to fe only for eval
                apply_bp_to_fight(pick, fe, run.builder_scale, run.sci_level)
                fe.blueprints_fired.add(pick)
                bps = [b for b in bps if b != pick]
            if c.kind == "Y" and docs:
                pick = pick_doctrine(run, docs)
                fe.doctrines_fired.append(pick)
                docs = [d for d in docs if d != pick]

        ev = evaluate_play(run, play, fe, settlement, consume_burst=False)
        # Small bias: prefer higher rank / using siege on walls
        score = ev["damage"]
        if settlement["walls"] and not fe.walls_removed and any(c.kind == "S" for c in play):
            score += 1
        if score > best_dmg:
            best_dmg = score
            best_play = play
            best_eval = ev

    if not best_play and hand:
        best_play = [hand[0]]
        best_eval = evaluate_play(run, best_play, fight, settlement, False)

    return best_play, best_eval


def pick_blueprint(run: RunState, available: list[str], settlement: dict,
                   fe: FightMods) -> str:
    strat = run.strategy
    pri = []
    if settlement["walls"] and not fe.walls_removed:
        pri += ["siege_tower", "scaffolding", "battering_ram"]
    if strat == "S4":
        pri += ["aqueduct", "forge", "arsenal", "magazine", "watchtower"]
    if strat == "S1":
        pri += ["siege_tower", "battering_ram", "scaffolding", "forge"]
    pri += ["forge", "magazine", "aqueduct", "watchtower", "supply_lines", "roads"]
    for p in pri:
        if p in available:
            return p
    return available[0]


def pick_doctrine(run: RunState, available: list[str]) -> str:
    strat = run.strategy
    pri = []
    if strat == "S5":
        pri += ["missionary_zeal", "zeal", "tithe", "pilgrimage", "relic_hunt"]
    if strat == "S6":
        pri += ["scriptorium", "alms", "tithe"]
    pri += ["zeal", "tithe", "scriptorium", "crusade", "alms", "pilgrimage", "missionary_zeal"]
    for p in pri:
        if p in available:
            return p
    return available[0]


def apply_bp_to_fight(name: str, fe: FightMods, scale: float, sci_level: int = 0) -> None:
    effect = BLUEPRINTS[name][2]
    if effect == "siege_might":
        fe.siege_might += int(10 * scale)
    elif effect == "ignore_walls_next":
        fe.ignore_walls_next = True
    elif effect == "next_might10":
        fe.next_might += int(10 * scale)
    elif effect == "next_unit_might_50":
        fe.next_unit_might_pct = max(fe.next_unit_might_pct, 0.5)
    elif effect == "remove_walls":
        fe.walls_removed = True
    elif effect == "plus_regroup":
        fe.plus_regroup += 1
    elif effect == "next_mom2":
        fe.next_mom += 2
    elif effect == "plus_assault":
        fe.plus_assault += 1
    elif effect == "next_unit_might_25":
        fe.next_unit_might_pct = max(fe.next_unit_might_pct, 0.25)
    elif effect == "sci_mom_scale":
        fe.next_mom_mult = max(fe.next_mom_mult, 1.0 + 0.1 * sci_level)


def should_regroup(run: RunState, hand: list[Card], fight: FightMods,
                   settlement: dict, regroups_left: int, assaults_left: int) -> bool:
    if regroups_left <= 0:
        return False
    play, ev = greedy_assault(run, hand, fight, settlement)
    # Regroup if damage is weak relative to remaining need — caller passes defence left via settlement
    defence_left = settlement["defence_left"]
    if assaults_left <= 0:
        return False
    needed = defence_left / max(1, assaults_left)
    if ev["damage"] < needed * 0.45 and ev["rank"] <= 2:
        return True
    if ev["rank"] <= 1 and regroups_left > 0 and assaults_left >= 2:
        return True
    return False


def regroup_discard(hand: list[Card], run: RunState) -> list[Card]:
    """Discard up to 5 least useful cards."""
    # Prefer discarding supports if no BP/Doc left unused later — simple: discard duplicates of low value
    scored = []
    for c in hand:
        v = 0
        if c.kind == "M":
            v = 3
        elif c.kind == "R":
            v = 3
        elif c.kind == "C":
            v = 4
        elif c.kind == "S":
            v = 3
        elif c.kind == "B":
            v = 1 if run.blueprints else 0
        else:
            v = 1 if run.doctrines else 0
        if run.strategy == "S2" and c.kind in ("B", "Y"):
            v = -1
        scored.append((v, c))
    scored.sort(key=lambda x: x[0])
    n = min(5, max(1, len(hand) // 2))
    return [c for _, c in scored[:n]]


def fight_settlement(run: RunState, settlement: dict) -> tuple[bool, int, int]:
    """Returns (won, damage, assaults_used)."""
    rng = run.rng
    draw = list(run.deck)
    rng.shuffle(draw)
    discard: list[Card] = []
    hand: list[Card] = []
    refill_hand(hand, draw, discard, run.hand_size, rng)

    fight = FightMods()
    assaults = run.base_assaults
    regroups = run.base_regroups
    defence = settlement["defence"]
    settlement = dict(settlement)
    settlement["defence_left"] = defence
    total_damage = 0
    assaults_used = 0

    while defence > 0 and assaults > 0:
        settlement["defence_left"] = defence
        # optionally regroup
        if should_regroup(run, hand, fight, settlement, regroups, assaults):
            dump = regroup_discard(hand, run)
            for c in dump:
                hand.remove(c)
                discard.append(c)
            refill_hand(hand, draw, discard, run.hand_size, rng)
            regroups -= 1
            if fight.plus_regroup:
                # already consumed as extra stock at start — handle below
                pass
            continue

        play, _ = greedy_assault(run, hand, fight, settlement)
        # Apply supports for real
        for c in play:
            if c.kind == "B":
                avail = [b for b in run.blueprints if b not in fight.blueprints_fired]
                if avail:
                    bp = pick_blueprint(run, avail, settlement, fight)
                    trigger_blueprint(run, bp, fight, hand, draw, discard)
            if c.kind == "Y":
                avail = [d for d in run.doctrines if d not in fight.doctrines_fired]
                if avail:
                    trigger_doctrine(run, pick_doctrine(run, avail), fight)

        # Extra assaults/regroups from BP
        if fight.plus_assault:
            assaults += fight.plus_assault
            fight.plus_assault = 0
        if fight.plus_regroup:
            regroups += fight.plus_regroup
            fight.plus_regroup = 0

        ev = evaluate_play(run, play, fight, settlement, consume_burst=True)
        dmg = ev["damage"]
        defence -= dmg
        total_damage += dmg
        assaults_used += 1
        assaults -= 1
        for c in play:
            hand.remove(c)
            discard.append(c)
        refill_hand(hand, draw, discard, run.hand_size, rng)

        run.events.append({
            "settlement": settlement["kind"], "form": ev["form"],
            "dmg": dmg, "left": max(0, defence),
        })

    won = defence <= 0
    if run.zeal_settlements_left > 0 and won:
        run.zeal_settlements_left -= 1
    return won, total_damage, assaults_used


# --- Rewards / occupy / shop / level-ups --------------------------------------

def interest(run: RunState) -> None:
    run.gold += min(run.interest_cap, run.gold // 5)


def city_yields(run: RunState) -> None:
    for t in run.occupied:
        if t == "scholar":
            run.science += CITY_YIELD
        elif t == "artisan":
            run.culture += CITY_YIELD
        elif t == "temple":
            run.faith += CITY_YIELD
        elif t == "trade":
            run.gold += CITY_YIELD


def snapshot_run(run: RunState) -> dict:
    editions = Counter(c.edition for c in run.deck if c.edition != "standard")
    special_units = sum(1 for c in run.deck if c.edition != "standard")
    promoted = sum(1 for c in run.deck if c.bonus_might > 0 or c.bonus_mom > 0)
    class_counts = Counter(c.kind for c in run.deck)
    return {
        "gold": run.gold,
        "science_bank": run.science,
        "culture_bank": run.culture,
        "faith": run.faith,
        "sci_levels_taken": run.sci_level,
        "civ_levels_taken": run.civ_level,
        "tiers": dict(run.tiers),
        "tier_sum": sum(run.tiers[k] for k in ("M", "R", "C", "S", "B")),
        "form_levels": dict(run.form_levels),
        "form_level_sum": sum(run.form_levels.values()),
        "policies": list(run.policies),
        "policy_count": len(run.policies),
        "blueprints": list(run.blueprints),
        "blueprint_count": len(run.blueprints),
        "doctrines": list(run.doctrines),
        "doctrine_count": len(run.doctrines),
        "blueprint_slots": run.blueprint_slots,
        "doctrine_slots": run.doctrine_slots,
        "policy_slots": run.policy_slots,
        "hand_size": run.hand_size,
        "base_assaults": run.base_assaults,
        "base_regroups": run.base_regroups,
        "builder_scale": run.builder_scale,
        "deck_size": len(run.deck),
        "class_counts": dict(class_counts),
        "special_unit_count": special_units,
        "editions": dict(editions),
        "promoted_card_count": promoted,
        "occupied": list(run.occupied),
        "occupy_count": len(run.occupied),
        "zeal_left": run.zeal_settlements_left,
        "writing": run.writing,
    }


def after_victory(run: RunState, settlement: dict, total_damage: int,
                  assaults_used: int, fight_docs: FightMods) -> dict:
    before = snapshot_run(run)
    sci_before = run.sci_level
    civ_before = run.civ_level
    tiers_before = dict(run.tiers)
    policies_before = set(run.policies)
    bp_before = set(run.blueprints)
    doc_before = set(run.doctrines)
    deck_before = len(run.deck)
    special_before = sum(1 for c in run.deck if c.edition != "standard")
    promoted_before = sum(1 for c in run.deck if c.bonus_might > 0 or c.bonus_mom > 0)
    gold_before = run.gold
    faith_before = run.faith

    unused = max(0, run.base_assaults - assaults_used)
    base_gold = REWARD_GOLD + unused
    run.gold += base_gold
    run.science += REWARD_SCIENCE
    run.culture += REWARD_CULTURE
    run.faith += REWARD_FAITH
    if "rationalism" in run.policies:
        run.science += max(4, int(REWARD_SCIENCE * 0.25))

    choice = choose_occupy(run, settlement)
    if choice == "raze":
        run.gold += RAZE_GOLD
        occupied_type = ""
    else:
        occupied_type = settlement["city_type"]
        run.occupied.append(occupied_type)

    apply_doctrine_rewards(run, fight_docs, total_damage, settlement, occupied_type)

    interest(run)
    city_yields(run)
    level_ups = process_level_ups(run)
    shop(run, settlement)

    after = snapshot_run(run)
    troop_ups = {
        k: after["tiers"][k] - tiers_before[k]
        for k in tiers_before
        if after["tiers"][k] != tiers_before[k]
    }
    return {
        "occupy_or_raze": choice,
        "occupied_type": occupied_type or None,
        "science_level_ups_this_fight": after["sci_levels_taken"] - sci_before,
        "civic_level_ups_this_fight": after["civ_levels_taken"] - civ_before,
        "science_picks": [x["pick"] for x in level_ups["science"]],
        "civic_picks": [x["pick"] for x in level_ups["civics"]],
        "science_offers": level_ups["science"],
        "civic_offers": level_ups["civics"],
        "troop_upgrades_this_fight": troop_ups,
        "new_policies": [p for p in after["policies"] if p not in policies_before],
        "new_blueprints": [b for b in after["blueprints"] if b not in bp_before],
        "new_doctrines": [d for d in after["doctrines"] if d not in doc_before],
        "units_bought": max(0, after["deck_size"] - deck_before),
        "special_units_gained": max(0, after["special_unit_count"] - special_before),
        "promotions_gained": max(0, after["promoted_card_count"] - promoted_before),
        "gold_delta": after["gold"] - gold_before,
        "faith_delta": after["faith"] - faith_before,
        "snapshot": after,
    }


def choose_occupy(run: RunState, settlement: dict) -> str:
    t = settlement["city_type"]
    if run.strategy == "S6" and t == "scholar":
        return "occupy"
    if run.strategy == "S5" and t == "temple":
        return "occupy"
    if run.strategy == "S4" and t == "trade":
        return "occupy"
    if run.gold < 15:
        return "raze"
    # Prefer occupy for long-term unless broke
    if t in ("scholar", "temple", "artisan", "trade"):
        return "occupy"
    return "raze"


def process_level_ups(run: RunState) -> dict:
    sci_picks = []
    civ_picks = []
    while run.sci_level < len(SCIENCE_COSTS) and run.science >= SCIENCE_COSTS[run.sci_level]:
        run.science -= SCIENCE_COSTS[run.sci_level]
        offers = roll_science_offers(run)
        pick = choose_science(run, offers)
        apply_science(run, pick)
        run.sci_level += 1
        sci_picks.append({"pick": pick, "offers": offers})
        run.events.append({"science_pick": pick, "offers": offers})
    while run.civ_level < len(CIVIC_COSTS) and run.culture >= CIVIC_COSTS[run.civ_level]:
        run.culture -= CIVIC_COSTS[run.civ_level]
        offers = roll_civic_offers(run)
        pick = choose_civic(run, offers)
        apply_civic(run, pick)
        run.civ_level += 1
        civ_picks.append({"pick": pick, "offers": offers})
        run.events.append({"civic_pick": pick, "offers": offers})
    return {"science": sci_picks, "civics": civ_picks}


def roll_science_offers(run: RunState) -> list[str]:
    rng = run.rng
    t_count = 1 if rng.random() < 0.60 else 2
    troops = weighted_troop_offers(run, t_count)
    non = []
    pool = [n for n, e in NON_TROOP_SCI if e <= run.era or rng.random() < 0.08]
    rng.shuffle(pool)
    while len(troops) + len(non) < 3 and pool:
        non.append(pool.pop())
    # pad
    while len(troops) + len(non) < 3:
        non.append("battle_line_drill")
    return (troops + non)[:3]


def weighted_troop_offers(run: RunState, n: int) -> list[str]:
    rng = run.rng
    soft = run.soft_cap()
    weights = []
    for cls, key in [("M", "M"), ("R", "R"), ("C", "C"), ("S", "S"), ("B", "B")]:
        cur = run.tiers[key]
        if key == "B" and cur >= 3:
            continue
        if cur >= 5:
            continue
        soft_use = soft if key != "B" else (2 if run.era < 3 else 3)
        gap = soft_use - cur
        if gap >= 1:
            w = 14.0 if run.era_just_began else 10.0
        elif gap == 0 and cur + 1 <= min(5, soft_use + 1):
            w = 1.0  # ahead of era
        else:
            continue
        if run.last_troop_upgrade == key and not run.era_just_began:
            w *= 0.35
        weights.append((key, w))
    picks = []
    for _ in range(n):
        if not weights:
            break
        total = sum(w for _, w in weights)
        r = rng.random() * total
        acc = 0.0
        chosen = weights[0][0]
        for k, w in weights:
            acc += w
            if r <= acc:
                chosen = k
                break
        picks.append(f"upgrade_{chosen}")
        weights = [(k, w) for k, w in weights if k != chosen]
    return picks


def choose_science(run: RunState, offers: list[str]) -> str:
    strat = run.strategy
    pref = []
    if strat == "S3":
        pref = ["upgrade_M", "upgrade_R", "battle_line_drill", "upgrade_C"]
    elif strat == "S1":
        pref = ["upgrade_S", "upgrade_M", "upgrade_B", "combined_arms_primer"]
    elif strat == "S2":
        pref = ["upgrade_M", "upgrade_C", "skirmish_drill", "upgrade_R"]
    elif strat == "S4":
        pref = ["upgrade_B", "upgrade_M", "writing", "battle_line_drill"]
    elif strat == "S5":
        pref = ["upgrade_M", "upgrade_R", "surveying", "upgrade_C"]
    elif strat == "S6":
        pref = ["upgrade_M", "upgrade_R", "upgrade_C", "upgrade_S", "writing"]
    else:
        pref = ["upgrade_M", "upgrade_R", "upgrade_C", "upgrade_S", "battle_line_drill"]
    for p in pref:
        if p in offers:
            return p
    return offers[0]


def apply_science(run: RunState, pick: str) -> None:
    if pick.startswith("upgrade_"):
        key = pick.split("_")[1]
        run.tiers[key] = min(5 if key != "B" else 3, run.tiers[key] + 1)
        run.last_troop_upgrade = key
        if key == "B":
            run.builder_scale = {1: 1.0, 2: 1.5, 3: 2.0}[run.tiers["B"]]
        run.era_just_began = False
        return
    if pick == "battle_line_drill":
        run.form_levels["battle_line"] += 1
    elif pick == "skirmish_drill":
        run.form_levels["skirmish"] += 1
        run.form_levels["pair"] += 1
    elif pick == "combined_arms_primer":
        run.form_levels["combined_arms"] += 1
    elif pick == "phalanx_drill":
        run.form_levels["phalanx"] += 1
    elif pick == "vanguard_primer":
        run.form_levels["vanguard"] += 1
    elif pick == "grand_army_drill":
        run.form_levels["grand_army"] += 1
    elif pick == "legion_primer":
        run.form_levels["legion"] += 1
    elif pick == "imperial_standards":
        run.form_levels["imperial_guard"] += 1
    elif pick == "natural_philosophy":
        if "rationalism" not in run.policies and len(run.policies) < run.policy_slots:
            run.policies.append("rationalism")
        else:
            run.science += 8
    elif pick == "machinery":
        run.writing = True
    elif pick == "writing":
        run.writing = True
    elif pick == "surveying":
        run.base_regroups += 1
    run.era_just_began = False


def roll_civic_offers(run: RunState) -> list[str]:
    pool = ["policy_slot", "draft_policy", "builder_slot", "missionary_slot",
            "plus_regroup", "plus_hand"]
    run.rng.shuffle(pool)
    return pool[:3]


def choose_civic(run: RunState, offers: list[str]) -> str:
    strat = run.strategy
    pref = {
        "S4": ["builder_slot", "draft_policy", "plus_hand"],
        "S5": ["missionary_slot", "draft_policy", "policy_slot"],
        "S3": ["draft_policy", "policy_slot", "plus_hand"],
        "S2": ["draft_policy", "plus_regroup", "policy_slot"],
        "S6": ["draft_policy", "policy_slot", "plus_hand"],
        "S1": ["draft_policy", "builder_slot", "plus_regroup"],
    }.get(strat, ["draft_policy", "policy_slot", "plus_hand"])
    for p in pref:
        if p in offers:
            if p == "policy_slot" and run.policy_slots >= 5:
                continue
            if p == "builder_slot" and run.blueprint_slots >= 5:
                continue
            if p == "missionary_slot" and run.doctrine_slots >= 4:
                continue
            return p
    return offers[0]


def apply_civic(run: RunState, pick: str) -> None:
    if pick == "policy_slot":
        run.policy_slots = min(5, run.policy_slots + 1)
    elif pick == "builder_slot":
        run.blueprint_slots = min(5, run.blueprint_slots + 1)
    elif pick == "missionary_slot":
        run.doctrine_slots = min(4, run.doctrine_slots + 1)
    elif pick == "plus_regroup":
        run.base_regroups += 1
    elif pick == "plus_hand":
        run.hand_size += 1
    elif pick == "draft_policy":
        draft_policy(run)


def draft_policy(run: RunState) -> None:
    if len(run.policies) >= run.policy_slots:
        return
    pool = [p for p in POLICIES if p not in run.policies]
    if not pool:
        return
    run.rng.shuffle(pool)
    offers = pool[:3]
    pick = choose_policy(run, offers)
    run.policies.append(pick)


def choose_policy(run: RunState, offers: list[str]) -> str:
    strat = run.strategy
    pref = {
        "S3": ["academy_momentum", "research_corps", "agoge", "drill_manual", "line_officers",
               "conscription", "professional_army", "workshop_network", "logistics"],
        "S1": ["academy_momentum", "sappers", "siegecraft", "workshop_network", "agoge", "conscription"],
        "S2": ["academy_momentum", "conscription", "leveee", "horse_breeding", "chivalry", "research_corps"],
        "S4": ["academy_momentum", "workshop_network", "logistics", "research_corps", "agoge"],
        "S5": ["academy_momentum", "liturgical_fire", "logistics", "agoge", "rationalism"],
        "S6": ["academy_momentum", "research_corps", "rationalism", "logistics", "agoge", "drill_manual"],
    }.get(strat, ["academy_momentum", "research_corps", "agoge", "logistics", "conscription"])
    for p in pref:
        if p in offers:
            return p
    return offers[0]


def shop(run: RunState, settlement: dict) -> None:
    rng = run.rng
    # Once per era: guarantee a Wonder purchase option
    if not run.era_wonder_offered and run.wonder is None:
        run.era_wonder_available = rng.choice(list(WONDERS.keys()))
        run.era_wonder_offered = True

    treasury = [roll_treasury_offer(run) for _ in range(PACK_SIZE)]
    synod = [roll_synod_offer(run) for _ in range(PACK_SIZE)]

    # Append forced era wonder as an extra buyable row item
    if run.era_wonder_available and run.wonder is None:
        w = run.era_wonder_available
        treasury.append(("wonder", w, WONDERS[w][1]))

    if run.strategy in ("S4", "S1") and run.gold >= 3:
        if not any(o[0] == "blueprint" for o in treasury):
            run.gold -= 3
            treasury = [roll_treasury_offer(run) for _ in range(PACK_SIZE)]
            if run.era_wonder_available and run.wonder is None:
                w = run.era_wonder_available
                treasury.append(("wonder", w, WONDERS[w][1]))
    if run.strategy == "S5" and run.faith >= 3:
        if not any(o[0] == "doctrine" for o in synod):
            run.faith -= 3
            synod = [roll_synod_offer(run) for _ in range(PACK_SIZE)]

    buy_treasury(run, treasury)
    buy_synod(run, synod)

    if run.strategy == "S2":
        disband_supports(run)


def roll_treasury_offer(run: RunState) -> tuple:
    rng = run.rng
    if run.wonder is None and rng.random() < WONDER_SHOP_CHANCE:
        name = rng.choice(list(WONDERS.keys()))
        return ("wonder", name, WONDERS[name][1])
    r = rng.random()
    if r < 0.38:
        kind = rng.choice(["M", "R", "C", "S"])
        cost = {1: 8, 2: 12, 3: 18}.get(run.tiers[kind], 12)
        if run.cheap_units:
            cost = max(4, cost // 2)
        edition = "standard"
        er = rng.random()
        if er < 0.15:
            edition = rng.choice(["gilded", "scholarly", "devout", "mercantile"])
            cost = int(cost * 1.5)
        return ("unit", kind, cost, edition)
    if r < 0.72:
        rarities = [b for b, v in BLUEPRINTS.items() if v[0] == "C"] * 3 + \
                   [b for b, v in BLUEPRINTS.items() if v[0] == "U"] * 2 + \
                   [b for b, v in BLUEPRINTS.items() if v[0] == "R"]
        name = rng.choice(rarities)
        return ("blueprint", name, BLUEPRINTS[name][1])
    if r < 0.92:
        return ("promotion", "master_drill", 10)
    kind = rng.choice(["M", "R", "C", "S"])
    cost = 8
    if run.cheap_units:
        cost = 4
    return ("unit", kind, cost, "standard")


def roll_synod_offer(run: RunState) -> tuple:
    rng = run.rng
    if rng.random() < 0.55:
        rarities = [d for d, v in DOCTRINES.items() if v[0] == "C"] * 3 + \
                   [d for d, v in DOCTRINES.items() if v[0] == "U"] * 2 + \
                   [d for d, v in DOCTRINES.items() if v[0] == "R"]
        name = rng.choice(rarities)
        return ("doctrine", name, DOCTRINES[name][1])
    return ("prophet", "sow_dissent", 15)


def buy_treasury(run: RunState, offers: list) -> None:
    scored = []
    for o in offers:
        scored.append((treasury_score(run, o), o))
    scored.sort(key=lambda x: -x[0])
    for score, o in scored:
        if score <= 0:
            continue
        if o[0] == "unit":
            _, kind, cost, edition = o
            if run.gold >= cost and want_unit(run, kind):
                run.gold -= cost
                kw = {}
                if edition == "gilded":
                    kw["bonus_might"] = 2
                c = run.new_card(kind, edition=edition, **kw)
                if edition != "standard":
                    c.edition = edition
                run.deck.append(c)
        elif o[0] == "blueprint":
            _, name, cost = o
            if run.gold >= cost and name not in run.blueprints and len(run.blueprints) < run.blueprint_slots:
                if want_blueprint(run, name):
                    run.gold -= cost
                    run.blueprints.append(name)
        elif o[0] == "promotion":
            _, name, cost = o
            if run.gold >= cost:
                targets = [c for c in run.deck if c.combat()]
                if targets and want_promotion(run):
                    run.gold -= cost
                    pref = preferred_class(run)
                    targets.sort(key=lambda c: (0 if c.kind == pref else 1))
                    targets[0].bonus_might += 2
        elif o[0] == "wonder":
            _, name, cost = o
            if run.wonder is None and run.gold >= cost and want_wonder(run, name):
                run.gold -= cost
                apply_wonder(run, name)
                run.era_wonder_available = None


def buy_synod(run: RunState, offers: list) -> None:
    for o in offers:
        if o[0] == "doctrine":
            _, name, cost = o
            if run.faith >= cost and name not in run.doctrines and len(run.doctrines) < run.doctrine_slots:
                if want_doctrine(run, name):
                    run.faith -= cost
                    run.doctrines.append(name)
        elif o[0] == "prophet" and run.faith >= o[2]:
            if run.strategy in ("S5", "S1"):
                run.faith -= o[2]
                # Sow Dissent stub: +gold or mark
                run.gold += 5


def treasury_score(run: RunState, o: tuple) -> float:
    if o[0] == "wonder":
        return 8 if want_wonder(run, o[1]) else 0
    if o[0] == "blueprint":
        return 5 if want_blueprint(run, o[1]) else 0
    if o[0] == "unit":
        return 3 if want_unit(run, o[1]) else 0.5
    if o[0] == "promotion":
        return 2 if want_promotion(run) else 0
    return 0


def want_wonder(run: RunState, name: str) -> bool:
    if run.wonder is not None:
        return False
    # Buy if affordable with a small gold buffer for next fight
    cost = WONDERS[name][1]
    return run.gold >= cost + 10


def apply_wonder(run: RunState, name: str) -> None:
    run.wonder = name
    effect = WONDERS[name][0]
    if effect == "plus_assault":
        run.base_assaults += 1
    elif effect == "free_sci_level":
        # immediate free science level-up pick
        offers = roll_science_offers(run)
        pick = choose_science(run, offers)
        apply_science(run, pick)
        run.sci_level += 1
    elif effect == "builder_scale":
        run.blueprint_slots = min(5, run.blueprint_slots + 1)
        run.builder_scale = max(run.builder_scale, 1.5)
    elif effect == "hand_size":
        run.hand_size += 1
    elif effect == "faith_burst":
        run.faith += 25
    elif effect == "cheap_units":
        run.cheap_units = True
    elif effect == "interest":
        run.interest_cap = max(run.interest_cap, 10)
    elif effect == "policy_slot":
        run.policy_slots = min(5, run.policy_slots + 1)


def want_unit(run: RunState, kind: str) -> bool:
    n = len(run.deck)
    if n >= 28:
        return False
    strat = run.strategy
    if strat == "S2":
        return kind == preferred_class(run)
    if strat == "S1":
        return kind in ("S", "M")
    if strat == "S3":
        return kind in ("M", "R")
    if strat == "S4":
        return kind in ("M", "R", "B") if False else kind in ("M", "R")
    return kind in ("M", "R", "C")


def want_blueprint(run: RunState, name: str) -> bool:
    if name in run.blueprints or len(run.blueprints) >= run.blueprint_slots:
        return False
    strat = run.strategy
    if strat == "S1":
        return name in ("battering_ram", "siege_tower", "scaffolding", "forge", "aqueduct", "observatory")
    if strat == "S4":
        return True
    if strat == "S3":
        return name in ("forge", "magazine", "watchtower", "aqueduct", "supply_lines", "roads", "observatory", "arsenal")
    if strat == "S6":
        return name in ("observatory", "forge", "aqueduct", "watchtower", "supply_lines")
    return name in ("forge", "watchtower", "supply_lines", "aqueduct", "siege_tower", "observatory")


def want_doctrine(run: RunState, name: str) -> bool:
    if name in run.doctrines or len(run.doctrines) >= run.doctrine_slots:
        return False
    if run.strategy == "S5":
        return True
    if run.strategy == "S6":
        return name in ("scriptorium", "alms", "tithe", "zeal")
    return name in ("tithe", "zeal", "scriptorium", "crusade")


def want_promotion(run: RunState) -> bool:
    return run.strategy in ("S2", "S3", "S6")


def preferred_class(run: RunState) -> str:
    return {"S2": "M", "S1": "S", "S3": "M", "S4": "M", "S5": "M", "S6": "M"}.get(run.strategy, "M")


def disband_supports(run: RunState) -> None:
    # Remove up to 2 supports if gold allows
    supports = [c for c in run.deck if c.kind in ("B", "Y")]
    for c in supports[:2]:
        if run.gold >= run.disband_cost:
            run.gold -= run.disband_cost
            run.deck.remove(c)
            run.disband_cost += 1


# --- Settlement generation ----------------------------------------------------

def make_settlement(kind: str, rng: random.Random, era: int = 1) -> dict:
    base = ERA_BASE_DEFENCE.get(era, 500)
    mult = {"village": 1.0, "town": 1.5, "capital": 2.5}[kind]
    defence = int(base * mult)
    if kind == "village":
        walls = False
        garrison = "militia"
    elif kind == "town":
        walls = rng.random() < 0.50
        garrison = rng.choice(["pikemen", "archers", "horsemen", "militia"])
    else:
        walls = rng.random() < 0.80
        garrison = rng.choice(["pikemen", "archers", "horsemen"])
    city_type = rng.choice(["scholar", "artisan", "temple", "trade"])
    return {
        "kind": kind,
        "era": era,
        "defence": defence,
        "walls": walls,
        "garrison": garrison,
        "city_type": city_type,
    }


# --- Run ----------------------------------------------------------------------

def play_eras(seed: int, strategy: str, max_era: int = 1) -> dict:
    rng = random.Random(seed)
    run = RunState(rng=rng, strategy=strategy, era=1)
    starting_deck(run)

    results = {
        "strategy": strategy, "seed": seed, "max_era": max_era,
        "won_through": 0, "failed_at": None, "failed_era": None,
        "settlements": [], "tiers_end": None, "policies": None,
        "blueprints": None, "doctrines": None, "gold_end": 0,
        "damage_by_era_capital": {},
    }

    for era in range(1, max_era + 1):
        run.era = era
        run.era_just_began = True
        run.era_wonder_offered = False
        run.era_wonder_available = None
        for kind in ("village", "town", "capital"):
            run.settlement_index += 1
            st = make_settlement(kind, rng, era)
            won, dmg, used = fight_settlement_with_docs(run, st)
            results["settlements"].append({
                "era": era, "kind": kind, "won": won, "damage": dmg,
                "defence": st["defence"], "walls": st["walls"],
                "garrison": st["garrison"], "assaults_used": used,
                "tiers": dict(run.tiers), "gold": run.gold,
                "overkill": max(0, dmg - st["defence"]) if won else None,
                "shortfall": max(0, st["defence"] - dmg) if not won else None,
            })
            if kind == "capital" and won:
                results["damage_by_era_capital"][era] = dmg
            if not won:
                results["failed_at"] = kind
                results["failed_era"] = era
                results["tiers_end"] = dict(run.tiers)
                results["policies"] = list(run.policies)
                results["blueprints"] = list(run.blueprints)
                results["doctrines"] = list(run.doctrines)
                results["gold_end"] = run.gold
                results["deck_size"] = len(run.deck)
                results["trajectory"] = results.get("trajectory", [])
                return results
            post = after_victory(run, st, dmg, used, run._last_fight)  # type: ignore
            results.setdefault("trajectory", []).append({
                "fight_index": run.settlement_index,
                "era": era,
                "kind": kind,
                "defence": st["defence"],
                "damage": dmg,
                "assaults_used": used,
                "won": True,
                **{k: post[k] for k in post if k != "snapshot"},
                "after": post["snapshot"],
            })
        results["won_through"] = era

    results["tiers_end"] = dict(run.tiers)
    results["policies"] = list(run.policies)
    results["blueprints"] = list(run.blueprints)
    results["doctrines"] = list(run.doctrines)
    results["gold_end"] = run.gold
    results["deck_size"] = len(run.deck)
    return results


def play_era1(seed: int, strategy: str) -> dict:
    r = play_eras(seed, strategy, max_era=1)
    r["won_era"] = r["won_through"] >= 1
    return r


def fight_settlement_with_docs(run: RunState, settlement: dict) -> tuple[bool, int, int]:
    rng = run.rng
    draw = list(run.deck)
    rng.shuffle(draw)
    discard: list[Card] = []
    hand: list[Card] = []
    refill_hand(hand, draw, discard, run.hand_size, rng)

    fight = FightMods()
    assaults = run.base_assaults
    regroups = run.base_regroups
    defence = settlement["defence"]
    st = dict(settlement)
    st["defence_left"] = defence
    total_damage = 0
    assaults_used = 0

    while defence > 0 and assaults > 0:
        st["defence_left"] = defence
        if should_regroup(run, hand, fight, st, regroups, assaults):
            dump = regroup_discard(hand, run)
            for c in dump:
                if c in hand:
                    hand.remove(c)
                    discard.append(c)
            refill_hand(hand, draw, discard, run.hand_size, rng)
            regroups -= 1
            continue

        play, _ = greedy_assault(run, hand, fight, st)
        for c in play:
            if c.kind == "B":
                avail = [b for b in run.blueprints if b not in fight.blueprints_fired]
                if avail:
                    bp = pick_blueprint(run, avail, st, fight)
                    trigger_blueprint(run, bp, fight, hand, draw, discard)
            if c.kind == "Y":
                avail = [d for d in run.doctrines if d not in fight.doctrines_fired]
                if avail:
                    trigger_doctrine(run, pick_doctrine(run, avail), fight)

        if fight.plus_assault:
            assaults += fight.plus_assault
            fight.plus_assault = 0
        if fight.plus_regroup:
            regroups += fight.plus_regroup
            fight.plus_regroup = 0

        ev = evaluate_play(run, play, fight, st, consume_burst=True)
        dmg = ev["damage"]
        defence -= dmg
        total_damage += dmg
        assaults_used += 1
        assaults -= 1
        for c in play:
            if c in hand:
                hand.remove(c)
                discard.append(c)
        refill_hand(hand, draw, discard, run.hand_size, rng)

    won = defence <= 0
    if run.zeal_settlements_left > 0:
        # decrement only after settlement resolves in after_victory path
        pass
    run._last_fight = fight  # type: ignore
    if won and run.zeal_settlements_left > 0:
        run.zeal_settlements_left -= 1
    return won, total_damage, assaults_used


def summarize(runs: list[dict], max_era: int = 1) -> dict:
    n = len(runs)
    clear_era = {e: sum(1 for r in runs if r.get("won_through", 0) >= e) / n for e in range(1, max_era + 1)}
    fail_era = Counter((r.get("failed_era"), r.get("failed_at")) for r in runs if r.get("won_through", 0) < max_era)

    def avg(xs):
        return round(sum(xs) / len(xs), 1) if xs else None

    def pct(xs, p):
        if not xs:
            return None
        ys = sorted(xs)
        return ys[min(len(ys) - 1, int(p / 100 * len(ys)))]

    by_era = {}
    for e in range(1, max_era + 1):
        caps = [s for r in runs for s in r["settlements"]
                if s.get("era", 1) == e and s["kind"] == "capital"]
        vill = [s for r in runs for s in r["settlements"]
                if s.get("era", 1) == e and s["kind"] == "village"]
        towns = [s for r in runs for s in r["settlements"]
                 if s.get("era", 1) == e and s["kind"] == "town"]
        cap_won = [s for s in caps if s["won"]]
        by_era[e] = {
            "base_defence": ERA_BASE_DEFENCE[e],
            "village_def": int(ERA_BASE_DEFENCE[e] * 1.0),
            "town_def": int(ERA_BASE_DEFENCE[e] * 1.5),
            "capital_def": int(ERA_BASE_DEFENCE[e] * 2.5),
            "village_clear": round(sum(1 for s in vill if s["won"]) / len(vill), 3) if vill else 0,
            "town_clear": round(sum(1 for s in towns if s["won"]) / len(towns), 3) if towns else 0,
            "capital_clear": round(sum(1 for s in caps if s["won"]) / len(caps), 3) if caps else 0,
            "avg_capital_damage_won": avg([s["damage"] for s in cap_won]),
            "p50_capital_damage_won": pct([s["damage"] for s in cap_won], 50),
            "avg_capital_overkill": avg([s.get("overkill") or 0 for s in cap_won]),
            "avg_village_damage": avg([s["damage"] for s in vill]),
            "attempts_capital": len(caps),
        }

    # Power vs HP: median capital damage among those who reached that capital
    power_curve = {}
    for e in range(1, max_era + 1):
        dmg = [s["damage"] for r in runs for s in r["settlements"]
               if s.get("era", 1) == e and s["kind"] == "capital"]
        hp = int(ERA_BASE_DEFENCE[e] * 2.5)
        power_curve[e] = {
            "capital_hp": hp,
            "p50_damage": pct(dmg, 50),
            "mean_damage": avg(dmg),
            "damage_to_hp_ratio_p50": round(pct(dmg, 50) / hp, 2) if dmg and pct(dmg, 50) else None,
        }

    return {
        "n": n,
        "max_era": max_era,
        "clear_through_era": {str(k): round(v, 3) for k, v in clear_era.items()},
        "fail_at": {f"{e}:{k}": v for (e, k), v in fail_era.items()},
        "by_era": {str(k): v for k, v in by_era.items()},
        "power_curve": {str(k): v for k, v in power_curve.items()},
        # backward compat for era1 report tooling
        "era_win_rate": round(clear_era.get(1, 0), 3),
        "village_clear_rate": by_era.get(1, {}).get("village_clear", 0),
        "town_clear_rate": by_era.get(1, {}).get("town_clear", 0),
        "capital_clear_rate": by_era.get(1, {}).get("capital_clear", 0),
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=300)
    ap.add_argument("--seed", type=int, default=42)
    ap.add_argument("--eras", type=int, default=1)
    args = ap.parse_args()

    strategies = ["S1", "S2", "S3", "S4", "S5", "S6", "BALANCED"]
    all_out = {"defence_bases": ERA_BASE_DEFENCE, "eras": args.eras}
    for strat in strategies:
        runs = []
        for i in range(args.runs):
            r = play_eras(args.seed + i * 17 + hash(strat) % 10000, strat, max_era=args.eras)
            r["won_era"] = r["won_through"] >= 1
            runs.append(r)
        all_out[strat] = summarize(runs, max_era=args.eras)
        fails = [r for r in runs if r["won_through"] < args.eras][:3]
        all_out[strat]["sample_failures"] = [
            {"failed_era": f.get("failed_era"), "failed_at": f["failed_at"],
             "tiers": f["tiers_end"], "policies": f["policies"],
             "blueprints": f["blueprints"],
             "settlements": f["settlements"][-3:]}
            for f in fails
        ]
        wins = [r for r in runs if r["won_through"] >= args.eras][:2]
        all_out[strat]["sample_wins"] = [
            {"tiers": w["tiers_end"], "policies": w["policies"],
             "blueprints": w["blueprints"], "doctrines": w["doctrines"],
             "deck_size": w.get("deck_size"),
             "damage_by_era_capital": w.get("damage_by_era_capital"),
             "settlements": [
                 {k: s[k] for k in ("era", "kind", "won", "damage", "defence", "assaults_used")}
                 for s in w["settlements"]
             ]}
            for w in wins
        ]
        pc = all_out[strat]["power_curve"]
        print(f"{strat}: through={all_out[strat]['clear_through_era']} "
              f"fail={all_out[strat]['fail_at']} "
              f"cap_ratio={[pc[str(e)].get('damage_to_hp_ratio_p50') for e in range(1, args.eras+1)]}")

    out_path = f"/workspace/sim/results/era{args.eras}_summary.json"
    with open(out_path, "w") as f:
        json.dump(all_out, f, indent=2)
    print(f"Wrote {out_path}")


if __name__ == "__main__":
    main()
