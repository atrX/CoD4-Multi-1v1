main () {
	if (getDvar("mapname") == "mp_background") {
		return;
	}

	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::setupCallbacks();
	maps\mp\gametypes\_globallogic::setupCallbacks();

	maps\mp\gametypes\_globallogic::registerTimeLimitDvar("multi1v1", 12, 0, 1440);
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar("multi1v1", 500, 0, 5000);
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar("multi1v1", 1, 0, 10);
	maps\mp\gametypes\_globallogic::registerNumLivesDvar("multi1v1", 0, 0, 10);

	level.callbackPlayerKilledGlobal = level.callbackPlayerKilled;
	level.callbackStartGameType = ::Callback_StartGameType;
	level.callbackPlayerConnect = ::Callback_PlayerConnect;
	level.callbackPlayerDisconnect = ::Callback_PlayerDisconnect;
	level.callbackPlayerKilled = ::Callback_PlayerKilled;

	level.teamBased = true;

	level.allies = ::allies;
	level.axis = ::axis;
	level.spectator = ::spectator;
}

Callback_StartGameType () {
	setClientNameMode("auto_change");

	level.spawn = [];
	level.spawn["allies"] = getEntArray("spawn_allies", "targetname");
	level.spawn["axis"] = getEntArray("spawn_axis", "targetname");
	level.spawn["spectator"] = getEntArray("mp_global_intermission", "classname")[0];

	if (!level.spawn["allies"].size || !level.spawn["axis"].size) {
		multi1v1\mod::abort("MISSING SPAWN POINTS");
	}

	for (i = 0; i < level.spawn["allies"].size; i++) {
		level.spawn["allies"][i] placeSpawnPoint();
	}
	for (i = 0; i < level.spawn["axis"].size; i++) {
		level.spawn["axis"][i] placeSpawnPoint();
	}

	multi1v1\mod::main();

	allowed[0] = "multi1v1";
	maps\mp\gametypes\_gameobjects::main(allowed);
}

dummy () {
	waittillframeend;
	if (isDefined(self)) {
		level notify("connecting", self);
	}
}

Callback_PlayerConnect () {
	thread dummy();

	self.statusicon = "";
	self waittill("begin");
	self multi1v1\mod::playerConnect();
}

Callback_PlayerDisconnect () {
	self multi1v1\mod::playerDisconnect();
}

Callback_PlayerKilled (eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration) {
	self multi1v1\mod::playerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}

allies () {
	self multi1v1\mod::setTeam("allies");
}

axis () {
	self multi1v1\mod::setTeam("axis");
}

spectator () {
	self multi1v1\mod::setTeam("spectator");
}
