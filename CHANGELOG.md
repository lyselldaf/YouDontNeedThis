# Changelog

Newest version first. Each version gets a `## <version>` heading matching `## Version:` in the .toc;
`tools/Build-Package.ps1` copies that section into `dist/` for pasting into CurseForge.

## 0.6.0

- **Clear out low-level quests.** A new window lists the grey quests in your quest log (or grey + green, or every quest a set number of levels below you), each with an Abandon button. Every abandon asks first. "Abandon all listed" skips quests that are ready to turn in, since those still pay out.
- **Easy to open.** Use the new minimap button (drag it to move it), a key binding (Esc > Options > Keybindings > AddOns), the button on the quest log, `/ydnt quests`, or right-click You Don't Need This in the addons button by the minimap.
- **Low-level quest reminders.** A chat line after login and when a level-up turns quests grey, with a clickable [Show]. Turn it off, or have the login reminder show only when the count goes up, in the settings.
- **Abandoned quests no longer keep items "Still needed".** Items for a quest you abandoned get the red X, and the tooltip shows the quest as "(abandoned)". Picking the quest up again makes it count again.
- **Update notice.** If someone in your guild or group runs a newer version of You Don't Need This, you get a one-line reminder in chat (and at each login until you update).
- `/ydnt minimap` shows or hides the minimap button.

## 0.5.0

- **Your bank is checked too.** Bank slots get the red X while the bank is open, `/ydnt list` includes items in your bank (as of your last visit), and the login summary counts them.
- **Settings panel.** Find it under Esc > Options > AddOns, or click You Don't Need This in the addons button by the minimap. Turn marks and alerts on or off and manage your own choices.
- **Make your own call on an item.** `/ydnt ignore <item>` marks an item as not needed, for example when its quest can't be done anymore. `/ydnt keep <item>` makes sure an item is never marked. `/ydnt clear <item>` undoes either. These apply to all your characters.
- **Fewer items stuck on "Still needed".** Quests that can't be picked up in the game anymore no longer keep an item needed. The tooltip shows them as "(unavailable)".
- **AdiBags and ArkInventory support.** AdiBags gets a "You Don't Need This" section and the red X; ArkInventory gets the red X.
- Typing `/ydnt` with an unknown command now lists every command.

## 0.4.1

- **Crafting materials are no longer marked.** Items like Light Leather or Linen Cloth that a quest used, but that also have other uses, no longer get the red X, alerts or "YDNT" tooltip. Only items that exist purely for quests are flagged.
- `/ydnt why` explains when an item's quests are done but it's kept because it has other uses.

## 0.4.0

First public release.

- **Red X on items you don't need.** Bag slots holding an item whose quests are all completed get a red tint and a red X. Works with the default bags (separate and combined), Bagnon and Baganator.
- **Automatic alerts.** A chat summary after login, and a message when you turn in a quest that leaves you holding an item you no longer need, or when you loot one.
- **Tooltips.** Quest items show "YDNT: <quest name>" naming the completed quest they were for, or "Still needed: <quest name>".
- **Built-in quest-item database** for WoW Forever, generated from QuestieDB (3,600+ items), so items looted before you pick up their quest aren't flagged by mistake. Questie is not required.
- Quests for other races, classes and the other faction are ignored. Repeatable and daily quests are left out.
- Commands: `/ydnt list`, `/ydnt why <item>`, `/ydnt marks`, `/ydnt alerts`, `/ydnt scan`, `/ydnt reset`.
