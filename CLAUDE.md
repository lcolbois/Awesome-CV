# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A LaTeX-based job application system built on the [Awesome CV](https://github.com/posquit0/Awesome-CV) template. It manages multiple tailored CVs and cover letters for different job applications.

See `.context/main_context.md` for the applicant's background, target roles, and application strategy.

## Build Commands

```bash
make app ID=<app_id>               # Build CV (and cover letter if cl.tex exists) for one app
make all                           # Build all applications
make base                          # Build _base/ canonical template (smoke test)
make new ID=<company_role>         # Scaffold a new application from _base
make new ID=<company_role> FROM=<existing_id>  # Fork from an existing application
make check                         # Check all apps for unfilled placeholders / copy-paste hazards
make check ID=<app_id>             # Check one application
make diff ID=<app_id>              # Diff an app's content sections against _base
make list                          # List available application IDs
make cleantemp                     # Remove auxiliary files, keep PDFs
make clean                         # Remove all build folders
```

Output PDFs land in `applications/<app_id>/build/`.

The build uses LuaLaTeX via `latexmk`. Direct compile: `cd applications/<app_id> && latexmk -pdf -lualatex cv.tex`.

## Repository Structure

```
_base/               # Canonical template — fork this for every new application
  meta.tex           # THE ONLY FILE TO EDIT PER APP (company, title, position, recipient)
  cv.tex             # Boilerplate — do not edit, reads meta.tex
  cl.tex             # Boilerplate with commented variant blocks — do not edit, reads meta.tex
  summary.tex        # Canonical (base) content for each section
  experience.tex
  skills.tex
  education.tex
  publications.tex
  awesome-cv.cls -> ../awesome-cv.cls   (symlink)
  profile.jpg    -> ../profile.jpg      (symlink)

applications/<id>/   # One self-contained folder per job application
  meta.tex           # Company/position/title/recipient — the only per-app identity file
  cv.tex             # Identical to _base/cv.tex (boilerplate)
  cl.tex             # Identical to _base/cl.tex with variants selected/filled
  summary.tex        # App-specific tailoring (forked from _base)
  experience.tex     # App-specific tailoring (forked from _base)
  skills.tex         # App-specific tailoring (forked from _base)
  education.tex      # Usually identical to _base; copy only to translate/customize
  publications.tex   # Usually identical to _base
  offer.md           # Job description for reference
  awesome-cv.cls -> ../../awesome-cv.cls   (symlink)
  profile.jpg    -> ../../profile.jpg      (symlink)

shared/              # LEGACY — used by the 14 pre-restructure applications, do not modify
```

## The meta.tex Model

Every application-specific header field lives in `meta.tex`:

```latex
\newcommand{\appCompany}{Cisco Systems}
\newcommand{\appJobTitle}{Machine Learning Engineer}
\newcommand{\appPosition}{Applied ML Engineer{\enskip\cdotp\enskip}PhD in ML \& Biometrics}
\newcommand{\appQuote}{}                      % empty = no quote rendered
\newcommand{\appRecipientName}{Hiring Team}
\newcommand{\appRecipientAddress}{Cisco\\Address\\City}
\newcommand{\appLetterOpening}{Dear Hiring Team,}
```

`cv.tex` and `cl.tex` are identical boilerplate in every application — they must not be edited. The cover letter body (variant blocks) is the only part of `cl.tex` that gets customized per application.

## Propagating CV Improvements Forward

This repo has **no live single source of truth for bullet wording** — each application tailors its own copy, and submitted applications are frozen. Improvements propagate *forward only*:

1. When you improve a bullet in an app and want to generalize it, paste it into `_base/<section>.tex`.
2. Future `make new` forks will inherit the improvement automatically.
3. `make diff ID=<app>` shows what an existing app diverged from `_base` — useful for deciding what to promote back.

## Cover Letter Variants

`cl.tex` contains commented-out variant blocks. When writing a cover letter:
1. Uncomment the variant(s) most relevant to the role (Variant A = environmental/mission, B = tech/engineering, C = geographic, D = deep CV/VLM)
2. Fill in the `SPECIFIC REASON`, `SPECIFIC DOMAIN`, etc. placeholders
3. Run `make check ID=<app_id>` to confirm no placeholders remain

## Safety Checks

- **Build banner** — when building a new-style app (one with `meta.tex`), the build prints `Building CV: <company> / <job title>` so a wrong company name is immediately visible in the log.
- **`make check`** — scans for leftover placeholders (`COMPANY NAME`, `JOB TITLE`, `*** CUSTOMIZE`, etc.) and warns if the company name in `meta.tex` doesn't appear in `offer.md` (copy-paste guard).

## Python / Job Scraping

`pixi` manages a Python 3.10 environment with `python-jobspy` for scraping job listings. The notebook is at `jobhunt/scraping.ipynb`.

```bash
pixi run jupyter notebook
```
