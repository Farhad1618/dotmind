# dotmind rendering contract

Every platform package (web today; SwiftUI and Compose next) implements the same four pieces. A port is correct when it produces the same 64 values as the TypeScript reference for the same inputs.

## 1. Activity

```
phase    idle | thinking | tool | writing | waiting | error | done
tool     the tool's name as the model called it (optional)
kind     search | browse | code | file | database | compute | generic
progress characters received so far in this turn (optional, only ever grows within a turn)
```

## 2. Tool classification

Split the name into lowercase tokens on non-alphanumerics and camelCase boundaries (`searchDocs` → `search`, `docs`). Walk the rules in order; the first rule with a token that equals a word, or starts with a word longer than three letters, wins. No match → `generic`. User overrides by exact name take precedence.

Rule order and words: see `packages/dotmind/src/tools.ts` (`RULES`). The order matters: `search` before `database` before `browse` before `code` before `file` before `compute`.

## 3. Scene selection

```
idle → breathe      thinking → comet      writing → type
waiting → halo      error → cross         done → check
tool: search → radar, browse → globe, code → code, file → pages,
      database → stack, compute → prism, generic → circuit
```

## 4. Patterns

A pattern is `f(t, out[64], { energy, progress })`, row-major, (0,0) top-left, values in 0…1.5. Values above 0.85 fade toward white; 1.5 is fully white-hot. `t` is the scene's own clock, starting at 0 when the scene is shown. `progress` is characters received since the scene was shown.

Reference implementations: `packages/dotmind/src/patterns.ts`. The test `every pattern fills 64 finite values in range` is the minimum bar for a port; a golden-frame test (sample each scene at t = 0, 0.5, 1.7, 12.5 with progress 0 and 137) is the parity check.

## 5. Clock and energy

```
on progress p at clock c:
  inst = (p - lastP) / max(1/60, c - lastC)
  rate = 0.7·rate + 0.3·inst
each frame (dt seconds, capped at 0.05):
  if c - lastC > 0.45: rate *= exp(-3·dt)
  target = clamp(0.3 + rate / 160, 0.3, 1.5)
  energy += (target - energy) · (1 - exp(-6·dt))
  scene.t += dt · (0.6 + 0.6·energy)
```

Without progress, writing uses a synthetic progress of 40 characters per second times the same speed.

Scene changes blend over 0.35 s with smoothstep, mixing both values and colours.

## 6. Drawing

Padding 12% of the side, dot radius 34% of the step between dot centres, every dot drawn at 14% alpha in the scene colour, lit dots drawn on top with a glow of `radius · (1.5 + 2.5·w)` where `w = clamp((v - 0.85) / 0.55, 0, 1)`.
