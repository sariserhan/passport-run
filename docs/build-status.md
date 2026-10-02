# Build status — expanded offline prototype

The user's latest instruction authorized continuing beyond the original M0–M2-only first build. [HANDOFF.md](../HANDOFF.md) is now the authoritative continuation document. The primary target is iPhone; Mac/Xcode/device access exists with the user but was unavailable to this Linux session.

| Milestone | Current implementation | Remaining acceptance/work |
| --- | --- | --- |
| M0 Foundation | Godot 4.5.2, portrait, modular scene, configurable resources | Native iPhone launch/performance; no mobile PASS claimed |
| M1 Tile gameplay | Touch-driven jump/landing/crack/fall, results and clean retry | Physical touch comfort and profiling |
| M2 Reveal | Preview timer, one checked safe tile per row, hiding, unchanged path | Human readability and memory-load testing |
| M3 Difficulty | Easy/Moderate/Hard presets and menu, separate local records | Competitive leaderboard segregation when backend exists |
| M4 Infinite | Random-access seeded generation, bounded row sections, same-path retry | Device memory/FPS testing; final preview-loop playtest |
| M5 Countries | Five procedural placeholder variants; completion and stamp award | Production art/animation and richer transition sequence |
| M6 Home/route | Explicit searchable home choice, configurable demo graph preference, choices | Geographic dataset beyond demo; optional active-run persistence |
| M7 World Tour | Complete five-country non-repeating journey, choices, totals, failure | Region badges, production travel transitions, validation |
| M8 Passport | Unique stamps, history and local persistence | Artwork polish and eventual sync |
| M9 Daily | Deterministic UTC start/route/path per difficulty; local bests | Backend manifests and authoritative date/rankings |
| M10 Leaderboards | Honest local records screen only | Auth/session handling, submissions, replay validation, real boards |
| M11 Ads | Not implemented | Provider, callbacks, frequency, checkpoint continue and fallback |
| M12 Purchases | Not implemented | Product setup, verified purchase/restore and sync |
| M13 Kids | Simpler slower paths, friendly failure, no sharing/profile/chat | Kid-friendly character, verified facts/stickers, device review |
| M14 Audio/polish | Original synthesized music/cues, volumes, pause/resume, accessibility | Listening QA, polished art/animations/production audio |
| M15 Challenges | Validated portable seeded route codes and manual import | Public links, hosting, native opening, verified comparison |
| M16 Share cards | Real local 720×1000 PNG + clipboard code | Character/backdrop art, native iPhone share sheet |
| M17 Analytics | Bounded local event log + summary script | Complete event coverage, remote retention/funnel dashboard and player study |

## Verification

Four headless suites pass: original core (1,143 checks), scene (149), progression (3,487), and modes (346 or more depending on destination option counts). Tests use isolated save files. Corrupt-save recovery, finite/random-access parity, daily identity, invalid challenge data, whole-tour completion, unique passport stamps, records, infinite streaming and retries were exercised.

Rendered mode tests passed at 480×900, 390×844 and 375×667. Share-card creation and dimensions were validated in rendered runs. Final 480×900 render exited without script, texture, or object-leak errors; the virtual display reports an expected unsupported-VSync warning. The test runtime uses Mesa software rendering and is not performance evidence for an iPhone.

Screenshots were visually inspected for menu overflow, preview row visibility at each difficulty, country cues, completion actions, passport and record layouts, Kids rewards, and the exported card. Temporary art deliberately falls short of the reference images' final fidelity.

Fixed during this iteration: corrupt JSON logging noise, malformed challenge handling, difficulty-dependent camera fit, resource teardown warnings, single-country grammar, and inability to leave a ready screen using the pause control.

## Deferred decisions

- Keep the five-country validation scope; do not respond to poor retention by adding 195 environments.
- Infinite currently reveals a fresh section after each section is crossed; retries always start at row 1 with the same route. Confirm this loop with players.
- Current active runs are not resumed after process termination; earned stamps/preferences/local records persist.
- Daily and challenge data are local and unverified. No online rank or percentile claims are shown.
- UI shows 5 available passport destinations, not a misleading 195-country playable count.
- All path/route/balance versions must be preserved when online competition and migrations are added.
