# AGENTS.md

Read this file before every response in this repository.

## Project

BetterRaidInfoFrame is a small World of Warcraft Classic addon. Keep it that way.

## Working Style

- Keep changes small, boring, and easy to review.
- Do not refactor unrelated code while fixing a bug.
- Prefer existing addon patterns over new abstractions.
- Treat Blizzard UI APIs and embedded libs as the boundary; do not invent wrappers unless they pay rent.
- Be blunt in code review: lead with bugs, risks, and missing checks.
- Do not burn tokens explaining obvious Lua.

## Code Rules

- Target Lua used by WoW Classic MOO addons.
- Keep globals intentional. Localize addon internals.
- Guard optional UI objects and saved handlers before calling them.
- Do not remove LibQTip spacing/layout mechanics unless you test the frame visually in game.
- Keep TOC/library/package changes separate from behavior changes when practical.

## Validation

- Run `luacheck BetterRaidInfoFrame.lua` after Lua edits when available.
- LuaCheck warnings for known Blizzard globals are acceptable unless the changed code introduces new ones.
- If in-game verification is needed but not possible, say so plainly.

## Git

- Do not revert user changes.
- Do not run destructive git commands unless explicitly asked.
