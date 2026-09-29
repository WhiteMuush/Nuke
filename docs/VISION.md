# Nuke — Vision

Chaos engineering that gives you a **verdict**, with **zero configuration**,
and always heals itself.

Nuke turns "let's break something and see" into "prove this service survives
the failure, on every deploy." It is built for **teams** running real services,
not for one-off demos.

---

## Why teams don't do chaos engineering (the problem)

Two things stop teams, and Nuke is designed to remove both:

1. **Fear.** "I'll break something and won't be able to undo it." Nuke answers
   this with guardrails: a required scope, automatic rollback, a hard duration
   cap, a typed confirmation for the all-out level, and a Ctrl+C that heals
   before it exits.

2. **Effort.** Existing tools make you write YAML CRDs, pick fault parameters,
   wire probes, and read raw output to judge the result. That friction means
   chaos stays a rare, manual event instead of a habit.

Nuke's bet: remove the effort, and chaos becomes something a team does
continuously, like running tests.

---

## The core principle: simplicity

**The user points and validates. Nuke discovers, proposes, and runs.**

The user should almost never have to configure anything by hand:

- Nuke **discovers targets** on its own (namespaces, deployments, services,
  containers, interfaces) and offers them in a menu.
- The **steady state is derived from the target itself.** In Kubernetes,
  "healthy" defaults to "the Deployment keeps its replicas ready and the
  Service keeps endpoints." No health URL to write, and it works for any target.
- **Sane defaults** everywhere (success threshold, recovery window), always
  overridable, never required.

Configuration is an escape hatch for power users, not the price of entry.

---

## The workflow that makes a team need Nuke

The same discipline every developer already trusts, "a failing test for every
bug," applied to reliability:

1. An incident happens (a payments pod is rescheduled during a node upgrade,
   checkout falls over).
2. In Nuke you pick the target and the fault. Nuke builds the experiment and
   runs it. It comes back **red**: the weakness is proven.
3. The team fixes it (a PodDisruptionBudget, a retry, a timeout).
4. The experiment now comes back **green**, and it **stays in CI forever.**
5. The next node upgrade causes no incident. The outage never silently returns.

That is a recurring, measurable need for every team that runs services.

---

## What an experiment is

An experiment answers one question: *does the system hold when this fault
hits?* It has four parts, and Nuke fills in as much as it can:

- **Target** — which layer and scope. Chosen from a discovered list.
- **Steady state** — what must stay true. Auto-derived from the target by
  default (e.g. replicas stay ready), overridable with a custom probe.
- **Fault** — what to inject, at an intensity on the `POKE → NUKE` ladder.
- **Verdict rule** — an outage budget and a recovery window, both defaulted.

### The run

1. Check the system is healthy **first** (abort if it is already unhealthy).
2. Start probing the steady state on an interval, recording pass/fail.
3. Inject the fault at the chosen intensity, for its capped duration.
4. Keep probing through and after the fault, up to the recovery window.
5. Emit a **verdict**: `RESILIENT` if the system recovered and its worst
   continuous outage stayed within the budget, otherwise `WEAK SPOT`, with the
   numbers. The outage is measured on the clock, not by counting samples, so the
   verdict is stable run to run.
6. Exit `0` or `1` so CI can gate on it.

### The saved file (generated, not hand-written)

After a run, Nuke saves the experiment so it can be replayed. The file is an
**output** of the interactive flow, not something the user authors:

```
NAME=checkout-node-drain
LAYER=kubernetes
TARGET=deploy/checkout -n payments
FAULT=pod-kill
INTENSITY=HAVOC
# steady state and thresholds are auto-filled; override only if you want:
# MAX_DOWNTIME=5
# RECOVER_WITHIN=30
```

It commits into the repo under `experiments/`, versioned with the app, which is
what makes the CI gate possible.

---

## What makes Nuke a team tool

- **The CI gate.** `nuke run checkout-node-drain` runs headless, exits pass or
  fail. Resilience becomes a merge condition, like tests.
- **The report.** Every run produces a shareable summary (expected steady
  state, what was injected, recovery time, proof of rollback). It attaches to a
  PR, a post-mortem, or an SRE review.
- **The GameDay.** Chain several experiments in sequence, record the timeline,
  produce one report for the team. Today GameDays are run by hand with kubectl
  and a spreadsheet.
- **Trust at scale.** Scope guardrails so nobody hits the wrong namespace, an
  audit log of who ran what and when, and a guaranteed rollback. This is what
  lets a team run it without holding its breath.

---

## Roadmap

Ordered so each step stands on the previous one.

1. **Verdict engine.** Auto-derived steady-state probe + fault + verdict, inside
   the existing TUI. The single most valuable piece: Nuke stops just breaking
   things and starts telling you whether you survived.
2. **Save + replay.** Persist an experiment (generated `.exp`) and run it
   headless with `nuke run <name>`, pass/fail exit code.
3. **Report.** A shareable artifact per run.
4. **GameDay.** Sequenced experiments with a combined timeline and report.
5. **Pluggable steady state (v2).** Keep the same verdict engine, add
   Prometheus (PromQL vs a threshold) as an optional steady-state source.
6. **Wire the beta layers.** Bring Docker, Network and Host up to the same
   verdict-backed standard as Kubernetes.

---

## Non-goals

- Not competing with Gremlin or AWS FIS on cloud, SaaS, enterprise ground.
  Nuke owns local and self-hosted chaos with a verdict, replayable in CI.
- No configuration sprawl. If a user has to hand-write scopes, probes and
  thresholds to get value, the tool has failed its core principle.
- No mandatory external dependency for the basics. The portable path (a probe
  that exits `0`) must always work; richer sources are optional add-ons.
