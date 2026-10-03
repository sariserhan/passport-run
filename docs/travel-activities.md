# Travel activities batch

All activities are local to the existing profile. Open **More adventures & creative tools** or **Departure lounge** from the main menu. Existing route purchases and destination access checks apply to every optional route. Memory-path rules and Balloon Tour's fatal first collision remain intact.

| Feature | Player behavior |
| --- | --- |
| Country arrivals | Travel transitions show destination scenery, a welcome/fact, the selected buddy and chosen weather. Destination music comes from the existing generated soundtrack system. The arrivals gallery previews any free country and its soundtrack. |
| Interactive souvenirs | Tap a room keepsake or open Living souvenirs to reveal its story/fact, animate it and hear its collection sound. |
| Buddy adventures | Pip visits JP/IS/ID, Orbit visits FR/US/JP, Ember visits NO/FI/CA. Complete the stops with that buddy equipped to earn a visible accessory. |
| Room interactions | Switch lamps, sit in an earned armchair, and wake/rest a buddy in its bed. These choices persist. |
| Travel scrapbook | Create, edit and delete up to 20 pages with a title, note, up to four earned destinations, and grid/stacked layouts. Export or share the saved page. |
| Weekly expeditions | Northern Lights, Island Hopping and Mediterranean Memories rotate on Monday UTC. Complete all stops in the named expedition that week to earn its keepsake. Rewards remain in the adventure collection after the week changes. |
| iPhone/small-phone polish | Automated rendering checks every new activity screen at 375×667 and 390×844. The exact native sharing bridge passed presentation and cancellation-handler checks on a paired physical iPhone 14 Pro through an isolated test app; the installed game was not replaced. |
| Photo mode | Open from the memory game's pause panel or the activity hub. Choose a scenic destination, pose, buddy, frame and caption, then save/share the composed picture. Returning from pause photo mode preserves the paused run. |
| Passport personalization | Save a nickname, motto and Ruby/Jade/Ocean stamp ink, and choose existing earned covers. Ink applies to passport pages and gameplay stamps. |
| Destination mastery | Completion earns Bronze. A flawless Moderate memory clear earns Silver; flawless Hard earns Gold. Balloon Tour medal levels also count. Kids clears earn Bronze. Older discovered countries receive Bronze on reload without fabricated dates. |
| Treasure hunts | Solve a capital-city clue, then complete its destination to earn its treasure. Wrong guesses do not consume progress. |
| Travel bingo | Nine weekly goals count completions, flawless finishes, buddy travel, photos, knowledge, room interactions, Silver mastery, treasures and expeditions. Each completed line earns a retained sticker. |
| Departure lounge | A small airport lounge with a departure board and packed suitcase links to World Tour, weekly/buddy/treasure routes and discovered stops. |
| Travel timeline | Stores actual dated stamps, first flawless finish, mastery, trophies, quests, treasures, stickers and photos. Earlier saves are shown as earlier journeys without invented dates. |
| Room expansion | Earn a balcony at 6 destinations, reading nook at 12, gallery at 20. Each space retains its own six keepsakes, postcards, decorations and positions. |
| Weather/time of day | Choose Clear/Rain/Snow and Day/Sunrise/Sunset/Night. Arrival scenes, photos and gameplay sky decorations reflect the selection; buddies react to weather. Effects do not obscure the playable path or alter collisions. |
| Learning challenges | Completed real destinations with known capitals unlock optional multiple-choice questions from existing catalog data. Correct answers earn one permanent knowledge sticker. No score or failure penalty. |
| Celebration customization | Choose Wave/Jump/Cheer, Gold/Ocean/Forest confetti and a favorite sound. Memory-game victory movement, stamp sounds and celebration previews use those choices. |
| Discovery checklist | Search all destinations, inspect souvenir/mastery/rare/knowledge progress, and receive a concrete next objective. Optional replay buttons respect destination access; premium routes stay in their existing purchase flows. |

## Persistence and verification

`scripts/core/travel_activities.gd` validates bounded new profile fields. The timeline keeps 500 events; the existing daily postcard archive keeps 30 days. Adventure rewards persist separately from weekly boards. `tests/test_travel_batch.gd` checks gating, mastery tiers, clue completion, quest accessories, permanent rewards, quiz uniqueness, weekly rollover, bingo, separate room arrangements, scrapbook reload, screen sizing and PNG exports. It captures each new screen when run with a display; `--small` selects 375×667.

`tools/check_iphone_sharing_device.py --device <paired-UDID> --profile <existing-mobileprovision>` uses a separate signed test app and removes it afterward. It verifies native presentation and the cancellation callback; it never sends a picture to a recipient. Actual recipient delivery, saving to Photos and a full newly exported Godot build on the physical device are outside that automated check.
