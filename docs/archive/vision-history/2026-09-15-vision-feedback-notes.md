---
status: stale
last_updated: 2026-09-15
related_repo: knk-workspace
---

# Vision feedback notes (2026-09-15)

> `Notes-claude-15-09-26.docx` — the user's response/feedback while reviewing a structured outline of the game vision, written the evening before [vision.md](../../vision/vision.md)'s last edit (2026-09-16). Treated as already incorporated into `vision.md` rather than a standalone active document; kept here for provenance on *why* several `vision.md` decisions (Districts as neighborhoods not primarily wealth-tiers, MVP kingdom count, the Territory/`controlledBy` distinction, premium-tier philosophy, etc.) read the way they do.

---

I am just responding and noting things that come to mind while I read through the structured outline.

## Core concept

To just add a little to the already very concise description of the core concept: A major part of the players "day-to-day" activities should also include going on adventures; exploring the game world, doing mini-games, completing quests etc. Not simply to "build lives within towns". Ultimately I want players themselves to decide with what activities they want to progress in the game, whether it is adventuring, pvp'ing, doing town chores and progressing in the occupation system. There should be multiple ways to level up, increase your wealth and items quality. Of course, in the end the ultimate goal of the game is to join a clan, rise in its ranks and conquer the game world with your clan in the seasonal rotation of "clan wars" or whatever its name will be.

## World Structure

So Districts have multiple roles. They CAN and most often will, as byproduct, group areas and structures by wealth tier. But what do I mean by wealth tier? The wealth tier is just a packaging for multiple things such as entry conditions (player level, player wealth such as minimum coins/gems required, their clan, their premium/donor rank etc.) the mean price of housing in this district, the grade and rarity of commodities sold there etc. All kinds of things determine whether a district is 'wealthy' or not. But Districts fundamentally just mean neighborhoods, "wijken" in dutch or parts of a town.

So your fourth bulletpoint touches exactly what I described above. Districts (and Kingdoms, provinces and towns alike) can be used to restrict access and steer player progress, just like the recent Assassins Creed franchise games (like Origins, Valhalla, Odyssey and Shadows) do. They restrict access to game content (i.e. game world areas) by simply not allowing players to enter or by other mechanics such as very aggressive and strong opponents/npc's, based on various metrics of the player's progression such as balance in coins, gems or its level, its occupation (and level), its items, clan, premium/donor rank etc.

For the immediate future only 1, maybe 2 kingdoms will exist. With the immediate future I am referring to this project's goal (i.e. the claude project Knights and Kings) of getting the minigame Siege up and running, and other essential features too. This will be the open beta MVP (I can get into more detail about this milestone later).

Do you need me to provide more detail about the structure types? Or will we get into that later? I assume there was a lot of info about those in the documents and in the datamine of the legacy projects (a Claude Code session pushed the legacy spec mining findings to the docs repo under branch `legacy-spec-mining`)?

## Clans Conquest & Seasons

Correct. A clan can only exist if it holds control of at least one clanhouse/stronghold. However, not the cost of the clanhouse/stronghold alone gates who can start one. The player level and possibly other player statistics can be used to gate who can start a clan.

I am not sure what you mean by in-kingdom and out-of-kingdom. The Kingdom entity merely represents a region of the game world, just like district and the others. However, eventually I want Kingdom, Province, Town and District entities to have a controlledBy/owner mechanism, stating which player/group/clan holds control over this entity. As far as I can currently imagine, there will be no area in the gameworld that is not part of at least one of the aforementioned entities. An edge case is areas around towns, I would describe them as "wilderness", but they should be "wilderness" owned by either a Town or a Province or a Kingdom. The Wilderness can be used by internal game mechanics to for example spawn a player ambush of bandits, or a bandit camp or monsters etc. Does this all make sense? As far as taking clancastles goes; the amount of clancastles in a district or town depends on the size of the district/town. Each clancastle can be taken from other clans or npc's by a small siege. Possibly in the future a clan can, under certain circumstances and with the right resources (conditions) try to conquer a district or town (i.e. multiple clancastles) in one large siege.

Attacks should indeed happen on a scheduled cadence is what I thought of initially. This system should indeed be fair for both the attacking and defending parties. This system would also allow new game mechanics such as siege preparation tasks, intelligence gathering missions and sabotage missions, as well as strategy planning.

I haven't really thought too much about what ends a season. Obviously a season ends if one clan controls all clancastles in the game world. But this could create a space where a season takes "too" long, but then again what is too long? But what if there is a tie-battle going on endlessly? There are things to think about. Another good question from your end is what resets/persists for clans and players after a season-end. This I haven't really thought about too much either. I did think about some mechanism similar to Formula 1 pole position and start position based on how well the clan performed in the previous season. Also thought about rewards for individual players based on their efforts in the previous season etc. But this needs more thought and input.

I want to have a multitude of clan-related mechanics, which in theory should allow new/small clans to compete with bigger ones. But overall clans can be too big for other clans to handle, and those smaller clans have no other option than to either form an alliance or merge into the bigger clan. But some mechanics are resource production/transports, trade, knowledge, and their promotion or disruption through tasks and missions executed by players with a specific role (i.e. profession and skill level of that profession). I do want some kind of Politics/relations/negotiations mechanic between clans. Clans can then improve or degrade their ties and relations between them, ranging from enemies in war to close allies (drawing heavy inspiration from the Sid Meier's Civilization franchise, especially Civ 5's politics and international relationships mechanics). Overall, it wouldn't be too wise for a player or small clan to join the fight in a late-season if it intends on winning.

## Economy & Professions

Your first bullet point reminded me of a larger scaling problem I haven't really found a solution for yet. It is the following: The game-world will have (in the foreseeable future) a finite amount of Kingdoms, provinces, towns, districts and structures, including houses, shops and resource-production structures. I really like the idea of players buying and owning their own house/apartment and/or shop/resource-production structure. This was actually one of the first core ideas for this game. However, the number of players will most likely keep growing while the number of ownable structures will not. This will eventually get problematic, where there are too little living structures and shops/resource-production structures for the amount of players. This is even worse for high-demand structures or A-location structures. GTA 5 for example, solved this by basically enabling a virtually infinite amount of copies for the same structures, with condos having a computed view out of the window, which will be much harder (possibly impossible) in Minecraft. Same goes for the shops/resource-production structures. One instance can have only one owner. With the shops and RP structures it can be solved a little more easily, by simply allowing multiple players to 'own' the same structure in the backend, and paying each player the stated income. But the problem here lies in the custom stock and upgrade level of the structure. I am desperately searching for solutions for these scalability problems. I am aware that these are specifically tied to Minecraft, and that's why I am now developing the game in such a way that migrating to a different platform (e.g. Unreal Engine or a custom engine) in the future is a viable option without having to develop the codebase from scratch. However, I want to build it initially in Minecraft, therefore I am desperately searching for solutions. A possible solution I had for housing was to create new Minecraft worlds (linked through the Multiverse or BungeeCord plugins) which contain small patches of land separated by void which allows players to "build" their own house, which would solve a lot of the housing capacity, however I do like the thought of actual players living in the houses where players walk through in the game world, if that makes sense. Maybe you can help me with these topics?

About the professions: These were the ones I could think of, but 5 is definitely not the limit.

The stated intent about real medieval market data would be nice, but game balance before realism I'd say.

As I mentioned above here, I'm not sure about single or multi-owner structure.

As I said, open to suggestions and additions, but for now we'll stick with the 4/5.

## Player progression & Social status

The experience points are very much tied to the noble titles. The noble titles are the player levels. When a player reaches the highest level (i.e. noble title), experience points can still increase, so eventually other players can see how 'good' or 'veteran' a player is by their experience points more than their max. level. Titles are NOT unlocked by specific achievements.

Donor tiers (I'd like to rename them to premium tiers) should have a good balance between pay-to-win and cosmetic. Personally, I would rather spend real money on in-game things which provide a real advantage or speed up progress rather than pure cosmetics.

The random advantages and disadvantages idea is dropped. Very complex and ambiguous to implement.

## Law, Crime & Safety

Yes. The jail and justice system needs refinement, but I really like the idea to jail people, execute them, fine them for crimes and offences, including spamming, swearing etc. Bandit ambush and camp probability goes up also by their distance from law-enforcement buildings.

The scenario is the "map" and game-mode details of a Siege minigame. It is configurable by an admin and contains at least the number of sides (default 2: defenders and attackers), the teams (could be more than 2 if there are 2 rival teams attacking and 1 defending, could be 2 allies attacking and one or more defending), the spawnpoints per team, the objectives and who holds which objective at the start. Possible main objectives (main objective determines winner when captured). In the classic Siege minigame (can be different for clan sieges) layout I thought of, you have 2 teams, one defending and one attacking. The town hall (or something similar) is the main objective. The town gates are side objectives and some other strategic/important points can also be side objectives. The defenders typically hold all objectives at the start of the game. Held objectives double as spawnpoints for the team holding them. GateStructures can be objectives and are destroyed once captured by the attackers. More info probably in the legacy mine. I also envisioned each town/kingdom having its own default team, with team colors, a banner and allies/enemies etc. These can be selected while configuring a scenario. Should be defined more. If you need more info about the Siege minigame let me know, but I think it's best to first merge the info from this and the documentation with the findings of the legacy code mine.

I think storyline can be moved to the bottom of the priority list.

I think you are missing individual item age and item origin? It was described in the iphone notes.
