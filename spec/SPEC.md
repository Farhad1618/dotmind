# dotmind rendering contract

Every platform package (web today; SwiftUI and Compose next) implements the same four pieces. A port is correct when it produces the same 64 values as the TypeScript reference for the same inputs.

## 1. Activity

```
phase    idle | thinking | tool | writing | waiting | error | done
tool     the tool's name as the model called it (optional)
kind     search | browse | code | file | database | compute | translate | deploy | debug | generic
progress characters received so far in this turn (optional, only ever grows within a turn)
```

## 2. Tool classification

Split the name into lowercase tokens on non-alphanumerics and camelCase boundaries (`searchDocs` → `search`, `docs`). Walk the rules in order; the first rule with a token that equals a word, or starts with a word longer than three letters, wins. No match → `generic`. User overrides by exact name take precedence.

Rule order and words: see `packages/dotmind/src/tools.ts` (`RULES`). The order matters: `search` before `database` before `browse` before `code` before `file` before `compute` before `translate` before `deploy` before `debug`. The last three were appended so every name classified before keeps its kind:

```
translate  translate translation translator i18n localize localise locale
deploy     deploy deployment release publish rollout ship kubectl helm
debug      debug debugger breakpoint stacktrace traceback inspect
```

Default labels: `Translating`, `Deploying`, `Debugging`.

## 3. Scene selection

A state's scene key is the phase name, or `tool:<kind>` for the tool phase (`tool:generic` when the kind is missing). The scene is the first match of:

1. the `scene` option (one scene for every state),
2. the `scenes` override map, keyed by scene key,
3. the look's table,
4. the classic table.

An unknown look falls back to `classic`.

Classic table:

```
idle → breathe      thinking → comet      writing → type
waiting → halo      error → cross         done → check
tool: search → radar, browse → globe, code → code, file → pages,
      database → stack, compute → prism, translate → glyph,
      deploy → rocket, debug → bug, generic → circuit
```

Looks (only the differences from classic):

| look | scenes | shape | aura |
|---|---|---|---|
| `classic` | none | dot | off |
| `icons` | thinking → neural, done → verified, tool:search → magnifier, tool:translate → glyph, tool:compute → sort, tool:deploy → rocket | dot | on |
| `pixel` | tool:debug → bug, tool:code → blocks, tool:search → scan | square | off |

`shape` and `aura` options override the look's defaults.

## 4. Patterns

A pattern is `f(t, out[64], { energy, progress })`, row-major, (0,0) top-left, values in 0…1.5. Values above 0.85 fade toward white; 1.5 is fully white-hot. `t` is the scene's own clock, starting at 0 when the scene is shown. `progress` is characters received since the scene was shown.

Reference implementations: `packages/dotmind/src/patterns.ts` (classic scenes and the `PATTERNS` registry), `icon-patterns.ts` (neural, magnifier, glyph, sort, rocket, verified) and `pixel-patterns.ts` (bug, blocks, scan); shared helpers in `grid.ts`. Discrete steps use `floor` and step lengths chosen so the golden sample times never land on a step boundary. The test `every pattern fills 64 finite values in range` is the minimum bar for a port; a golden-frame test (sample each scene at t = 0, 0.5, 1.7, 12.5 with progress 0 and 137) is the parity check.

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

Padding 12% of the side; `step` is the distance between cell centres. Every cell is drawn at the shape's base alpha in the scene colour, then lit cells (v ≥ 0.03) on top with alpha `clamp(v, 0, 1)`, colour mixed toward white by `w = clamp((v - 0.85) / 0.55, 0, 1)`, size grown by `1 + 0.12·w`, and a glow (blur) of `half · (1.5 + 2.5·w)` where `half` is half the cell size.

| shape | cell size | corner radius | base alpha |
|---|---|---|---|
| `dot` | circle, diameter 0.68 · step (radius 0.34 · step) | n/a | 0.14 |
| `square` | rounded square, side 0.8 · step | 0.22 · side | 0.20 |

Aura (pill only, or the matrix well when bare): a soft glow in the current scene colour behind the indicator, two layers `0 0 24px -6px` at 55% and `0 0 72px 8px` at 20% alpha. The colour follows the scene and cross-fades over 0.35 s, the same as the matrix blend.

## 7. Parity fixture

`spec/golden.json` is generated from the TypeScript reference by `node scripts/golden.mjs [output path]` (after `npm run build`). Every port loads it in its tests and must match within `tolerance`:

- `frames`: each scene sampled at `t` ∈ {0, 0.5, 1.7, 12.5} and `progress` ∈ {0, 137}, energy 0.8.
- `tools`: tool name → kind.
- `scenes`: activity → scene and default English label (classic look).
- `looks`: every scene key × every look → scene and default English label, with no overrides.
- `energy`: a renderer created on scene `type`, `feed(0)`, then for frame `i` in 0…239: `step(1/60)`; if `i < 120`, add 1 (i < 60) or 8 (otherwise) to progress and `feed` it; after every 20th frame record `level` and `sample()`.

Numeric rules ports must follow to match: compute in 64-bit floats; round with `floor(x + 0.5)` (JavaScript `Math.round`), never banker's rounding or round-half-away-from-zero; `%` on possibly negative numbers uses `((a % n) + n) % n`; `hash(i, s) = fract(sin(i·127.1 + s·311.7) · 43758.5453)` with `fract(x) = x - floor(x)`.
