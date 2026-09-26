# Slush Rush – Game Design Document

Last updated: 2026-09-25

## Overview

Slush Rush is a cozy spatial puzzle game: fit fruit pieces into a blender, blend smoothies that match each customer's order, and serve them before customers lose patience. The full release expands the Comfy Jam: Summer 2026 entry into an 18-day campaign plus endless mode.

| | |
| --- | --- |
| Genre | Cozy puzzle / time management |
| Engine | Godot 4.6 |
| Platforms | Steam (Windows), Android |
| Price | Steam $5 premium; Android free with ads |
| Session length | 3–6 min per day |
| Target playtime | 2–3 hours campaign, plus endless |
| Jam version | [joshwright.itch.io/slush-rush](https://joshwright.itch.io/slush-rush) (free) |

**Pitch:** Summer has arrived and the smoothie bar is open. Drag fruit off the conveyor, rotate and pack it into the blender, then blend a drink that hits the customer's fruit percentages.

## Core loop and controls

The jam's loop stays unchanged: read order, pack blender, blend, serve. The full game wraps it in days with goals and unlocks between them.

1. A customer arrives with an order: target fruit percentages.
2. Fruit pieces (polyomino shapes) move along the conveyor.
3. The player drags pieces into the blender grid, rotating to fit.
4. The player presses Blend; the smoothie's percentages come from the cells each fruit fills.
5. The player drags the smoothie to the customer. Score depends on how close it is to the order.
6. Customers who wait too long get angry, then leave.

**Day wrapper:** a day has a timer and a target score. At the end, the player gets a 1–3 star rating, rewards and upgrades, and the next day's twist is revealed.

| Action | PC | Android |
| --- | --- | --- |
| Pick up / drag | Hold left click | Touch and drag |
| Rotate | Right click while holding | Tap with a second finger while dragging, or tap a placed piece |
| Blend | Click Blend | Tap Blend |
| Serve | Drag smoothie onto customer | Drag smoothie onto customer |
| See order | Hover customer (or auto-show) | Always shown |

On touch, the dragged piece floats above the finger so the finger doesn't cover it.

## Content

The full game uses the jam's existing art: 5 fruits × 7 shapes (35 pieces). New sprites are added only if free art is available. Variety comes from blender sizes, customer types, day twists, shaders and recolors.

**Fruits:** strawberry, banana, blueberry, mango, apple.

**Shapes:**

| Shape | Cells | Status |
| --- | --- | --- |
| 1×1 | 1 | Existing |
| 2×1 | 2 | Existing |
| 3×1 | 3 | Existing |
| 2×2 L | 3 | Existing |
| 3×2 L | 4 | Existing |
| 3×2 T | 4 | Existing |
| 3×2 IL | 4 | Existing |
| New shapes (e.g. S/Z, 2×2 square, plus) | 4–5 | Only if free art is found (5 sprites each) |

**Blender sizes:** the grid size is already configurable (`grid_rows`, `grid_columns` in `Scripts/Grid/grid.gd`), and the blender art scales to fit. Sizes are used both as shop upgrades and as day modifiers:

- Small (3×3) – the broken-blender day
- Standard – the jam default
- Large – an upgrade
- Fewer blenders (2 of 4) – a day modifier

**Customers:** new types reuse the existing customer sprites. They're told apart by color tints and a small icon badge (for example a star for the critic or a clock for the rusher), not by new art.

- **Regular:** normal patience and tolerance.
- **Picky / critic:** tight percentage tolerance, big tip.
- **Rusher:** short timer, bonus if served fast.
- **Allergic:** order excludes one fruit.
- **Double order:** wants two smoothies.
- **VIP:** high value, appears once per day on late days.

## Campaign

The campaign runs 18 days, each with its own twist. To keep this fast to build, each day is a `DayConfig` resource. Most twists are just different values in it, so about half the days need no new code.

**DayConfig fields:** fruits allowed, shapes allowed, grid size, belt speed, customer patience, % tolerance, customer mix, day length, target score (1/2/3 stars), twist ID, sky/shader preset.

| Day | Name | Twist | Cost |
| --- | --- | --- | --- |
| 1 | Opening Day | 2 fruits, simple shapes; tutorial built in | Setting |
| 2 | New Delivery | Third fruit arrives | Setting |
| 3 | Odd Shapes | L and T shapes introduced | Setting |
| 4 | Food Critic | Tight % tolerance | Setting |
| 5 | Lunch Rush | Rush orders with a timer | Small |
| 6 | Allergy Season | "No banana" style orders | Small |
| 7 | Broken Blender | 3×3 grid | Setting |
| 8 | Belt on Overdrive | Fast conveyor | Setting |
| 9 | Rotten Batch | Blocked cells to avoid (`blank_cells` exists) | Small |
| 10 | Heatwave | Fruit melts if left on the belt | Small |
| 11 | Brain Freeze | Some pieces can't rotate | Small |
| 12 | Blender Down | Only 2 of the 4 blenders work | Setting |
| 13 | Mystery Menu | Order percentages partly hidden | Small |
| 14 | Night Shift | Dark screen, light around the cursor | Shader |
| 15 | Power Outage | Blend button flickers / cooldown | Small + shader |
| 16 | Double Trouble | Customers order two smoothies | Medium |
| 17 | VIP Visit | One big-tipping VIP plus a crowd | Medium |
| 18 | Summer Festival | Finale remixing earlier twists | Setting |

**Totals:** 9 setting-only days, 7 small, 2 medium. Day names and order can change; the twist list is the scope.

The wide 6×3 blender was swapped for Blender Down because the blender art can't stretch to a wide grid without new sprites.

## Campaign 2: Boardwalk Nights

Opens at 24 total stars. Twelve evening days, lit with a purple dusk tint, built around five mechanics that need no new art:

| Mechanic | What happens |
| --- | --- |
| Combo | Smoothies at 80%+ accuracy in a row multiply the score (x1.25 per step, up to x2) |
| Hot Blenders | Three blends within 18 seconds overheat a blender for 6 seconds |
| Belt Hiccups | The conveyor stalls for 2.5 seconds every 8 to 13 seconds |
| Shifty Fruit | Loose fruit changes type every 2.2 seconds until it's grabbed |
| Short Memory | Order bubbles fade after 3.5 seconds; hover the customer to peek |

| Day | Name | Twists |
| --- | --- | --- |
| 1 | Lights On | Combo |
| 2 | Hot Blenders | Overheat, combo |
| 3 | Belt Hiccups | Belt stalls, combo |
| 4 | Shifty Fruit | Shifty fruit, combo |
| 5 | Short Memory | Fading orders, combo |
| 6 | Lantern Light | Night shift, combo |
| 7 | Overtime | Overheat, rush, combo |
| 8 | Mixed Up | Shifty fruit, allergies, combo |
| 9 | Blackout | Power outage, belt stalls, combo |
| 10 | Midnight Critics | 85% accuracy, fading orders, combo |
| 11 | Double Heat | Double orders, overheat, combo |
| 12 | Grand Finale | Combo, shifty, overheat, fading, VIP, rush (180 s) |

Campaigns are data (`Resource/Campaigns/*.tres`), so a third campaign is a new list of day files plus a line in `GameManager.CAMPAIGN_PATHS`.

## Endless mode, progression and unlocks

Endless mode unlocks after the campaign on Steam and is available from the start on Android. Stars and achievements unlock cosmetics.

**Endless:** all fruits and shapes, difficulty ramps over time, and the run ends when a set number of customers leave angry. Steam has a global leaderboard for it.

**Shop upgrades (between days, bought with tips):**

- Bigger blender grid
- Slower customer anger
- Hold slot (keep one piece aside)
- Slower conveyor
- Wider % tolerance

**Cosmetic unlocks:** recolors of the blender, cups, bar, conveyor and customers. These are done with palette-swap shaders on the existing sprites, so they need no new art. On Steam they're earned through stars and achievements. On Android they cost more stars to unlock, and rewarded ads speed that up.

**Stars:** each day awards 1–3 stars from its score targets. Stars gate the last few days (about 30 stars to reach Day 18) and count toward cosmetics.

## Visuals and audio

Shaders are driven by the day timer, so each day both looks and plays differently. A single "time remaining" parameter feeds every effect.

| Effect | Trigger |
| --- | --- |
| Sky and lighting shift from morning to sunset | Day timer, every day |
| Heat shimmer that grows stronger | Heatwave day |
| Warm/red urgency tint | Rush timer near zero |
| Darkness with a light around the cursor | Night Shift |
| Light flicker | Power Outage |

**Animation polish list** (fixed time budget, done after the levels are playable):

- Blend swirl when the Blend button is pressed
- Squash and bounce when a piece drops into the grid
- Happy and angry reactions on customers
- Star reveal on the end-of-day screen
- Screen transitions (the existing wipe, restyled)

**Audio:** keep Nivadra's track and the existing SFX. Add a short end-of-day jingle and per-twist ambience if time allows.

## Platforms and monetization

| | Steam | Android |
| --- | --- | --- |
| Price | $5 | Free |
| Ads | None | Rewarded ads (main), interstitials only between days |
| Purchases | None | Optional "Remove ads" (~$2.99) |
| Content | Full campaign and endless | Same content as Steam |
| Endless | Unlocked after the campaign | Unlocked from the start |
| Cosmetics | Earned by playing | Harder to earn by playing; rewarded ads speed it up |
| Extras | Achievements, endless leaderboard (GodotSteam); cloud saves later | None at launch |

**Android ad requirements:** AdMob plugin for Godot 4, GDPR consent popup (Google UMP), a privacy policy, and a Play Data Safety form that declares ad data.

**Out of scope for launch:** controller support and Steam Deck Verified, localization, iOS.

## Technical notes

- **Engine:** Godot 4.6. Steam uses the Forward+ renderer. Android switches to the Mobile renderer (or Compatibility for low-end phones).
- **Save system (new):** `user://` save with day progress, stars, upgrades, cosmetics, settings and endless best score. Saves on day end and on `NOTIFICATION_APPLICATION_PAUSED`.
- **DayConfig (new):** one resource per day. `GameManager` reads it at day start.
- **Input:** rotation is right-click only today (`dragable_fruit.gd`, `dragable_smoothie.gd`). Add a touch rotate path, and force `auto_show_orders` on for mobile.
- **Settings:** fullscreen/windowed, separate music and SFX volume, auto-show orders, colorblind mode (icons or patterns on fruit).
- **Font:** Delicious Handrawn (Google Fonts, OFL), set once as the project default through `Assets/fonts/slush_font.tres`. Text on the wooden boards uses a painted style (`BoardPaint`).
- **Cleanup:** remove the `.tscn*.tmp` files and the build outputs in the project root.

## Schedule and release checklist

About 6 weeks of building, then about 5 weeks of store waits during which other projects can continue.

| Phase | Weeks | Focus |
| --- | --- | --- |
| Foundation | 1 | Save system, DayConfig, renderer switch, cleanup |
| Campaign | 2–4 | Days 1–18, twists, shop, settings, colorblind mode |
| Mobile | 4–5 | Touch controls, ads, consent, safe areas |
| Polish | 5–6 | Shaders, animations, achievements, leaderboard, tutorial |
| Store waits | +1 to +5 | Paperwork, store pages, closed test, reviews, launch |

**After the build is done:**

- [ ] Confirm "Slush Rush" is free on Steam and Google Play
- [ ] Written permission from Jack, Robert, Aurora and Nivadra to use their jam work in the commercial release, noting the agreed bonus
- [x] Font switched to a Google Font; credits updated
- [ ] Pay the Steam app fee ($100), which starts the 30-day wait
- [ ] Steam store page, capsule art, trailer; live as Coming Soon for at least 2 weeks
- [ ] Google Play developer account ($25), keystore, AAB export, current target API level
- [ ] Privacy policy page
- [ ] Play closed test with 12+ testers for 14 days in a row
- [ ] Update the itch page with a wishlist link
- [ ] Submit builds for review, then launch on a day someone can watch for 48 hours

## Build status

Done so far (September 2026):

- [x] Save system (`SaveManager`): settings, day progress, stars, endless best
- [x] Campaign: 18 `DayConfig` days, every twist implemented
- [x] Day select calendar, day intro card, day end screen with stars, in-game day timer
- [x] Sunset tint over each day, night shift and power outage effects
- [x] Smoothie pour scene transition, painted board text
- [x] Touch rotate (second finger tap) and always-on order bubbles on mobile
- [ ] Balance pass on star targets (current values are first guesses)
- [x] Style unlocks: blender, wall, conveyor, transition and board paint colors
- [x] Second campaign (Boardwalk Nights) with five new mechanics
- [x] Hands-on day 1 tutorial, redone settings and credits screens
- [ ] Shop upgrades (gameplay unlocks)
- [x] Settings: fullscreen toggle
- [ ] Colorblind mode
- [ ] Steam achievements and leaderboard, Android ads

## Team and decisions

Joshua Wright builds the full release solo. The jam team's art, music and code carry over, and the other contributors get a bonus payment after launch.

| Name | Jam role | Full release |
| --- | --- | --- |
| Joshua Wright | Godot dev | Solo developer |
| Jack (H4rb1nger) | Godot dev | Credited; bonus after launch |
| Robert Taquechel | Godot dev | Credited; bonus after launch |
| Aurora (Roranart) | Art | Credited; bonus after launch |
| Nivadra | Music | Credited; bonus after launch |

Sound effects by Kenney (kenney.nl). The font will be credited once the Google Font is chosen.

**Decisions:**

- **New art:** no new sprites unless free art is available.
- **Font:** Delicious Handrawn, with text on the boards styled to look painted on.
- **Team:** solo release, with bonuses to the jam contributors after launch.
- **Android vs Steam:** same content; on Android, recolors and other cosmetics are harder to unlock.
