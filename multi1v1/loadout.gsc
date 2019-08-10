init () {
	level.loadouts = [];
	addLoadout("loadout_rifles", "Rifles", strTok("ak47_mp,g36c_mp,m4_mp,m16_mp", ","), true);

	level.defaultLoadout = "loadout_rifles";
}

addLoadout (id, name, weapons, secondaryWeapons) {
	loadout = spawnStruct();
	loadout.name = name;
	loadout.weapons = weapons;
	loadout.secondaryWeapons = secondaryWeapons;
	level.loadouts[id] = loadout;

	for (i = 0; i < weapons.size; i++) {
		preCacheItem(weapons[i]);
	}
}

decideLoadout (player1, player2) {
	// TODO: loadout picking
	return "loadout_rifles"; // TEMPORARY
}

giveLoadout (loadout) {
	self endon("disconnect");
	self endon("death");
	self endon("joined_spectator");

	waittillframeend;
	wait .05;

	self freezeControls(true);
	self takeAllWeapons();

	weaponIndex = self.pers["weapon_" + loadout];
	if (!isDefined(weaponIndex)) {
		weaponIndex = 0;
	}

	weapon = level.loadouts[loadout].weapons[weaponIndex];
	self giveWeapon(weapon);
	self giveMaxAmmo(weapon);
	// TODO: give secondary weapons if true

	wait .05;
	self switchToWeapon(weapon);
}
