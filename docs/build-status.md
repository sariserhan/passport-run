# Build status — 2026-10-02

The five-country game is a playable prototype. Online competition now works against a real local Convex instance; no hosted service or commercial release is claimed. [HANDOFF.md](../HANDOFF.md) contains continuation instructions.

| Milestone | Implemented | Remaining acceptance/work |
| --- | --- | --- |
| M0–M2 Foundation/gameplay/reveal | Portrait Godot, touch movement, jumps/falls, results/retry, timed hidden paths | Physical iPhone touch, readability, FPS and thermal testing |
| M3 Difficulty | Three immutable presets, segregated local and server boards | Human balance testing |
| M4 Infinite | Bounded tile windows, random-access generation, same-path retry, verified online submissions | Device profiling, final memory-loop validation |
| M5 Countries | Five detailed matte-painted destinations, rounded 3D stone paths, stamps, illustrated travel with skip/pause | Dynamic scenery/parallax and fully rigged character animation |
| M6 Home/route | Searchable explicit home, demo graph and long-haul choices | Curated geography; optional active-run persistence |
| M7 World Tour | Five non-repeating destinations, totals, travel, collection badge | Real regional rewards after geographic expansion |
| M8 Passport | Durable local stamps/history, sticker album, online discovery union | Account recovery and broader sync policy |
| M9 Daily | Offline deterministic Daily plus authenticated canonical server manifests, pinned retries | Hosted deployment and device integration |
| M10 Leaderboards | Replay reconstruction, authenticated ownership, atomic personal bests, sanitized segregated boards, Godot client | Hosted validation, abuse prevention, account linking |
| M11 Ads | Unimplemented | Provider setup and verified rewards/continuation |
| M12 Purchases | Unimplemented | Store product, transaction verification and restoration |
| M13 Kids | Slower paths, robot explorer, verified facts and illustrated stickers | Device/human/parental review |
| M14 Polish | Illustrated backpacker/menu, licensed display type, prototype audio, pauseable travel, safe-area scrolling, reduced motion/high contrast | Full skeletal character animation, device visual/performance and listening/haptics QA |
| M15 Challenges | Validated local PR1 codes and identical-path replay | Hosted links and native link handling |
| M16 Share cards | Illustrated 720×1000 PNG and clipboard code | Native iPhone share sheet |
| M17 Analytics | Local bounded events, session/run timing and scoped funnel report | Consent-aware remote analytics and real retention/revenue study |

## Verification

Seven headless Godot suites passed: core 1,143; scene 156; progression 3,487; modes 364 or more depending on route choices; mobile UI 20; polish 16; animations/timer 36. Python reporting checks passed (3). Rendered mode tests passed at 375×667 and 390×844; mobile dialogs were also checked down to 320×568. Illustrated cards and Kids rewards were inspected. Desktop rendering does not establish iPhone performance.

Backend typecheck and 151 tests passed. Tests cover Godot-generated compatibility fixtures, ownership, revoked sessions, malformed and impossible replays, score reconstruction, duplicate submissions, passport isolation, and retry manifests across midnight. Real local HTTP smoke tests exercised sign-in, submit, board, sync, refresh and sign-out. Godot's real-backend integration suite passed 19 checks, including actual in-game verified score display. These use development users, not customer evidence.

See [iPhone validation](iphone-validation.md) for native export/build status. Keep the five-country validation scope from spec section 91. Active runs do not resume after process termination. Client replay verification does not establish human play or prevent automated bots. Online playback is opt-in; the default exported game stays offline.

The latest reference graphics pass is documented in [visual assets](visual-assets.md). The 3D tiles remain interactive; the scenery and main backpacker are illustrated assets. Native export includes the new art/font. Earlier device-lock and human-validation limitations still apply.

The latest requested thinking/jump/fall/celebration/pocket/passport/stamp sequence is implemented with a 16-pose atlas and pauseable passport animation. New balance-v2 runs add a 10-second decision clock per playable row; legacy challenge and ranked rules remain versioned. Rendered animation checks passed (36), and a real online timeout/score submission passed.
