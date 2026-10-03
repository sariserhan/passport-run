# Traveler animation assets

The 24 travelers have two generated motion atlases, each with six columns and twelve rows. Human rows follow the original travelers atlas order; animal/space/fantasy rows follow the fantasy travelers atlas order. Columns are walk A, walk B, jump, landing, victory and falling. Original idle portraits remain available; the classic explorer and Kids robot retain their established animation implementation.

- `assets/realistic/travelers-motion.png`
- `assets/realistic/fantasy-travelers-motion.png`
- `resources/traveler-motion.json`: measured absolute alpha bounds for all 144 poses.
- `tools/measure_traveler_motion.gd`: repeatable bounds measurement, excluded from app exports.

The images were generated using the original character atlases as identity references. The prompt requested exactly six columns and twelve rows, one original character per row in reading order, distinct articulated full-body poses facing right, preserved outfits and accessories, transparent margins, a shared scale/baseline per row, and no labels, scenery or borders. Specific directions asked for alternating fox tails, opening dragon wings, and a tucked floating astronaut jump. Generated art can vary slightly between poses.

`CharacterStyle.motion_texture` crops each measured pose. Its standing walk height sets the scale for the whole character, and the renderer anchors the bottom to the floor. Jumping uses jump/landing textures on the existing jump trajectory; arcade uses alternating walk textures while moving, a victory texture after a clear, and a falling texture on a hit. Animation changes are cosmetic and do not alter collision, route, scoring or timing rules. The astronaut has additional cosmetic hover while thinking/jumping. Reduced Motion disables cycling and decorative motion while retaining static action poses. Pause freezes character animation clocks.

Tests cover atlas bounds, pose transitions, pause/Reduced Motion, and the earned reward/room/quest/album flow. Rendered phone-size fixtures are under `artifacts/rewards-*`.
