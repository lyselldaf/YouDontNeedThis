# You Don't Need This

WoW Forever addon that tells you which quest items in your bags you can throw away because
you've already completed every quest that uses them.

It works on its own, with no commands needed:

- Items you don't need get a red tint and a red X in your bags and bank. Works with the default
  bags, Bagnon, Baganator, AdiBags (also as its own section) and ArkInventory.
- After login you get one line in chat saying how many items you don't need.
- When you turn in a quest and one of its items is no longer needed, or you loot one you don't
  need, a message appears in chat and briefly on screen.
- Hover an item: "YDNT: <the completed quest it was for>" or "Still needed: <quest>"
- Settings: Esc > Options > AddOns > You Don't Need This, or the addons button by the minimap.

Commands:

- `/ydnt list` — list every item in your bags (and bank, as last seen) you don't need
- `/ydnt why <item>` — shift-click an item to see which quests it's linked to and why
- `/ydnt ignore <item>` / `/ydnt keep <item>` / `/ydnt clear <item>` — your own verdict on an
  item (not needed / never mark / back to automatic), for all your characters
- `/ydnt options` — open the settings
- `/ydnt marks` / `/ydnt alerts` — turn the bag marks or the alerts on or off
- `/ydnt scan` — rescan quest log and bags now
- `/ydnt reset` — clear learned data for this character

Non-English clients: quest names from the built-in database are in English. Quests you've had in
your quest log show in your client's language.

Install: copy the `YouDontNeedThis` folder into `World of Warcraft\<Forever folder>\Interface\AddOns`.

## Quest data

Which items belong to which quests comes from `SeedData.lua`, generated from the
[QuestieDB](https://github.com/Questie/QuestieDB) addon's database, plus links the addon learns
from your own quest log. Players don't need Questie installed.

To regenerate `SeedData.lua` (developers only):

1. In game, with Questie and QuestieDB enabled, run `/ydnt export` and wait for "export done".
   This also saves which quests Questie hides as unobtainable. `/ydnt export` exists only in the
   repo copy of the addon: the release zip leaves out `Export.lua`.
2. Log out or `/reload`, so the game writes the saved variables file.
3. Run:

   ```powershell
   .\tools\Build-SeedData.ps1 -SavedVariables "<WoW Forever>\WTF\Account\<ACCOUNT>\SavedVariables\YouDontNeedThis.lua"
   ```

## Releasing

1. Bump `## Version:` in `YouDontNeedThis/YouDontNeedThis.toc`.
2. Add a `## <version>` section at the top of [CHANGELOG.md](CHANGELOG.md) describing what changed.
3. Build the zip, which ends up in `dist\YouDontNeedThis-<version>.zip`. The build fails if the
   changelog section is missing. It prints the section and saves it to `dist\changelog-<version>.md`.

   ```powershell
   .\tools\Build-Package.ps1
   ```

4. Upload the zip on the CurseForge project's Files tab and paste the changelog into its Changelog field.

## License

GNU GPL v3 or later (see [LICENSE.md](LICENSE.md)). Quest data comes from QuestieDB, also GPLv3;
see [CREDITS.md](YouDontNeedThis/CREDITS.md). Not affiliated with the Questie team.
