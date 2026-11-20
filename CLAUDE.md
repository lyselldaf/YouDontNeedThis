# You Don't Need This

A World of Warcraft addon for **WoW Forever** (client 1.60.x, Interface 16001 — verify in game with
`/dump select(4, GetBuildInfo())`). It flags quest items in your bags that you no longer need because
every quest that uses them is already completed.

## Layout
- `YouDontNeedThis/` — the addon itself (this is the folder that goes in `Interface\AddOns`)
  - `YouDontNeedThis.toc` — manifest; `YDNT_DB` per character (learned links, quest titles, bank as
    last seen, settings), `YDNT_Global` account-wide (`overrides[itemID] = "ignore"|"keep"`),
    `YDNT_Export` account-wide (export only). Addon compartment callbacks live in Options.lua.
  - `YouDontNeedThis.lua` — core: learning, bank cache, item status, overrides, tooltip, slash
    commands, throttled events; shares `ns.DB / ns.Global / ns.ItemStatus / ns.SetOverride /
    ns.ForEachBagItem / ns.ListJunk / ns.PREFIX` with the other files
  - `Bags.lua` — red tint + red X (`ns.SetMark`) on unneeded slots in the default bags, bank slots,
    Bagnon and Baganator, and alerts (login summary incl. bank; chat + UIErrorsFrame message when an
    item becomes unneeded or is looted). `ns.Refresh(announce, force)` is called after every
    throttled scan and calls each `ns.refreshHooks[i](changed)`. Settings: `YDNT_DB.settings.marks / .alerts`.
  - `Integrations.lua` — AdiBags (filter section + marks module via `AdiBags_UpdateButton`) and
    ArkInventory (`ArkInventory.API.ItemFrameUpdated` hook). APIs taken from their source; not yet verified in game.
  - `Options.lua` — canvas settings panel (Settings API, InterfaceOptions fallback), override list,
    `ns.OpenOptions`, addon compartment entry.
  - `SeedData.lua` — GENERATED: `items[itemID] = {questID,...}`, `quests[questID] = {name, races, classes}`,
    `raceMask[raceID] = bit`, `hidden[questID] = true` (Questie's unobtainable quests), `meta` (source version, date).
  - `Export.lua` — dev-only `/ydnt export`: walks `LibQuestieDB` (QuestieDB addon, corrections applied)
    in chunks, reads Questie's `QuestieCorrections.hiddenQuests`, and saves `YDNT_Export`.
    `Build-Package.ps1` leaves it (and `YDNT_Export`) out of the release zip.
  - `LICENSE.md`, `CREDITS.md` — GPLv3; credits QuestieDB
- `tools/Build-SeedData.ps1` — turns the `YDNT_Export` saved variables file into `SeedData.lua`
- `tools/Build-Package.ps1` — builds `dist/YouDontNeedThis-<version>.zip` for CurseForge (version from the .toc;
  packs the .toc, every file it loads, LICENSE.md and CREDITS.md)

## License
GPL-3.0-or-later, because SeedData.lua is derived from QuestieDB (GPLv3). Keep the license headers,
CREDITS.md and the source/version line in SeedData.lua. Don't use the Questie name or logo as
branding (QuestieDB's license forbids that); crediting it is fine.

## How it works
- The game API can say whether a quest is completed (`C_QuestLog.IsQuestFlaggedCompleted` /
  `IsQuestFlaggedCompleted`) but not which quests an item belongs to. Links come from two places:
  1. **Learning**: on `QUEST_LOG_UPDATE` / `BAG_UPDATE_DELAYED` (throttled 1s), item objectives in the
     quest log ("Linen Cloth: 3/10" or "3/10 Linen Cloth") are matched by name to items in the bags and
     saved to `YDNT_DB.learned[itemID][questID]`.
  2. **SeedData.lua**: links exported from QuestieDB (item objectives, `requiredSourceItems`,
     `sourceItemId`, and items whose `startQuest` is the quest). Repeatable/daily/weekly quests are left
     out (they never stay completed). Seed quests whose race/class mask excludes the player are ignored.
- An item is "not needed" only when every linked quest is completed (or unavailable: in the seed's
  `hidden` and never seen in this character's quest log) AND it is quest-only (item class Quest, or
  bind type 4 "Quest Item"). Trade goods like Light Leather are never flagged; `ItemStatus` then
  returns `false, {}, "shared"`. Player overrides win over everything ("ignored" / "kept").
- Bank: the default bank is -1 plus bank bags from `Enum.BagIndex.BankBag_1` (6 on Forever, which has a
  reagent bag at 5). Only readable while open, so its item IDs are cached in `YDNT_DB.bank`.
- UI: bag/bank marks, alerts, tooltip line ("YDNT: <completed quest>" / "Still needed: <quest>"),
  settings panel, plus `/ydnt list|why|ignore|keep|clear|options|marks|alerts|scan|reset|export`.
- Bag frames on Forever: `ContainerFrame1..13` and `ContainerFrameCombinedBags`; buttons via
  `frame:EnumerateValidItems()`, bag via `button:GetBagID()`. Hooks: `UpdateItems`,
  `ContainerFrame_Update`, `OnShow`. Bagnon: hook global `SetItemButtonTexture`, buttons with
  `.info` + `:GetBag()` (skip `:IsCached()`). Baganator: `Baganator.API.RegisterCornerWidget` +
  `RequestItemButtonsRefresh` (signature taken from OneForAll; Baganator source isn't on GitHub). Both verified in game.
- No Lua or Python is installed on the dev machine, and QuestieDB's corrections are Lua code, so the
  data is extracted in game (where QuestieDB already runs) rather than by parsing its repo.

## Conventions
- Forever is a retail-style UI on a Classic base: always feature-detect APIs (C_ namespaced first,
  then the old global), as the existing code does. Never assume one client's API.
- Keep event handlers throttled; QUEST_LOG_UPDATE and BAG_UPDATE fire constantly.
- Never delete or sell items automatically — the addon only informs.
- Releases: bump `## Version:` in the .toc and add a matching `## <version>` section at the top of
  `CHANGELOG.md` (player-facing wording, what changed since the last upload). `Build-Package.ps1`
  refuses to build without it and writes `dist/changelog-<version>.md` for CurseForge. 0.4.0 is the
  first public release.

## Status / next steps
- Verified in game: tooltip, seed data, `/ydnt why`, red marks in default bags, Bagnon and Baganator (v0.4.0),
  alerts. Not yet verified (v0.5.0): bank marks, settings panel, compartment entry, overrides, AdiBags,
  ArkInventory, and the `hidden` quests (needs a fresh `/ydnt export` with Questie enabled).
- Install: `C:\Program Files (x86)\World of Warcraft\_forever_\Interface\AddOns\YouDontNeedThis` is a
  junction to this repo's addon folder. Questie + QuestieDB are installed there too.
- Unobtainable quests: handled by the seed's `hidden` list (from Questie's blacklist) and by the
  player's `/ydnt ignore`. Until SeedData.lua is regenerated it has no `hidden` table.

## Testing locally (Windows)
Link the addon folder into the game instead of copying, so edits show up after `/reload`:
    mklink /J "<WoW Forever>\Interface\AddOns\YouDontNeedThis" "%USERPROFILE%\source\repos\YouDontNeedThis\YouDontNeedThis"
