---
version: alpha
name: Athens Transit Map Sheet
description: Home screen of the Athens Transit Android app - full-screen map, one bottom sheet grouped by stop, menu top left (direction C, "stop list").
colors:
  primary: "#1A56C4"
  on-primary: "#FFFFFF"
  surface: "#FFFFFF"
  ink: "#16181A"
  muted: "#6B7177"
  faint: "#8A9097"
  pill-bg: "#F1F3F6"
  rule: "#F0F1F3"
  outline: "#CFD6E0"
  me-dot: "#1A73E8"
  scrim: "#00000073"
typography:
  section-tab:
    fontFamily: Roboto
    fontSize: 15px
    fontWeight: 700
    lineHeight: 1.2
  stop-name:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.2
  stop-kind:
    fontFamily: Roboto
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.3
  pill-line:
    fontFamily: Roboto
    fontSize: 13px
    fontWeight: 700
    lineHeight: 1
  pill-minutes:
    fontFamily: Roboto
    fontSize: 15px
    fontWeight: 700
    lineHeight: 1
  smart-minutes:
    fontFamily: Roboto
    fontSize: 26px
    fontWeight: 800
    lineHeight: 1
  smart-title:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.2
  menu-item:
    fontFamily: Roboto
    fontSize: 16px
    fontWeight: 600
    lineHeight: 1.3
rounded:
  sheet: 20px
  search: 24px
  smart-card: 14px
  pill: 16px
  walk: 18px
  fab: 999px
spacing:
  gutter: 16px
  stop-gap: 8px
  pill-gap: 6px
  touch: 48px
components:
  sheet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.sheet}"
  search-bar:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.muted}"
    rounded: "{rounded.search}"
    height: 48px
  smart-card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
    rounded: "{rounded.smart-card}"
    padding: 12px
  smart-card-minutes:
    textColor: "{colors.primary}"
    typography: "{typography.smart-minutes}"
  line-pill:
    backgroundColor: "{colors.pill-bg}"
    textColor: "{colors.ink}"
    rounded: "{rounded.pill}"
    height: 32px
  walk-button:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.primary}"
    rounded: "{rounded.walk}"
    height: 36px
  map-fab:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.me-dot}"
    rounded: "{rounded.fab}"
    size: 48px
  drawer:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
  drawer-scrim:
    backgroundColor: "{colors.scrim}"
  stop-divider:
    backgroundColor: "{colors.rule}"
  tab-active:
    textColor: "{colors.ink}"
  tab-idle:
    textColor: "{colors.faint}"
refs:
  - bm2: Busmate, App Store screenshot 2 - nearby stops grouped by stop, line badges with minutes, walking time (docs/design-home-refs/bm2.png)
  - bm4: Busmate, App Store screenshot 4 - one stop, rows of lines with times (docs/design-home-refs/bm4.png)
  - mv3: Moovit, App Store screenshot 3 - map with a half-open sheet "Nearby stops / Favourites" (docs/design-home-refs/mv3.png)
---

# Athens Transit Map Sheet

## Overview

One screen: the map fills the phone, a bottom sheet sits half open over it, a
search bar with a menu button floats on top. No bottom navigation bar. Everything
the user taps (stop, vehicle, line) opens inside the same sheet. The sheet answers
"what comes near me and when" without any gesture. Built for people who are not
technical, including older users: nothing important hides behind a swipe.
Direction C, "stop list": the list is grouped by stop, not by line. [ref: bm2]

## Colors

White surfaces, near-black text, one blue accent (`primary`) for actions and the
smart card. Colour otherwise appears only on line badges, which use each line's
own colour (from the API) with white text, or dark text on yellow lines. No other
decorative colour. [ref: bm2] Never emoji anywhere: every icon is SVG (agent rule
from Harold, 2026-10-29).

## Typography

Roboto (Android system). Minutes are the biggest text in every row: the user
asks "when", so the answer is the largest thing (P0 finding of the UX audit).
Stop names 16px bold; the stop kind ("στάση λεωφορείων", "σταθμός μετρό") 12px
grey under the name replaces any icon.

## Layout

- **Top:** search bar, 16px from the edges, menu button (three lines) inside it on
  the left. Placeholder "Στάση, γραμμή ή μέρος". No profile button.
- **Sheet, half open (default):** two text tabs "Κοντά σου" / "Αγαπημένα" (star
  icon), then the smart card, then the stop groups. [ref: mv3]
- **Smart card** (one at a time, by time and place): weekday 06:00-10:00 at home
  → "Πάμε δουλειά"; away from home → "Γυρνάς σπίτι"; from 19:00 → the evening
  "Τελευταία για σπίτι" section; otherwise the next favourite line. Places come
  from «Μέρη» (saved places, any number; Σπίτι and Δουλειά are two of them).
- **Κοντά σου:** first the nearest bus stop that serves the user's lines, then the
  nearest rail station (metro, suburban or tram). Two separate groups even when
  they share a name. More stops appear when the sheet is dragged up, and a text
  hint "σύρε για περισσότερες στάσεις" says so. [ref: bm2]
- **Stop group:** name + kind on the left, walk button on the right; below, a row
  of line pills (badge + minutes) that wraps. No square or pin icon before the
  name. [ref: bm4]
- **Walk button:** walking-person SVG + minutes. Tapping it opens Google Maps
  walking directions to the stop (geo intent with `mode=w`).
- **Sheet down (collapsed):** map takes the screen; only then the two map buttons
  appear on the right, above the sheet: layers, and "πού είμαι". The smart card
  stays visible in the collapsed sheet.
- **Menu (drawer from the left):** Γραμμές (all lines in detail), Ενημερώσεις,
  Ειδοποιήσεις, Μέρη, Widgets, Στατιστικά, Ρυθμίσεις (theme etc.), Σχετικά.
- **Back:** every sheet level has "‹ Πίσω" (named after the previous level when
  known, e.g. "‹ Σύνταγμα") and "✕". System back pops one level; "✕" or a tap on
  empty map clears the stack. From the home level, back leaves the app. One sheet
  level at a time, never a sheet over a sheet.
- **Ενημερώσεις:** when there is an active alert, an info badge shows in the search
  bar; an urgent one (strike) shows as a strip on top of the map at launch.

## Shapes

20px sheet corners, fully rounded search bar, pills and map buttons. The walk
button is an outlined pill (1.5px `outline`) so it reads as a button.

## Motion

Keep the five vault defaults: 200ms ease-out for sheet level changes, 150ms for
pill/press feedback, map buttons fade in 150ms when the sheet collapses and fade
out when it rises, no bounce, honour the system "remove animations" setting.

## Do's and Don'ts

- Do keep minutes the largest text in every row.
- Do give every tap target at least 48px.
- Don't hide a needed action behind a swipe; offer a button too.
- Don't use emoji or decorative icons; text labels beat icons for older users.
- Don't merge a bus stop and a rail station into one group.

## Decisions

- harold: direction C (stop list) over A (colour rows) and B (quiet map), 2026-10-29.
- harold: no bottom navigation bar; menu top left; no profile button.
- harold: no square icons before stop names; kind text instead.
- harold: walk button opens Google Maps walking directions.
- harold: "πού είμαι" and layers only when the sheet is down.
- harold: «Μέρη» replaces Σπίτι/Δουλειά; "Πάμε δουλειά" card yes (2026-10-30).
- agent: back stack per sheet level, labelled back button; from the UX discussion.
- agent: kept the layers button (only place to change what the map shows).
- agent: «Διαδρομή» (the planner) is the first menu item: it had its own tab, and no feature may be lost (2026-10-30).
- agent: the walk button sends `google.navigation:q=…&mode=w`; without the Maps app it opens the web directions page.
- agent: «Αγαπημένα» tab: saved stops as stop groups and my lines; a link opens the full page (add a stop, mark home/work, the evening last bus).
- agent: at a near bus stop only my lines get minutes; the other lines show as badges (live minutes exist only for the ≤5 watched lines). The distance stays beside the kind text.
- agent: smart card without «Σπίτι» and without favourites asks where home is (kept from the old card). «Ενημερώσεις» is a note page with no badge until rt#43.
- agent: with "only my lines" (layers sheet), «Κοντά σου» lists those lines instead of stops, as before.

Agents: read this file before you change the home screen; write a `## Decisions` line for any rule you change.
