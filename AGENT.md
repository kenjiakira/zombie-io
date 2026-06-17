# AGENT Instructions

This file tells AI how to work in this project without drifting away from the intended structure.

## 1. Read First

Before changing code, read:
- `GAME_ARCHITECTURE.md`
- `docs/CONCEPT.md`

These two files define the current technical layout and the game direction.

## 2. Default Coding Rules

- Keep changes small and targeted.
- Preserve the current scene-driven Godot structure.
- Prefer data-driven content over hardcoded behavior.
- Put orchestration in managers or core scripts.
- Keep entity logic inside the entity scene/script.
- Avoid unrelated refactors when fixing or adding one feature.

## 3. Project Direction

ZombieIO is a hybrid survival game, not just a zombie shooter.
When adding features, prefer systems that support:
- combat
- scavenging
- extraction
- progression
- defense
- crafting

## 4. Architecture Rules

- `Main` should coordinate systems, not own all gameplay logic.
- Managers should handle one domain each.
- UI should display state and emit signals.
- Data scripts should store balance values and configuration.
- Scenes should own their own behavior.

## 5. Implementation Priorities

When adding new gameplay, follow this order:
1. Make it playable.
2. Make it clear.
3. Make it data-driven if possible.
4. Add polish only after the loop works.

## 6. Safety Rules

- Do not overwrite user changes unless asked.
- Do not introduce large architectural rewrites casually.
- Keep new dependencies minimal.
- If a feature touches multiple systems, update the architecture doc only if the change is real and lasting.

## 7. Useful Output Style

When coding, prefer:
- readable names
- explicit signals
- simple control flow
- small helper functions
- comments only where intent is not obvious

## 8. Feature Checklist

Before finishing a change, check:
- Does it fit the hybrid survival concept?
- Does it preserve fast combat?
- Does it avoid bloating the codebase?
- Does it work with the current scene and manager structure?

## 9. Working Principle

If the task is ambiguous, choose the option that keeps the game smaller, cleaner, and easier to expand later.

