# Slush Rush – Game Design Document

Last updated: 2026-09-25

## Overview

Slush Rush is a cozy spatial puzzle game: fit fruit pieces into a blender, blend smoothies that match each customer's order, and serve them before customers lose patience. The full release expands the Comfy Jam: Summer 2026 entry into an 18-day campaign plus an unlimited roguelike mode.

| | |
| --- | --- |
| Genre | Cozy puzzle / time management |
| Engine | Godot 4.6 |
| Platforms | Steam (Windows), Android |
| Price | Steam $5 premium; Android free with ads |
| Session length | 3–6 min per day |
| Target playtime | 2–3 hours campaign, plus roguelike |
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

**Opening progression:** start Summer with one blender on Day 1, then unlock a second on Day 2, a third on Day 3 and the fourth on Day 4. Closed blenders show their opening day; the Day 12 repair modifier still leaves only two working. Early score targets are reduced for the smaller setup and still need a playtest balance pass.

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

## Roguelike mode, progression and unlocks

Roguelike mode unlocks after the campaign on Steam and is available from the start on Android. Stars and achievements unlock cosmetics.

**Roguelike:** an unlimited survival run inspired by Vampire Survivors' upgrade rhythm, using the smoothie-making loop. All fruits and shapes are available. The run ends when shop health reaches zero; health drains while customers are present, missed customers take extra health, and good smoothies restore it. There are no timed rounds or final wave.

Score milestones pause the shop and offer three distinct random upgrades. Pick one to resume. The first choices arrive at 2,500, 7,500, 15,000 and 25,000 cumulative points, with each following gap growing by 2,500. Large score jumps award each earned choice separately. Upgrades improve scoring, customer patience, maximum health, health from good service or conveyor control; an instant heal is also available. Conveyor slowing caps at 50% and disappears from the pool when maxed.

Difficulty scales independently of score. The first twist arrives after 40 seconds, then another arrives every 45 seconds. Fickle Customers comes first; the rest are shuffled. Each step increases health drain and missed-customer penalties by 6% of their base values, and reduces base patience toward a 60% floor. Pressure keeps increasing after every twist is active. Upgrade choices and pauses freeze this timer.

Upgrades and difficulty reset on death or a new run; best score and cosmetics persist. Existing roguelike best scores carry over. The calendar is the separate **Campaign** mode: authored days, score-based star goals, saved day unlocks, and the early blender progression. Roguelike upgrades never change campaign day resources.

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
| Ads | None | Heavy: interstitials after every day and every run, rewarded ads for unlocks and revives |
| Purchases | None | Optional "Remove ads" (~$2.99) |
| Content | Full campaign and roguelike | Same content as Steam |
| Roguelike | Unlocked after the campaign | Unlocked from the start |
| Unlocks | Earned at a normal pace | Take much longer; rewarded ads speed them up |
| Daily Slush | Online leaderboard | Offline, personal best and streak only |
| Online | Achievements, leaderboards, multiplayer, cloud saves (GodotSteam) | None |
| Builds | Windows and Linux, plus a demo on the same store page | Android |

**Android ad requirements:** AdMob plugin for Godot 4, GDPR consent popup (Google UMP), a privacy policy, and a Play Data Safety form that declares ad data.

**Out of scope for launch:** controller support and Steam Deck Verified, localization, iOS.

## Technical notes

- **Engine:** Godot 4.6. Steam uses the Forward+ renderer. Android switches to the Mobile renderer (or Compatibility for low-end phones).
- **Save system (new):** `user://` save with day progress, stars, upgrades, cosmetics, settings and roguelike best score. Saves on day end and on `NOTIFICATION_APPLICATION_PAUSED`.
- **DayConfig (new):** one resource per day. `GameManager` reads it at day start.
- **Input:** rotation is right-click only today (`dragable_fruit.gd`, `dragable_smoothie.gd`). Add a touch rotate path, and force `auto_show_orders` on for mobile.
- **Settings:** fullscreen/windowed, separate music and SFX volume, auto-show orders, colorblind mode (icons or patterns on fruit).
- **Font:** Delicious Handrawn (Google Fonts, OFL), set once as the project default through `Assets/fonts/slush_font.tres`. Text on the wooden boards uses a painted style (`BoardPaint`).
- **Cleanup:** remove the `.tscn*.tmp` files and the build outputs in the project root.

## Builds and exports

Plans for the Steam and Android builds. Only the jam Web and Windows presets exist so far.

**Shared setup (do first):**

- [x] Project renamed to "Slush Rush", version 0.1.0. Saves live in a custom user folder named "Slush Rush" (`%APPDATA%\Slush Rush` on Windows), so the path won't change again.
- [x] Presets export into a gitignored `builds/` folder.
- [x] Exclude filter on the presets: `addons/godot_mcp/*, *.tmp, builds/*`.
- [x] Old jam build outputs and unused test assets removed from the repo.
- A `tools/build.ps1` script that runs `godot --headless --export-release` for each preset, stamps the version, and refuses to build while the MCP autoloads are still in `project.godot`.
- Custom feature tags per preset (`steam`, `mobile`, `demo`) so code checks `OS.has_feature()` instead of separate branches.
- Show the version number in the settings or credits screen so bug reports say which build they came from.

**Steam (Windows, plus Linux for Steam Deck):**

- Windows preset: product name, company, `.ico` icon, embedded pck for a single exe, Forward+ renderer.
- Linux preset as a cheap extra so the Deck runs it natively. Aim for Deck "Playable", not Verified (still out of scope). The 1280x800 screen already works with the `expand` stretch aspect; check board text size there.
- GodotSteam as a GDExtension, only loaded with the `steam` tag. If Steam fails to start, the game still runs offline with no achievements.
- Pause the game when the Steam overlay opens.
- Cloud saves through Steam Auto-Cloud (point it at the save file in the Steamworks settings, no code needed).
- Rich presence: "Summer, Day 7" or "Roguelike, 12,400 pts".
- Achievements from existing content: finish each campaign, 3 stars on every day, first upgrade pick, roguelike score thresholds, unlock every style.
- Leaderboards: roguelike best, plus a seeded **Daily Slush** run where everyone gets the same fruit order and twists that day. This is the async multiplayer idea: Steam hosts the scores, so no servers are needed. Friends-only filter by default.
- Uploads with SteamPipe (`steamcmd` + a depot script in `tools/`). A `beta` branch for testers, and the free Steam Playtest app during the Coming Soon period.
- **Demo idea:** a separate demo app (built with the `demo` tag) with Summer Days 1 to 6 and a roguelike run capped at the first two upgrades, for Next Fest and wishlists. Demo saves carry into the full game.

**Android:**

- Gradle build (the AdMob plugin needs it), AAB output, arm64-v8a plus armeabi-v7a, current Play target API level.
- Keystore kept outside the repo, backed up twice. Losing it means the app can never be updated.
- Mobile renderer on the Android preset; turn on ETC2/ASTC texture import. Keep a Compatibility build in reserve for low-end phones if the melt and frozen shaders are too slow.
- Landscape only (sensor landscape). Pad the HUD with `DisplayServer.get_display_safe_area()` for notches and rounded corners.
- Anything that relies on hover (like the star score popup) needs a tap version.
- Android back button: pause in game, go back in menus, confirm before quitting on the title screen.
- Cap at 60 fps in game and 30 fps on menus to save battery.
- Keep the download small: Ogg audio, check the export for unused assets.
- No Play Games sign-in or online features. Daily Slush runs offline from a date-based seed.
- Closed test: recruit the 12 testers from the itch jam page and Discord before the build is finished, since the 14 days only start once they join.

**Decisions:**

- **Demo:** yes, on Steam, attached to the main store page. A Steam demo is its own app ID but shows as a "Download demo" button on the full game's page, so there is no second store page to maintain.
- **Linux:** ships at launch. It is just another export preset and GodotSteam has Linux builds, so the cost is one extra upload and a test on the Deck.
- **Daily Slush:** on both platforms. Steam gets online leaderboards; Android plays the same daily seed but only tracks your own best and streak.
- **Online features are Steam only.** Android has no leaderboards, multiplayer or sign-in. The other differences on Android are much slower unlocks and far more ads.

## Multiplayer (Steam only)

Async, using Steam's servers through GodotSteam, so there is nothing to host or pay for.

**Daily Slush** is the only online mode at launch: one seeded roguelike run per day, with the same fruit, twists and upgrade offers for everyone. The seed comes from the UTC date, so no server is needed to hand it out. Each daily opens with 2 random campaign twists as debuffs and 2 random roguelike upgrades as buffs, then plays like a normal roguelike run. Unlimited retries; the best score of the day counts, and playing on consecutive days builds a streak. Scores go to a daily Steam leaderboard with global and friends tabs. Android plays the same seed offline.

Ideas for after launch, only if the game does well: Friend Challenge (race a friend's seed as a ghost), Weekly Shift, Next Rival target line, a community Tip Jar goal, Custom Days with share codes, and real-time Rush Duel through Steam lobbies.

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

- [x] Save system (`SaveManager`): settings, day progress, stars, roguelike best
- [x] Campaign: 18 `DayConfig` days, every twist implemented
- [x] Day select calendar, day intro card, day end screen with stars, in-game day timer
- [x] Sunset tint over each day, night shift and power outage effects
- [x] Smoothie pour scene transition, painted board text
- [x] Calendar footer keeps Style beside Roguelike; star counts use drawn icons, and calendar tiles, Style swatches and board controls paint on with the text
- [x] Summer starts with one blender and opens one more each day through Day 4
- [x] Touch rotate (second finger tap) and always-on order bubbles on mobile
- [ ] Balance pass on star targets (current values are first guesses)
- [x] Unlimited roguelike: score-based upgrade choices, escalating survival pressure, and upgrades that reset each run
- [ ] Playtest roguelike milestone costs, upgrade strength and pressure growth
- [x] Style unlocks: blender, wall, conveyor, transition and board paint colors
- [x] Second campaign (Boardwalk Nights) with five new mechanics
- [x] Hands-on day 1 tutorial, redone settings and credits screens
- [ ] Shop upgrades (gameplay unlocks)
- [x] Settings: fullscreen toggle
- [ ] Colorblind mode
- [x] Daily Slush: date-seeded run with daily buffs and debuffs, local best and streak
- [ ] Steam achievements and leaderboards (roguelike, Daily Slush), Android ads

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
