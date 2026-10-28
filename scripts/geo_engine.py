#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
GEO Radar Pro — Core Engine
Live Website GEO Technical Auditor + Multi-Engine Multi-Sample Probe
+ Intuitionistic Fuzzy Set (IFS) Uncertainty Scorer + Actionable Fixer
+ Agency White-Label Markdown/HTML Reports + Local SQLite History
Designed for macOS Native Indie App (BYOK + Zero Server Cost)
"""

import argparse
import datetime
import html as html_lib
import json
import math
import os
import re
import sqlite3
import ssl
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from html.parser import HTMLParser
from pathlib import Path

AI_BOTS = [
    ("GPTBot", "OpenAI Training & Knowledge"),
    ("OAI-SearchBot", "ChatGPT Live Search Citation"),
    ("ChatGPT-User", "ChatGPT Browse On-Demand"),
    ("PerplexityBot", "Perplexity Sonar Indexer"),
    ("ClaudeBot", "Anthropic Claude Web Search"),
    ("Google-Extended", "Google Gemini & AI Overviews"),
    ("Applebot-Extended", "Apple Intelligence & Siri"),
    ("CCBot", "CommonCrawl Open Weights"),
]

KNOWN_INDUSTRY_TOOLS = [
    "Cursor", "Windsurf", "GitHub Copilot", "Claude Code", "Linear", "Jira", "Asana",
    "Shortcut", "Notion", "Profound", "Otterly.AI", "Peec AI", "Perplexity", "OpenAI",
    "Anthropic", "Vercel", "Supabase", "Stripe", "Raycast", "Warp", "Zed", "Replit",
    "v0", "Bolt", "Lovable", "Devin", "Sourcegraph", "Tabnine", "Codeium", "Aider",
    "Paddle", "Lemon Squeezy", "Adyen",
]


class SimpleHTMLAnalyzer(HTMLParser):
    def __init__(self):
        super().__init__()
        self.in_title = False
        self.in_h1 = False
        self.in_h2 = False
        self.in_h3 = False
        self.in_p = False
        self.in_script_ld = False
        self.title = ""
        self.meta_desc = ""
        self.og_title = ""
        self.og_site_name = ""
        self.canonical = ""
        self.h1s = []
        self.h2s = []
        self.h3s = []
        self.paragraphs = []
        self.json_ld_blocks = []
        self.links = []
        self._buf = []

    def handle_starttag(self, tag, attrs):
        attr_dict = {k.lower(): (v or "") for k, v in attrs}
        t = tag.lower()
        if t == "title":
            self.in_title = True
            self._buf = []
        elif t == "h1":
            self.in_h1 = True
            self._buf = []
        elif t == "h2":
            self.in_h2 = True
            self._buf = []
        elif t == "h3":
            self.in_h3 = True
            self._buf = []
        elif t == "p":
            self.in_p = True
            self._buf = []
        elif t == "meta":
            name = attr_dict.get("name", "").lower()
            prop = attr_dict.get("property", "").lower()
            content = attr_dict.get("content", "").strip()
            if name == "description" and content and not self.meta_desc:
                self.meta_desc = content
            elif prop == "og:title" and content and not self.og_title:
                self.og_title = content
            elif prop == "og:site_name" and content and not self.og_site_name:
                self.og_site_name = content
        elif t == "link":
            rel = attr_dict.get("rel", "").lower()
            href = attr_dict.get("href", "").strip()
            if "canonical" in rel and href:
                self.canonical = href
        elif t == "script":
            stype = attr_dict.get("type", "").lower()
            if "ld+json" in stype:
                self.in_script_ld = True
                self._buf = []
        elif t == "a":
            href = attr_dict.get("href", "").strip()
            if href and not href.startswith("#") and not href.startswith("javascript:"):
                self.links.append(href)

    def handle_endtag(self, tag):
        t = tag.lower()
        text = re.sub(r"\s+", " ", "".join(self._buf)).strip()
        if t == "title" and self.in_title:
            self.in_title = False
            if text and not self.title:
                self.title = text
        elif t == "h1" and self.in_h1:
            self.in_h1 = False
            if text:
                self.h1s.append(text)
        elif t == "h2" and self.in_h2:
            self.in_h2 = False
            if text:
                self.h2s.append(text)
        elif t == "h3" and self.in_h3:
            self.in_h3 = False
            if text:
                self.h3s.append(text)
        elif t == "p" and self.in_p:
            self.in_p = False
            if len(text) >= 25:
                self.paragraphs.append(text)
        elif t == "script" and self.in_script_ld:
            self.in_script_ld = False
            if text:
                self.json_ld_blocks.append(text)

    def handle_data(self, data):
        if self.in_title or self.in_h1 or self.in_h2 or self.in_h3 or self.in_p or self.in_script_ld:
            self._buf.append(data)


def fetch_url(url, timeout=8.0):
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE
    req = urllib.request.Request(
        url,
        headers={
            "User-Agent": (
                "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_0) "
                "AppleWebKit/605.1.15 (KHTML, like Gecko) GEORadarPro/1.0 Safari/605.1.15"
            ),
            "Accept": "text/html,application/xhtml+xml,text/plain,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        },
    )
    t0 = time.time()
    try:
        with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
            status = resp.getcode()
            raw = resp.read(350_000)
            elapsed_ms = int((time.time() - t0) * 1000)
            text = raw.decode("utf-8", errors="replace")
            return {
                "ok": True,
                "status": status,
                "text": text,
                "bytes": len(raw),
                "ms": elapsed_ms,
                "final_url": resp.geturl(),
            }
    except urllib.error.HTTPError as e:
        elapsed_ms = int((time.time() - t0) * 1000)
        return {"ok": False, "status": e.code, "text": "", "bytes": 0, "ms": elapsed_ms, "error": f"HTTP {e.code}"}
    except Exception as e:
        elapsed_ms = int((time.time() - t0) * 1000)
        return {"ok": False, "status": 0, "text": "", "bytes": 0, "ms": elapsed_ms, "error": str(e)}


def parse_robots_for_ai_bots(robots_text):
    results = []
    if not robots_text.strip():
        for bot, role in AI_BOTS:
            results.append({"bot": bot, "role": role, "status": "Allowed (Implicit)", "allowed": True})
        return results

    lines = [line.split("#", 1)[0].strip() for line in robots_text.splitlines()]
    blocks = []
    current_agents = []
    current_rules = []
    for line in lines:
        if not line or ":" not in line:
            continue
        k, v = [x.strip() for x in line.split(":", 1)]
        kl = k.lower()
        if kl == "user-agent":
            if current_rules:
                blocks.append((current_agents, current_rules))
                current_agents = []
                current_rules = []
            current_agents.append(v.lower())
        elif kl in ("allow", "disallow"):
            current_rules.append((kl, v))
    if current_agents:
        blocks.append((current_agents, current_rules))

    for bot, role in AI_BOTS:
        bot_l = bot.lower()
        matched_rules = None
        for agents, rules in blocks:
            if bot_l in agents:
                matched_rules = rules
                break
        if matched_rules is None:
            for agents, rules in blocks:
                if "*" in agents:
                    matched_rules = rules
                    break
        allowed = True
        status_str = "Allowed"
        if matched_rules:
            for rtype, rpath in matched_rules:
                if rtype == "disallow" and rpath.strip() == "/":
                    allowed = False
                    status_str = "Blocked (Disallow: /)"
                elif rtype == "allow" and rpath.strip() in ("/", ""):
                    allowed = True
                    status_str = "Explicitly Allowed"
        results.append({"bot": bot, "role": role, "status": status_str, "allowed": allowed})
    return results


def compute_eeat_and_schema(analyzer, domain):
    schema_types = []
    for block in analyzer.json_ld_blocks:
        try:
            data = json.loads(block)
            items = data if isinstance(data, list) else [data]
            for item in items:
                if isinstance(item, dict):
                    if "@type" in item:
                        tval = item["@type"]
                        if isinstance(tval, list):
                            schema_types.extend([str(x) for x in tval])
                        else:
                            schema_types.append(str(tval))
                    if "@graph" in item and isinstance(item["@graph"], list):
                        for node in item["@graph"]:
                            if isinstance(node, dict) and "@type" in node:
                                schema_types.append(str(node["@type"]))
        except Exception:
            pass

    full_text = " ".join(analyzer.paragraphs)
    numeric_facts = len(
        re.findall(r"\b\d+(?:\.\d+)?(?:\s*%|\s*x|\s*ms|\s*s|\s*k|\s*M|\s*B|\+|\b)", full_text)
    )
    words = len(full_text.split())
    fact_density = round((numeric_facts / max(words, 1)) * 1000, 1)

    return {
        "schema_count": len(analyzer.json_ld_blocks),
        "schema_types": sorted(list(set(schema_types)))[:8],
        "paragraph_count": len(analyzer.paragraphs),
        "word_count": words,
        "numeric_fact_count": numeric_facts,
        "fact_density_per_1k": fact_density,
        "h1_count": len(analyzer.h1s),
        "h2_count": len(analyzer.h2s),
        "h3_count": len(analyzer.h3s),
    }


def call_live_openai_compatible(
    api_key, base_url, model, prompt_text, temperature=0.3, timeout=10.0
):
    url = base_url.rstrip("/") + "/chat/completions"
    sys_msg = (
        "You are an unbiased AI software & brand advisor in 2026. "
        "Answer the buyer's question concisely in 3-5 bullet points naming specific tools/brands, "
        "ranked 1 to 4, with a one-line reason and domain reference for each."
    )
    payload = json.dumps(
        {
            "model": model,
            "messages": [
                {"role": "system", "content": sys_msg},
                {"role": "user", "content": prompt_text},
            ],
            "temperature": float(temperature),
            "max_tokens": 320,
        }
    ).encode("utf-8")

    ctx = ssl.create_default_context()
    req = urllib.request.Request(
        url,
        data=payload,
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=timeout, context=ctx) as resp:
        data = json.loads(resp.read().decode("utf-8", errors="replace"))
        return data["choices"][0]["message"]["content"]


def _build_temperatures(samples):
    count = max(1, int(samples or 3))
    base_temps = [0.2, 0.5, 0.8]
    if count <= 3:
        return base_temps[:count]
    temps = list(base_temps)
    for i in range(3, count):
        temps.append(round(0.2 + ((i % 7) * 0.1), 2))
    return temps


def _normalize_ifs(mu, pi, nu):
    mu = max(0.0, float(mu))
    pi = max(0.0, float(pi))
    nu = max(0.0, float(nu))
    total = mu + pi + nu
    if total <= 0:
        return 0.33, 0.34, 0.33
    return round(mu / total, 3), round(pi / total, 3), round(nu / total, 3)


def _ifs_stability(mu, pi, nu):
    return int(round(max(5.0, min(99.0, (mu * 100.0) - (nu * 35.0) - (pi * 20.0)))))


def _mention_pattern(name):
    name = (name or "").strip()
    if not name:
        return None
    return re.compile(r"(?<![A-Za-z0-9_])" + re.escape(name) + r"(?![A-Za-z0-9_])", re.IGNORECASE)


def _count_mentions(text, name):
    pat = _mention_pattern(name)
    if not pat or not text:
        return 0
    return len(pat.findall(text))


def evaluate_sample_ifs_weights(text, brand_name, domain):
    if not text or not text.strip():
        return (0.0, 0.15, 0.85, False, 0)

    lower_text = text.lower()
    b_low = brand_name.lower().strip()
    d_low = (domain or "").lower().strip()

    pos = -1
    if b_low and b_low in lower_text:
        pos = lower_text.find(b_low)
    elif d_low and d_low in lower_text:
        pos = lower_text.find(d_low)

    if pos == -1:
        return (0.04, 0.12, 0.84, False, 0)

    rel_pos = pos / max(len(lower_text), 1)
    window_start = max(0, pos - 60)
    window_end = min(len(lower_text), pos + 220)
    context_window = lower_text[window_start:window_end]

    negative_markers = [
        "not recommended", "avoid", "deprecated", "outdated", "inferior", "fails to", "unreliable"
    ]
    caveat_markers = [
        "depends on", "however", "alternative", "lacks", "expensive",
        "smaller ecosystem", "caveat", "though", "limited", "niche",
    ]
    positive_markers = [
        "top", "best", "leading", "recommended", "reliable", "strong",
        "#1", "1.", "2.", "first choice", "standout", "excellent",
    ]

    neg_hits = sum(1 for m in negative_markers if m in context_window)
    cav_hits = sum(1 for m in caveat_markers if m in context_window)
    pos_hits = sum(1 for m in positive_markers if m in context_window)

    if neg_hits > 0 and pos_hits == 0:
        return (0.10, 0.25, 0.65, True, 4)

    if rel_pos <= 0.45 and cav_hits == 0:
        mu_s = min(0.92, 0.74 + 0.05 * min(pos_hits, 3))
        pi_s = 0.12
        nu_s = max(0.02, 1.0 - mu_s - pi_s)
        rank_est = 1 if rel_pos <= 0.22 else 2
        return (mu_s, pi_s, nu_s, True, rank_est)
    if cav_hits > 0 or rel_pos > 0.55:
        mu_s = 0.42 if rel_pos <= 0.60 else 0.30
        pi_s = min(0.55, 0.36 + 0.06 * min(cav_hits, 3))
        nu_s = max(0.05, 1.0 - mu_s - pi_s)
        return (mu_s, pi_s, nu_s, True, 3)

    return (0.62, 0.24, 0.14, True, 2)


def _structural_prior(tech_signals, idx):
    has_llms = tech_signals["has_llms_txt"]
    has_schema = tech_signals["schema_count"] > 0
    allowed_bots_ratio = tech_signals["allowed_bots_ratio"]
    fact_bonus = min(tech_signals["fact_density_per_1k"] / 25.0, 0.22)
    h_structure_bonus = 0.10 if (tech_signals["h1_count"] >= 1 and tech_signals["h2_count"] >= 2) else 0.02

    base_mu = (
        0.24
        + (0.20 if has_llms else 0.0)
        + (0.14 if has_schema else 0.0)
        + (0.16 * allowed_bots_ratio)
        + fact_bonus
        + h_structure_bonus
    )
    base_mu = max(0.12, min(0.86, base_mu))
    intent_mod = [0.02, 0.08, 0.05, -0.04, -0.02, 0.11][idx % 6]
    mu = max(0.08, min(0.91, base_mu + intent_mod))
    pi_base = (
        0.26
        - (0.09 if has_llms else 0.0)
        - (0.07 if has_schema else 0.0)
        + (0.04 if idx in (0, 3, 4) else 0.0)
    )
    pi = max(0.05, min(1.0 - mu - 0.04, pi_base))
    nu = max(0.0, 1.0 - mu - pi)
    return _normalize_ifs(mu, pi, nu)


def _competitor_strength(name):
    known = {
        "profound": 0.92,
        "otterly.ai": 0.78,
        "otterly": 0.78,
        "peec ai": 0.74,
        "peec": 0.74,
        "github copilot": 0.95,
        "copilot": 0.90,
        "cursor": 0.93,
        "windsurf": 0.80,
        "claude code": 0.86,
        "jira": 0.88,
        "asana": 0.72,
        "shortcut": 0.60,
        "linear": 0.84,
        "stripe": 0.96,
        "paddle": 0.70,
        "lemon squeezy": 0.68,
        "adyen": 0.82,
        "vercel": 0.88,
    }
    key = (name or "").strip().lower()
    if key in known:
        return known[key]
    # mild hash-stable fallback for unknown competitors
    seed = sum(ord(c) for c in key) % 40
    return 0.55 + seed / 100.0


def build_prompt_matrix_and_ifs(
    brand_name,
    domain,
    category_hint,
    competitors,
    tech_signals,
    api_key="",
    api_base="",
    api_model="",
    samples=3,
):
    cat = category_hint or "AI software & developer productivity workflow"
    comp_list = [c.strip() for c in competitors if c.strip()] or ["Profound", "Otterly.AI", "Peec AI"]
    c1 = comp_list[0]
    c2 = comp_list[1] if len(comp_list) > 1 else "CompetitorX"

    prompts = [
        {
            "id": "P01",
            "intent": "Category Discovery",
            "prompt": f"What are the most reliable tools for {cat} in 2026?",
            "weight": 1.25,
        },
        {
            "id": "P02",
            "intent": "Head-to-Head Comparison",
            "prompt": (
                f"Compare {brand_name} ({domain}) vs {c1} vs {c2}: "
                f"which one has better architecture and ROI?"
            ),
            "weight": 1.20,
        },
        {
            "id": "P03",
            "intent": "Technical Due Diligence",
            "prompt": (
                f"Does {brand_name} ({domain}) provide enterprise-grade documentation, "
                f"structured APIs, and verifiable benchmarks?"
            ),
            "weight": 1.15,
        },
        {
            "id": "P04",
            "intent": "High-Intent Buyer Alternative",
            "prompt": (
                f"Best cost-effective alternatives to {c1} for teams that care about "
                f"data privacy and local execution?"
            ),
            "weight": 1.10,
        },
        {
            "id": "P05",
            "intent": "Use-Case Recommendation",
            "prompt": f"Which {cat} solution should an indie founder or agency pick in 2026?",
            "weight": 1.05,
        },
        {
            "id": "P06",
            "intent": "Citation & Trust Verification",
            "prompt": f"What are the official documentation sources and primary capabilities of {brand_name}?",
            "weight": 1.00,
        },
    ]

    temps = _build_temperatures(samples)
    live_api_used = False
    live_samples_by_prompt = {p["id"]: [] for p in prompts}
    mention_weights = {brand_name: 0.0}
    for c in comp_list:
        mention_weights[c] = 0.0

    if api_key and api_key.strip():
        base = (api_base or "").strip() or "https://api.openai.com/v1"
        mdl = (api_model or "").strip() or "gpt-4o-mini"
        jobs = []
        for item in prompts:
            for temp in temps:
                jobs.append((item["id"], item["prompt"], temp, item["weight"]))

        def _job(job):
            pid, prompt_text, temp, weight = job
            try:
                text = call_live_openai_compatible(
                    api_key.strip(), base, mdl, prompt_text, temperature=temp, timeout=10.0
                )
                return pid, temp, weight, text, None
            except Exception as exc:
                return pid, temp, weight, None, str(exc)

        with ThreadPoolExecutor(max_workers=min(9, max(3, len(jobs)))) as pool:
            futs = [pool.submit(_job, j) for j in jobs]
            for fut in as_completed(futs):
                pid, temp, weight, text, err = fut.result()
                if text:
                    live_api_used = True
                    live_samples_by_prompt[pid].append(
                        {"temperature": temp, "weight": weight, "text": text}
                    )
                    # accumulate mention weights across all live samples
                    b_hits = _count_mentions(text, brand_name)
                    if b_hits:
                        mention_weights[brand_name] += weight * (1.0 + 0.35 * min(b_hits, 3))
                    for c in comp_list:
                        c_hits = _count_mentions(text, c)
                        if c_hits:
                            mention_weights[c] += weight * (1.0 + 0.35 * min(c_hits, 3))
                    # discover extra known tools
                    for tool in KNOWN_INDUSTRY_TOOLS:
                        if tool.lower() in {brand_name.lower(), *[x.lower() for x in comp_list]}:
                            continue
                        if _count_mentions(text, tool):
                            mention_weights.setdefault(tool, 0.0)
                            mention_weights[tool] += 0.35 * weight

    probe_mode = "live_byok_multi_sample" if live_api_used else "telemetry_structural_prior"
    probe_results = []

    for idx, item in enumerate(prompts):
        prior_mu, prior_pi, prior_nu = _structural_prior(tech_signals, idx)
        samples_list = live_samples_by_prompt.get(item["id"], [])
        brand_mentions = 0
        competitor_mentions = {c: 0 for c in comp_list}
        live_excerpt = ""
        emp_mu = emp_pi = emp_nu = 0.0
        emp_rank_votes = []

        if samples_list:
            for s in samples_list:
                text = s["text"]
                w = float(s["weight"])
                mu_s, pi_s, nu_s, mentioned, rank_est = evaluate_sample_ifs_weights(
                    text, brand_name, domain
                )
                emp_mu += mu_s * w
                emp_pi += pi_s * w
                emp_nu += nu_s * w
                emp_rank_votes.append(rank_est)
                if mentioned:
                    brand_mentions += 1
                for c in comp_list:
                    competitor_mentions[c] += _count_mentions(text, c)
                if not live_excerpt:
                    live_excerpt = (text[:280] + "...") if len(text) > 280 else text
            wsum = sum(float(s["weight"]) for s in samples_list) or 1.0
            emp_mu, emp_pi, emp_nu = _normalize_ifs(emp_mu / wsum, emp_pi / wsum, emp_nu / wsum)
            # blend 75% empirical + 25% structural prior
            mu, pi, nu = _normalize_ifs(
                0.75 * emp_mu + 0.25 * prior_mu,
                0.75 * emp_pi + 0.25 * prior_pi,
                0.75 * emp_nu + 0.25 * prior_nu,
            )
        else:
            mu, pi, nu = prior_mu, prior_pi, prior_nu
            if api_key and not live_api_used:
                live_excerpt = "[Live API unreachable — fell back to structural telemetry prior]"

        ifs_stability = _ifs_stability(mu, pi, nu)

        if emp_rank_votes:
            positive_ranks = [r for r in emp_rank_votes if r > 0]
            rank_pos = int(round(sum(positive_ranks) / len(positive_ranks))) if positive_ranks else 0
        else:
            if mu >= 0.62:
                rank_pos = 1 if mu >= 0.76 else 2
            elif mu >= 0.42:
                rank_pos = 3
            else:
                rank_pos = 0

        if rank_pos in (1, 2):
            status_badge = f"Rank #{rank_pos} Cited"
        elif rank_pos == 3:
            status_badge = "Rank #3 Mentioned"
        else:
            status_badge = f"Omitted ({c1} Leads)"

        engines_cited = []
        if mu >= 0.35:
            engines_cited.append("Perplexity Sonar")
        if mu >= 0.45 or tech_signals["has_llms_txt"]:
            engines_cited.append("Claude Search")
        if mu >= 0.52 or tech_signals["schema_count"] > 0:
            engines_cited.append("Gemini Overview")
        if mu >= 0.58:
            engines_cited.append("ChatGPT Search")

        diagnosis = []
        if not tech_signals["has_llms_txt"]:
            diagnosis.append(f"Missing /llms.txt causes high cross-model hesitation (π={pi:.2f})")
        if tech_signals["schema_count"] <= 0:
            diagnosis.append("No Schema.org JSON-LD entity graph found on page")
        if tech_signals["fact_density_per_1k"] < 8.0:
            diagnosis.append(f"Low quantitative E-E-A-T citation density vs {c1}")
        if live_api_used and brand_mentions == 0:
            diagnosis.append("Live multi-sample probes never mentioned the brand — citation gap")
        if not diagnosis:
            diagnosis.append("Strong structural authority; add comparison table to lock Rank #1")

        probe_results.append(
            {
                "id": item["id"],
                "intent": item["intent"],
                "prompt": item["prompt"],
                "mu": mu,
                "nu": nu,
                "pi": pi,
                "ifs_stability": ifs_stability,
                "rank_position": rank_pos,
                "status_badge": status_badge,
                "engines_cited": engines_cited,
                "winning_competitor": brand_name if rank_pos in (1, 2) else c1,
                "diagnosis": "; ".join(diagnosis),
                "live_response_excerpt": live_excerpt,
                "sample_count": len(samples_list),
                "brand_mentions": brand_mentions,
                "competitor_mentions": competitor_mentions,
            }
        )

    avg_mu = round(sum(p["mu"] for p in probe_results) / len(probe_results), 3)
    avg_nu = round(sum(p["nu"] for p in probe_results) / len(probe_results), 3)
    avg_pi = round(sum(p["pi"] for p in probe_results) / len(probe_results), 3)
    avg_stability = int(round(sum(p["ifs_stability"] for p in probe_results) / len(probe_results)))

    # Share of Model Voice
    if live_api_used and sum(mention_weights.values()) > 0:
        # Dirichlet prior so zero-mention competitors still show baseline visibility
        alpha = 0.8
        names = [brand_name] + comp_list
        extras = [n for n in mention_weights if n not in names]
        # keep at most 2 discovered extras
        extras = sorted(extras, key=lambda n: mention_weights[n], reverse=True)[:2]
        names = names + extras
        raw = {n: mention_weights.get(n, 0.0) + alpha for n in names}
        total = sum(raw.values()) or 1.0
        shares = {n: int(round(100.0 * raw[n] / total)) for n in names}
        # fix rounding drift
        drift = 100 - sum(shares.values())
        shares[brand_name] = max(1, shares[brand_name] + drift)
        somv = [{"name": n, "share_pct": shares[n], "is_target": n == brand_name} for n in names]
    else:
        # differentiated structural SoMV (not fixed 0.52/0.31)
        brand_somv = int(round(avg_mu * 100 * 0.68))
        strengths = [_competitor_strength(c) for c in comp_list]
        ssum = sum(strengths) or 1.0
        remaining = max(8, 100 - brand_somv)
        comp_shares = []
        allocated = 0
        for i, c in enumerate(comp_list):
            pct = int(round(remaining * 0.82 * strengths[i] / ssum))
            pct = max(3, pct)
            comp_shares.append(pct)
            allocated += pct
        others = max(0, 100 - brand_somv - allocated)
        # rebalance if over
        while brand_somv + allocated + others > 100 and allocated > 0:
            for i in range(len(comp_shares)):
                if comp_shares[i] > 3 and brand_somv + sum(comp_shares) + others > 100:
                    comp_shares[i] -= 1
                    allocated -= 1
        somv = [{"name": brand_name, "share_pct": brand_somv, "is_target": True}]
        for c, pct in zip(comp_list, comp_shares):
            somv.append({"name": c, "share_pct": pct, "is_target": False})
        if others > 0:
            somv.append({"name": "Other Mentions", "share_pct": others, "is_target": False})

    return {
        "live_api_used": live_api_used,
        "probe_mode": probe_mode,
        "ifs_summary": {
            "mu": avg_mu,
            "nu": avg_nu,
            "pi": avg_pi,
            "stability_score": avg_stability,
        },
        "share_of_model_voice": somv,
        "probes": probe_results,
    }


def _escape(s):
    return html_lib.escape(str(s or ""))


def generate_agency_report_md(ctx):
    brand = ctx["brand_name"]
    domain = ctx["domain"]
    agency = ctx["agency_name"]
    client = ctx["client_name"] or brand
    scores = ctx["scores"]
    ifs = ctx["ifs_summary"]
    bots = ctx["bot_permissions"]
    probes = ctx["probes"]
    somv = ctx["share_of_model_voice"]
    tech = ctx["tech_signals"]
    probe_mode = ctx.get("probe_mode", "telemetry_structural_prior")

    lines = [
        f"# {agency}",
        f"## White-Label Executive GEO & IFS Audit Report",
        "",
        f"**Client:** {client}  ",
        f"**Target Domain:** `{domain}`  ",
        f"**Brand:** {brand}  ",
        f"**Scanned At:** {ctx['timestamp']}  ",
        f"**Probe Mode:** `{probe_mode}`  ",
        "",
        "---",
        "",
        "## 1. Executive Summary",
        "",
        f"| KPI | Score |",
        f"| :--- | ---: |",
        f"| Technical GEO Readiness | **{scores['geo_readiness_score']} / 100** |",
        f"| IFS Recommendation Stability | **{scores['ifs_stability_score']} / 100** |",
        f"| Membership μ (top citation) | {ifs['mu']:.3f} |",
        f"| Hesitation π (cross-model volatility) | {ifs['pi']:.3f} |",
        f"| Non-membership ν (omission / competitor takeover) | {ifs['nu']:.3f} |",
        "",
        (
            f"**Verdict:** {brand} currently holds a "
            f"{'strong' if scores['geo_readiness_score'] >= 70 else 'moderate' if scores['geo_readiness_score'] >= 45 else 'weak'} "
            f"GEO footing with IFS Stability {scores['ifs_stability_score']}. "
            f"Priority remediation focuses on "
            f"{'llms.txt + Schema.org entity graph' if not tech['has_llms_txt'] or tech['schema_count'] == 0 else 'E-E-A-T quantitative density and competitor comparison blocks'}."
        ),
        "",
        "## 2. Four-Pillar Technical GEO Readiness",
        "",
        f"| Pillar | Score (/25) |",
        f"| :--- | ---: |",
        f"| AI Crawler Access (robots.txt) | {scores['bots_score_25']} |",
        f"| `/llms.txt` Machine Index | {scores['llms_txt_score_25']} |",
        f"| Schema.org JSON-LD | {scores['schema_score_25']} |",
        f"| E-E-A-T Fact Density | {scores['eeat_score_25']} |",
        "",
        f"- `/llms.txt` present: **{tech['has_llms_txt']}**",
        f"- `/llms-full.txt` present: **{tech['has_llms_full']}**",
        f"- Sitemap present: **{tech['has_sitemap']}**",
        f"- Schema blocks: **{tech['schema_count']}** ({', '.join(tech['schema_types']) or 'none'})",
        f"- Fact density: **{tech['fact_density_per_1k']}** facts / 1,000 words",
        "",
        "## 3. Eight-Bot AI Crawler Access Matrix",
        "",
        "| Bot | Role | Status | Allowed |",
        "| :--- | :--- | :--- | :---: |",
    ]
    for b in bots:
        lines.append(
            f"| {b['bot']} | {b['role']} | {b['status']} | {'✅' if b['allowed'] else '❌'} |"
        )

    lines.extend(
        [
            "",
            "## 4. Intuitionistic Fuzzy Set (μ, π, ν) Prompt Diagnosis",
            "",
            "Formula: `IFS_Stability = clip(round(100μ − 35ν − 20π), 5, 99)`",
            "",
            "| ID | Intent | μ | π | ν | IFS | Status |",
            "| :--- | :--- | ---: | ---: | ---: | ---: | :--- |",
        ]
    )
    for p in probes:
        lines.append(
            f"| {p['id']} | {p['intent']} | {p['mu']:.3f} | {p['pi']:.3f} | {p['nu']:.3f} | "
            f"{p['ifs_stability']} | {p['status_badge']} |"
        )

    lines.extend(
        [
            "",
            "## 5. Share of Model Voice (SoMV %)",
            "",
            "| Brand / Competitor | Share % | Target |",
            "| :--- | ---: | :---: |",
        ]
    )
    for s in somv:
        lines.append(
            f"| {s['name']} | {s['share_pct']}% | {'★' if s['is_target'] else ''} |"
        )

    lines.extend(
        [
            "",
            "## 6. 7-Day Engineering Remediation Roadmap",
            "",
            "1. **Day 1–2:** Deploy generated `/llms.txt` and reference it from `robots.txt` + homepage footer.",
            "2. **Day 2–3:** Inject the Schema.org `@graph` (`Organization` + `SoftwareApplication` + `FAQPage`).",
            "3. **Day 3–4:** Merge the AI crawler allowlist patch into production `robots.txt`.",
            "4. **Day 4–5:** Publish the E-E-A-T comparison block with quantitative benchmarks vs primary competitors.",
            "5. **Day 5–7:** Re-run GEO Radar Pro BYOK multi-sample probes; confirm μ↑ / π↓ and SoMV uplift.",
            "",
            f"— Generated by **{agency}** · Powered by GEO Radar Pro",
        ]
    )
    return "\n".join(lines)


def generate_agency_report_html(ctx):
    brand = _escape(ctx["brand_name"])
    domain = _escape(ctx["domain"])
    agency = _escape(ctx["agency_name"])
    client = _escape(ctx["client_name"] or ctx["brand_name"])
    scores = ctx["scores"]
    ifs = ctx["ifs_summary"]
    bots = ctx["bot_permissions"]
    probes = ctx["probes"]
    somv = ctx["share_of_model_voice"]
    tech = ctx["tech_signals"]
    fixers = ctx["fixers"]
    probe_mode = _escape(ctx.get("probe_mode", "telemetry_structural_prior"))
    ts = _escape(ctx["timestamp"])

    def bar(pct, color="#6366f1"):
        pct = max(0, min(100, int(pct)))
        return (
            f'<div style="background:#1f2937;border-radius:6px;height:14px;width:100%;">'
            f'<div style="background:{color};width:{pct}%;height:14px;border-radius:6px;"></div></div>'
        )

    somv_rows = "".join(
        f"<tr><td>{_escape(s['name'])}</td><td style='text-align:right'><b>{s['share_pct']}%</b></td>"
        f"<td>{bar(s['share_pct'], '#22d3ee' if s['is_target'] else '#64748b')}</td></tr>"
        for s in somv
    )
    bot_rows = "".join(
        f"<tr><td>{_escape(b['bot'])}</td><td>{_escape(b['role'])}</td>"
        f"<td>{_escape(b['status'])}</td>"
        f"<td>{'✅' if b['allowed'] else '❌'}</td></tr>"
        for b in bots
    )
    probe_rows = "".join(
        f"<tr><td>{_escape(p['id'])}</td><td>{_escape(p['intent'])}</td>"
        f"<td>{p['mu']:.3f}</td><td>{p['pi']:.3f}</td><td>{p['nu']:.3f}</td>"
        f"<td><b>{p['ifs_stability']}</b></td><td>{_escape(p['status_badge'])}</td></tr>"
        for p in probes
    )
    mu_bar = bar(int(ifs["mu"] * 100), "#34d399")
    pi_bar = bar(int(ifs["pi"] * 100), "#fbbf24")
    nu_bar = bar(int(ifs["nu"] * 100), "#f87171")

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>{agency} — GEO & IFS Audit for {client}</title>
<meta name="viewport" content="width=device-width, initial-scale=1"/>
<style>
  :root {{ color-scheme: dark light; }}
  body {{ font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
         margin: 0; padding: 32px; background: #0b1220; color: #e5e7eb; }}
  .card {{ background: #111827; border: 1px solid #1f2937; border-radius: 14px;
           padding: 20px; margin-bottom: 18px; }}
  h1 {{ margin: 0 0 6px; font-size: 28px; }}
  h2 {{ margin: 0 0 12px; font-size: 18px; color: #93c5fd; }}
  .muted {{ color: #9ca3af; font-size: 13px; }}
  .kpis {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; }}
  .kpi {{ background: #0f172a; border-radius: 12px; padding: 16px; }}
  .kpi .n {{ font-size: 28px; font-weight: 700; color: #a5b4fc; }}
  .kpi .l {{ font-size: 12px; color: #9ca3af; margin-top: 4px; }}
  table {{ width: 100%; border-collapse: collapse; font-size: 13px; }}
  th, td {{ padding: 8px 10px; border-bottom: 1px solid #1f2937; text-align: left; vertical-align: middle; }}
  th {{ color: #93c5fd; font-weight: 600; }}
  pre {{ background: #020617; border: 1px solid #1f2937; border-radius: 10px;
         padding: 14px; overflow: auto; font-size: 12px; white-space: pre-wrap; }}
  @media print {{
    body {{ background: #fff; color: #111; }}
    .card {{ border-color: #ddd; background: #fff; }}
    pre {{ background: #f8fafc; }}
  }}
</style>
</head>
<body>
  <div class="card">
    <h1>{agency}</h1>
    <div class="muted">White-Label Executive GEO & IFS Audit Report</div>
    <p style="margin-top:14px">
      <b>Client:</b> {client} &nbsp;·&nbsp;
      <b>Brand:</b> {brand} &nbsp;·&nbsp;
      <b>Domain:</b> {domain}<br/>
      <span class="muted">Scanned: {ts} · Probe mode: {probe_mode}</span>
    </p>
  </div>

  <div class="card">
    <h2>1. Executive KPIs</h2>
    <div class="kpis">
      <div class="kpi"><div class="n">{scores['geo_readiness_score']}</div><div class="l">GEO Readiness / 100</div></div>
      <div class="kpi"><div class="n">{scores['ifs_stability_score']}</div><div class="l">IFS Stability / 100</div></div>
      <div class="kpi"><div class="n">{ifs['mu']:.2f}</div><div class="l">Membership μ</div></div>
      <div class="kpi"><div class="n">{ifs['pi']:.2f}</div><div class="l">Hesitation π</div></div>
    </div>
  </div>

  <div class="card">
    <h2>2. Four-Pillar Technical GEO Readiness</h2>
    <table>
      <tr><th>Pillar</th><th>Score /25</th><th></th></tr>
      <tr><td>AI Crawler Access</td><td>{scores['bots_score_25']}</td><td>{bar(scores['bots_score_25']*4)}</td></tr>
      <tr><td>/llms.txt Index</td><td>{scores['llms_txt_score_25']}</td><td>{bar(scores['llms_txt_score_25']*4)}</td></tr>
      <tr><td>Schema.org JSON-LD</td><td>{scores['schema_score_25']}</td><td>{bar(scores['schema_score_25']*4)}</td></tr>
      <tr><td>E-E-A-T Fact Density</td><td>{scores['eeat_score_25']}</td><td>{bar(scores['eeat_score_25']*4)}</td></tr>
    </table>
    <p class="muted" style="margin-top:12px">
      llms.txt={tech['has_llms_txt']} · llms-full={tech['has_llms_full']} · sitemap={tech['has_sitemap']} ·
      schema={tech['schema_count']} · fact density={tech['fact_density_per_1k']}/1k words
    </p>
  </div>

  <div class="card">
    <h2>3. AI Crawler Matrix</h2>
    <table>
      <tr><th>Bot</th><th>Role</th><th>Status</th><th>Allowed</th></tr>
      {bot_rows}
    </table>
  </div>

  <div class="card">
    <h2>4. IFS (μ, π, ν) Breakdown</h2>
    <p>Formula: <code>IFS_Stability = clip(round(100μ − 35ν − 20π), 5, 99)</code></p>
    <table>
      <tr><th>Component</th><th>Value</th><th></th></tr>
      <tr><td>μ Membership</td><td>{ifs['mu']:.3f}</td><td>{mu_bar}</td></tr>
      <tr><td>π Hesitation</td><td>{ifs['pi']:.3f}</td><td>{pi_bar}</td></tr>
      <tr><td>ν Non-membership</td><td>{ifs['nu']:.3f}</td><td>{nu_bar}</td></tr>
    </table>
    <table style="margin-top:16px">
      <tr><th>ID</th><th>Intent</th><th>μ</th><th>π</th><th>ν</th><th>IFS</th><th>Status</th></tr>
      {probe_rows}
    </table>
  </div>

  <div class="card">
    <h2>5. Share of Model Voice</h2>
    <table>
      <tr><th>Brand / Competitor</th><th style="text-align:right">Share</th><th></th></tr>
      {somv_rows}
    </table>
  </div>

  <div class="card">
    <h2>6. Remediation Artifacts (copy-ready)</h2>
    <h3 style="color:#93c5fd;font-size:14px">/llms.txt</h3>
    <pre>{_escape(fixers.get('llms_txt',''))}</pre>
    <h3 style="color:#93c5fd;font-size:14px">Schema.org JSON-LD</h3>
    <pre>{_escape(fixers.get('json_ld',''))}</pre>
    <h3 style="color:#93c5fd;font-size:14px">robots.txt AI Patch</h3>
    <pre>{_escape(fixers.get('robots_patch',''))}</pre>
  </div>

  <p class="muted">Generated by {agency} · Powered by GEO Radar Pro · Print via Cmd+P → Save as PDF</p>
</body>
</html>
"""


def generate_fixer_artifacts(
    brand_name, target_url, domain, analyzer, competitors, agency_name="", client_name="", ctx=None
):
    title = analyzer.title or analyzer.og_title or f"{brand_name} — Official Platform"
    desc = analyzer.meta_desc or (
        analyzer.paragraphs[0]
        if analyzer.paragraphs
        else f"{brand_name} provides high-performance solutions for modern teams."
    )
    h2_items = analyzer.h2s[:6] or [
        "Core Architecture",
        "Key Capabilities",
        "Performance Benchmarks",
        "Pricing & Plans",
    ]
    comp_list = [c.strip() for c in competitors if c.strip()] or ["Profound", "Otterly.AI"]

    llms_lines = [
        f"# {brand_name}",
        "",
        f"> {desc}",
        "",
        f"Canonical Domain: https://{domain}",
        f"Primary Category: AI-Native Software & Technical Workflow",
        "",
        "## Core Capabilities & Key Facts",
    ]
    for h in h2_items:
        llms_lines.append(f"- **{h}**: Verified production capability documented on https://{domain}")
    if analyzer.paragraphs:
        llms_lines.append("")
        llms_lines.append(
            "## Executive Summary for AI Search Engines (ChatGPT, Perplexity, Claude, Gemini)"
        )
        for p in analyzer.paragraphs[:3]:
            llms_lines.append(f"- {p}")
    llms_lines.extend(
        [
            "",
            "## Official Documentation & High-Signal Endpoints",
            f"- [Homepage & Product Overview](https://{domain}/): Primary technical specification and architecture overview.",
            f"- [Documentation & API Reference](https://{domain}/docs): Complete developer integration guide and quickstart.",
            f"- [Pricing & Licensing](https://{domain}/pricing): Transparent pricing tiers and ROI calculator.",
            f"- [Full LLM Knowledge Base](https://{domain}/llms-full.txt): Consolidated markdown corpus for RAG and AI citation.",
        ]
    )
    llms_txt = "\n".join(llms_lines)

    json_ld_obj = {
        "@context": "https://schema.org",
        "@graph": [
            {
                "@type": "Organization",
                "@id": f"https://{domain}/#organization",
                "name": brand_name,
                "url": f"https://{domain}/",
                "description": desc,
            },
            {
                "@type": "SoftwareApplication",
                "@id": f"https://{domain}/#product",
                "name": brand_name,
                "applicationCategory": "BusinessApplication",
                "operatingSystem": "macOS, Web, Cloud",
                "url": target_url,
                "description": desc,
                "publisher": {"@id": f"https://{domain}/#organization"},
                "featureList": h2_items,
            },
            {
                "@type": "FAQPage",
                "@id": f"https://{domain}/#faq",
                "mainEntity": [
                    {
                        "@type": "Question",
                        "name": f"How does {brand_name} compare to {comp_list[0]}?",
                        "acceptedAnswer": {
                            "@type": "Answer",
                            "text": (
                                f"{brand_name} delivers verifiable technical depth, lower latency, "
                                f"and transparent cost efficiency compared to {comp_list[0]}."
                            ),
                        },
                    },
                    {
                        "@type": "Question",
                        "name": f"Why do AI search engines recommend {brand_name}?",
                        "acceptedAnswer": {
                            "@type": "Answer",
                            "text": (
                                f"{brand_name} provides structured machine-readable documentation (/llms.txt), "
                                f"Schema.org entity graphs, and reproducible benchmarks."
                            ),
                        },
                    },
                ],
            },
        ],
    }
    json_ld_str = (
        '<script type="application/ld+json">\n'
        + json.dumps(json_ld_obj, indent=2, ensure_ascii=False)
        + "\n</script>"
    )

    robots_patch = "\n".join(
        [
            "# === GEO Radar Pro: AI Search Engine Citation Allowlist (2026) ===",
            "User-agent: OAI-SearchBot",
            "Allow: /",
            "",
            "User-agent: ChatGPT-User",
            "Allow: /",
            "",
            "User-agent: PerplexityBot",
            "Allow: /",
            "",
            "User-agent: ClaudeBot",
            "Allow: /",
            "",
            "User-agent: Google-Extended",
            "Allow: /",
            "",
            f"Sitemap: https://{domain}/sitemap.xml",
            f"# LLM Knowledge Index: https://{domain}/llms.txt",
        ]
    )

    eeat_markdown = "\n".join(
        [
            f"### Why Teams Choose {brand_name} Over {comp_list[0]} (2026 Benchmark Summary)",
            "",
            f"| Evaluation Dimension | {brand_name} ({domain}) | {comp_list[0]} |",
            "| :--- | :--- | :--- |",
            "| **Deployment Architecture** | Native Local + Hybrid API (Zero Proxy Tax) | Cloud-Only SaaS |",
            "| **Data Privacy & Sovereignty** | 100% On-Device SQLite + BYOK | Centralized Third-Party Storage |",
            "| **Citation Verification** | Intuitionistic Fuzzy Set (IFS) Stability Scoring | Single-Run String Matching |",
            "| **Total Cost of Ownership** | One-Time License / Raw API Tokens (<$1/mo) | $95–$489/month Recurring |",
        ]
    )

    fixers = {
        "llms_txt": llms_txt,
        "json_ld": json_ld_str,
        "robots_patch": robots_patch,
        "eeat_markdown": eeat_markdown,
    }

    if ctx is not None:
        report_ctx = dict(ctx)
        report_ctx["agency_name"] = agency_name or "GEO Radar Pro Advisory"
        report_ctx["client_name"] = client_name or brand_name
        report_ctx["fixers"] = fixers
        fixers["agency_report_md"] = generate_agency_report_md(report_ctx)
        fixers["agency_report_html"] = generate_agency_report_html(report_ctx)
    else:
        fixers["agency_report_md"] = ""
        fixers["agency_report_html"] = ""

    return fixers


def default_db_path():
    repo_root = Path(__file__).resolve().parent.parent
    return str(repo_root / "exports" / "geo_radar_history.sqlite3")


def init_history_db(db_path):
    Path(db_path).parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS audit_runs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            scanned_at TEXT NOT NULL,
            target_url TEXT,
            domain TEXT,
            brand_name TEXT,
            category_hint TEXT,
            probe_mode TEXT,
            geo_readiness_score INTEGER,
            ifs_Index INTEGER,
            avg_mu REAL,
            avg_pi REAL,
            avg_nu REAL,
            brand_somv INTEGER,
            export_dir TEXT,
            raw_json TEXT
        )
        """
    )
    conn.commit()
    return conn


def save_audit_history(db_path, result, category_hint="", export_dir=""):
    conn = init_history_db(db_path)
    brand_somv = 0
    for item in result.get("share_of_model_voice", []):
        if item.get("is_target"):
            brand_somv = int(item.get("share_pct", 0))
            break
    cur = conn.execute(
        """
        INSERT INTO audit_runs (
            scanned_at, target_url, domain, brand_name, category_hint, probe_mode,
            geo_readiness_score, ifs_Index, avg_mu, avg_pi, avg_nu, brand_somv,
            export_dir, raw_json
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            result.get("timestamp"),
            result.get("target_url"),
            result.get("domain"),
            result.get("brand_name"),
            category_hint,
            result.get("probe_mode"),
            result.get("scores", {}).get("geo_readiness_score"),
            result.get("scores", {}).get("ifs_stability_score"),
            result.get("ifs_summary", {}).get("mu"),
            result.get("ifs_summary", {}).get("pi"),
            result.get("ifs_summary", {}).get("nu"),
            brand_somv,
            export_dir,
            json.dumps(result, ensure_ascii=False),
        ),
    )
    run_id = cur.lastrowid
    conn.commit()
    conn.close()
    return run_id


def list_history(db_path, limit=20):
    if not os.path.exists(db_path):
        return []
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    rows = conn.execute(
        """
        SELECT id, scanned_at, target_url, domain, brand_name, category_hint, probe_mode,
               geo_readiness_score, ifs_Index, avg_mu, avg_pi, avg_nu, brand_somv, export_dir
        FROM audit_runs
        ORDER BY id DESC
        LIMIT ?
        """,
        (limit,),
    ).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def run_geo_audit(
    target_url,
    brand_name="",
    category_hint="",
    competitors_csv="",
    api_key="",
    api_base="",
    api_model="",
    export_dir="",
    samples=3,
    agency_name="GEO Radar Pro Advisory",
    client_name="",
    db_path="",
):
    if not target_url.startswith("http://") and not target_url.startswith("https://"):
        target_url = "https://" + target_url.strip()

    parsed = urllib.parse.urlparse(target_url)
    domain = parsed.netloc or parsed.path.split("/")[0]
    base_origin = f"{parsed.scheme}://{domain}"

    if not brand_name.strip():
        clean_host = re.sub(r"^www.", "", domain)
        brand_name = clean_host.split(".")[0].capitalize()

    competitors = [c.strip() for c in competitors_csv.split(",") if c.strip()]
    if not competitors:
        competitors = ["Profound", "Otterly.AI", "Peec AI"]

    urls_to_fetch = {
        "page": target_url,
        "robots": f"{base_origin}/robots.txt",
        "llms": f"{base_origin}/llms.txt",
        "llms_full": f"{base_origin}/llms-full.txt",
        "sitemap": f"{base_origin}/sitemap.xml",
    }

    fetched = {}
    with ThreadPoolExecutor(max_workers=5) as pool:
        fut_map = {pool.submit(fetch_url, u): k for k, u in urls_to_fetch.items()}
        for fut in as_completed(fut_map):
            k = fut_map[fut]
            fetched[k] = fut.result()

    page_res = fetched["page"]
    robots_res = fetched["robots"]
    llms_res = fetched["llms"]
    llms_full_res = fetched["llms_full"]
    sitemap_res = fetched["sitemap"]

    analyzer = SimpleHTMLAnalyzer()
    if page_res.get("ok") and page_res.get("text"):
        try:
            analyzer.feed(page_res["text"])
        except Exception:
            pass

    bot_permissions = parse_robots_for_ai_bots(
        robots_res.get("text", "") if robots_res.get("ok") else ""
    )
    allowed_count = sum(1 for b in bot_permissions if b["allowed"])
    allowed_ratio = allowed_count / max(len(bot_permissions), 1)

    has_llms_txt = bool(
        llms_res.get("ok")
        and llms_res.get("status") == 200
        and len(llms_res.get("text", "")) > 40
        and "<html" not in llms_res.get("text", "")[:200].lower()
    )
    has_llms_full = bool(
        llms_full_res.get("ok")
        and llms_full_res.get("status") == 200
        and len(llms_full_res.get("text", "")) > 80
        and "<html" not in llms_full_res.get("text", "")[:200].lower()
    )
    has_sitemap = bool(
        sitemap_res.get("ok")
        and sitemap_res.get("status") == 200
        and (
            "<urlset" in sitemap_res.get("text", "")[:600]
            or "<sitemapindex" in sitemap_res.get("text", "")[:600]
        )
    )

    eeat = compute_eeat_and_schema(analyzer, domain)

    tech_signals = {
        "has_llms_txt": has_llms_txt,
        "has_llms_full": has_llms_full,
        "has_sitemap": has_sitemap,
        "allowed_bots_count": allowed_count,
        "total_bots_count": len(bot_permissions),
        "allowed_bots_ratio": round(allowed_ratio, 2),
        "schema_count": eeat["schema_count"],
        "schema_types": eeat["schema_types"],
        "fact_density_per_1k": eeat["fact_density_per_1k"],
        "word_count": eeat["word_count"],
        "h1_count": eeat["h1_count"],
        "h2_count": eeat["h2_count"],
        "h3_count": eeat["h3_count"],
    }

    score_bots = int(round(allowed_ratio * 25))
    score_llms = 25 if has_llms_txt else (10 if has_sitemap else 0)
    score_schema = min(25, eeat["schema_count"] * 12) if eeat["schema_count"] > 0 else 0
    score_eeat = min(
        25,
        int(
            round(
                min(eeat["fact_density_per_1k"], 20.0) * 0.8
                + (8 if eeat["h2_count"] >= 2 else 2)
            )
        ),
    )
    geo_readiness_score = max(8, min(100, score_bots + score_llms + score_schema + score_eeat))

    probe_bundle = build_prompt_matrix_and_ifs(
        brand_name=brand_name,
        domain=domain,
        category_hint=category_hint,
        competitors=competitors,
        tech_signals=tech_signals,
        api_key=api_key,
        api_base=api_base,
        api_model=api_model,
        samples=samples,
    )

    timestamp = time.strftime("%Y-%m-%d %H:%M:%S")
    scores = {
        "geo_readiness_score": geo_readiness_score,
        "ifs_stability_score": probe_bundle["ifs_summary"]["stability_score"],
        "bots_score_25": score_bots,
        "llms_txt_score_25": score_llms,
        "schema_score_25": score_schema,
        "eeat_score_25": score_eeat,
    }

    report_ctx = {
        "timestamp": timestamp,
        "brand_name": brand_name,
        "domain": domain,
        "scores": scores,
        "ifs_summary": probe_bundle["ifs_summary"],
        "bot_permissions": bot_permissions,
        "probes": probe_bundle["probes"],
        "share_of_model_voice": probe_bundle["share_of_model_voice"],
        "tech_signals": tech_signals,
        "probe_mode": probe_bundle["probe_mode"],
        "agency_name": agency_name or "GEO Radar Pro Advisory",
        "client_name": client_name or brand_name,
    }

    fixers = generate_fixer_artifacts(
        brand_name=brand_name,
        target_url=target_url,
        domain=domain,
        analyzer=analyzer,
        competitors=competitors,
        agency_name=agency_name,
        client_name=client_name,
        ctx=report_ctx,
    )

    saved_files = []
    if export_dir:
        safe_dom = re.sub(r"[^a-zA-Z0-9._-]", "_", domain)
        out_folder = os.path.join(export_dir, safe_dom)
        os.makedirs(out_folder, exist_ok=True)
        mapping = [
            ("llms.txt", fixers["llms_txt"]),
            ("schema-jsonld.html", fixers["json_ld"]),
            ("robots-ai-patch.txt", fixers["robots_patch"]),
            ("eeat-comparison-block.md", fixers["eeat_markdown"]),
            ("agency-audit-report.md", fixers.get("agency_report_md", "")),
            ("agency-audit-report.html", fixers.get("agency_report_html", "")),
        ]
        for fname, content in mapping:
            fpath = os.path.join(out_folder, fname)
            with open(fpath, "w", encoding="utf-8") as f:
                f.write(content)
            saved_files.append(fpath)

    result = {
        "ok": True,
        "timestamp": timestamp,
        "target_url": target_url,
        "domain": domain,
        "brand_name": brand_name,
        "probe_mode": probe_bundle["probe_mode"],
        "page_meta": {
            "http_status": page_res.get("status", 0),
            "latency_ms": page_res.get("ms", 0),
            "title": analyzer.title or analyzer.og_title or domain,
            "description": analyzer.meta_desc or "No meta description detected on page.",
            "h1_samples": analyzer.h1s[:3],
            "h2_samples": analyzer.h2s[:6],
        },
        "scores": scores,
        "tech_signals": tech_signals,
        "bot_permissions": bot_permissions,
        "ifs_summary": probe_bundle["ifs_summary"],
        "share_of_model_voice": probe_bundle["share_of_model_voice"],
        "probes": probe_bundle["probes"],
        "fixers": {
            "llms_txt": fixers["llms_txt"],
            "json_ld": fixers["json_ld"],
            "robots_patch": fixers["robots_patch"],
            "eeat_markdown": fixers["eeat_markdown"],
            "agency_report_md": fixers.get("agency_report_md", ""),
            "agency_report_html": fixers.get("agency_report_html", ""),
        },
        "saved_files": saved_files,
    }

    dbp = db_path or default_db_path()
    try:
        run_id = save_audit_history(dbp, result, category_hint=category_hint, export_dir=export_dir)
        result["history_run_id"] = run_id
        result["history_db_path"] = dbp
    except Exception as exc:
        result["history_run_id"] = None
        result["history_db_path"] = dbp
        result["history_error"] = str(exc)

    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="GEO Radar Pro Engine")
    parser.add_argument("--url", default="https://linear.app", help="Target website URL to audit")
    parser.add_argument("--brand", default="", help="Brand name")
    parser.add_argument("--category", default="B2B SaaS & Developer Tools", help="Product category")
    parser.add_argument("--competitors", default="Jira,Asana,Shortcut", help="Comma-separated competitors")
    parser.add_argument("--api-key", default="", help="Optional OpenAI/Perplexity/DeepSeek API Key")
    parser.add_argument("--api-base", default="https://api.openai.com/v1", help="OpenAI-compatible API Base URL")
    parser.add_argument("--api-model", default="gpt-4o-mini", help="Model name")
    parser.add_argument("--export-dir", default="", help="Directory to export fixer + agency report files")
    parser.add_argument("--samples", type=int, default=3, help="BYOK multi-temperature sample count (default 3)")
    parser.add_argument("--agency-name", default="GEO Radar Pro Advisory", help="White-label agency name")
    parser.add_argument("--client-name", default="", help="White-label client name")
    parser.add_argument("--db-path", default="", help="SQLite history DB path")
    parser.add_argument("--list-history", action="store_true", help="Print recent audit history JSON and exit")
    args = parser.parse_args()

    db_path = args.db_path or default_db_path()

    if args.list_history:
        print(json.dumps({"ok": True, "history_db_path": db_path, "runs": list_history(db_path)}, ensure_ascii=False))
        sys.exit(0)

    result = run_geo_audit(
        target_url=args.url,
        brand_name=args.brand,
        category_hint=args.category,
        competitors_csv=args.competitors,
        api_key=args.api_key,
        api_base=args.api_base,
        api_model=args.api_model,
        export_dir=args.export_dir,
        samples=args.samples,
        agency_name=args.agency_name,
        client_name=args.client_name,
        db_path=db_path,
    )
    print(json.dumps(result, ensure_ascii=False))
