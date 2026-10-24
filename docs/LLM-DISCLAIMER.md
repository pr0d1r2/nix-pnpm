# Built by an LLM, in the open

This repository (code, spec, tests and prose) was written by
[Claude Code](https://claude.com/claude-code) running Anthropic's Claude
Opus 5.5, working from the owner's decisions. Every commit carries a
`Co-Authored-By: Claude Opus 5.5` trailer; compare
`git log --format=%B | grep -c Co-Authored-By` with
`git rev-list --count HEAD`. A human owns every decision and is
accountable for what ships.

## Why say it at all

An LLM writes plausible code, and plausible is not correct. A reader who
does not know how a repository was produced cannot calibrate how hard to
look at it.

## What keeps it checkable

- **A written spec.** `SPEC.md` and its nodes record each decision with
  its date and who made it. Where the owner amended an earlier decision,
  the old rule stays, marked as superseded.
- **Measurements, not memory.** Versions, hashes, sizes and failures in
  the spec were measured on the date given, with the command named. The
  prompt that started this repository claimed the pinned nixpkgs had no
  pnpm 12; measuring showed it had 12.9.0, and the spec says so.
- **A gate laid before the product code**, one check per commit, each
  shown refusing a planted violation in its commit body or in its
  upstream test suite.
- **Tests before scripts.** Every script's bats test landed first and
  failing; the history shows each red and green pair.
- **Hashes from upstream.** Every asset hash is GitHub's own digest,
  checked against a download, so a reader can verify the binaries
  without trusting this text.

## The defect record

Bugs found after the gate was green go into `SPEC.md` §B, each with the
invariant added so it cannot recur. Count them with
`grep -c '^B[0-9]' SPEC.md */SPEC.md`.

## What to watch for

The agent can be confidently wrong. If something here does not match
what you see, believe what you see and open an issue.
