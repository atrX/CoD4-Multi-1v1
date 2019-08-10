init () {
	level.arenas = [];

	setupArenas();
}

setupArenas () {
	triggers = getEntArray("trigger_multiple", "classname");
	for (i = 0; i < triggers.size; i++) {
		if (triggers[i].script_noteworthy != "arena") {
			continue;
		}

		arena = spawnStruct();
		arena.num = i + 1;
		arena.targetname = triggers[i].targetname;
		arena.spawnsAllies = [];
		arena.spawnsAxis = [];

		spawnsAllies = getEntArray("spawn_allies", "targetname");
		for (j = 0; j < spawnsAllies.size; j++) {
			if (spawnsAllies[j].target == arena.targetname) {
				arena.spawnsAllies[arena.spawnsAllies.size] = spawnsAllies[j];
			}
		}

		spawnsAxis = getEntArray("spawn_axis", "targetname");
		for (j = 0; j < spawnsAxis.size; j++) {
			if (spawnsAxis[j].target == arena.targetname) {
				arena.spawnsAxis[arena.spawnsAxis.size] = spawnsAxis[j];
			}
		}

		level.arenas[level.arenas.size] = arena;
	}
}

getArena (num) {
	return level.arenas[num - 1];
}

getRandomSpawnPoint (arena, team) {
	if (team == "allies") {
		return arena.spawnsAllies[randomInt(arena.spawnsAllies.size)];
	} else {
		return arena.spawnsAxis[randomInt(arena.spawnsAxis.size)];
	}
}
