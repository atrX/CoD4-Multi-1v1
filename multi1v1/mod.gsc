#include multi1v1\utils;
#include multi1v1\constants;

#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

main () {
	precache();
	preCacheModel("body_mp_usmc_cqb");

	level.splitscreen = isSplitScreen();
	level.xenon = false;
	level.ps3 = false;
	level.onlineGame = true;
	level.console = false;
	level.rankedMatch = getDvarInt("sv_pure");
	level.teamBased = true;
	level.oldschool = false;
	level.gameEnded = false;
	level.mapName = toLower(getDvar("mapname"));

	if (!isDefined(game["roundsplayed"])) {
		game["roundsplayed"] = 1;
	}
	game["state"] = "readyup";

	thread maps\mp\gametypes\_hud::init();
	thread maps\mp\gametypes\_hud_message::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_gameobjects::init();
	thread maps\mp\gametypes\_spawnlogic::init();
	thread maps\mp\gametypes\_quickmessages::init();

	multi1v1\constants::init();
	multi1v1\arenas::init();
	multi1v1\menus::init();
	multi1v1\loadout::init();

	level thread gameLogic();
}

precache () {
	precacheShader("black");
	precacheShader("white");
	precacheShader("killiconsuicide");
	precacheShader("killiconmelee");
	precacheShader("killiconheadshot");
	precacheShader("killiconfalling");
	precacheShader("stance_stand");
	precacheShader("score_icon");

	precacheStatusIcon("hud_status_connecting");
	precacheStatusIcon("hud_status_dead");
}

abort (msg) {
	for (i = 0; i < 5; i++) {
		iPrintLnBold("^1" + msg);
	}
	setDvar("sv_maprotationcurrent", "gametype war map mp_crash");
	exitLevel(false);
}

gameLogic () {
	level endon("endround");
	waittillframeend;

	visionSetNaked("mpIntro", 0);
	wait .2;

	waitingText = createServerFontString("objective", 1.5);
	waitingText setPoint("center", "center", 0, -20);
	waitingText setText("Waiting for players...");
	waitingText.hideWhenInMenu = true;

	while (getPlayingPlayers().size < getConstant("minPlayers")) {
		wait 2;
		if (getConstant("devMode") && getPlayingPlayers().size > 0) {
			break;
		}
	}
	waitingText destroy();

	orderedPlayers = orderPlayers(getPlayingPlayers());
	assignPlayersToArena(orderedPlayers);

	countdownTimer = newHudElem();
	countdownTimer.alignX = "center";
	countdownTimer.alignY = "middle";
	countdownTimer.horzAlign = "center";
	countdownTimer.vertAlign = "middle";
	countdownTimer.x = 0;
	countdownTimer.y = 0;
	countdownTimer.color = getConstant("countdownColor");
	countdownTimer.font = "objective";
  	countdownTimer.hideWhenInMenu = false;
  	countdownTimer.foreground = false;

	for (i = getConstant("countdownLength"); i >= 0; i--) {
	  	countdownTimer.fontScale = 2;
  		countdownTimer.alpha = 0;

		if (i > 0) {
			countdownTimer setText(i);
		} else {
			visionSetNaked(level.mapName, 1.0);
			players = getPlayingPlayers();
			for (j = 0; j < players.size; j++) {
				players[j] freezeControls(false);
			}
			if (!getConstant("devMode")) {
				thread endRound();
			}
			countdownTimer setText("GO!");
		}

		countdownTimer fadeOverTime(.5);
  		countdownTimer.alpha = 1;
		for (j = 0; j < 1; j += .05) {
		  	countdownTimer.fontScale += .1;
			wait .05;
		}
	}

	countdownTimer fadeOverTime(1);
	countdownTimer.alpha = 0;
	wait 1;
	countdownTimer destroy();
}

endRound () {
	while (level.arenaCount > 0) {
		level waittill("arena_done");
		level.arenaCount--;
	}

	level notify("endround");
	game["state"] = "round ended";

	// TODO: check time limit

	// TODO: endround music

	wait 5;
	map_restart(true);
}

orderPlayers (players) {
	orderedPlayers = [];
	for (arena = 1; arena <= getConstant("maxArenas"); arena++) {
		for (i = 0; i < players.size; i++) {
			if (isDefined(players[i].pers["arena"]) && players[i].pers["arena"] == arena) {
				orderedPlayers[orderedPlayers.size] = players[i];
			}
		}
	}
	for (i = 0; i < players.size; i++) {
		if (!isDefined(players[i].pers["arena"])) {
			orderedPlayers[orderedPlayers.size] = players[i];
		}
	}

	return orderedPlayers;
}

assignPlayersToArena (players) {
	level.arenaCount = 0;
	arena = 1;
	for (i = 0; i < players.size; i += 2) {
		loadout = undefined;

		if (!isDefined(players[i].pers["arena"])) {
			players[i].pers["arena"] = arena;
			players[i].pers["lastArena"] = arena;
		}

		if (players.size > i + 1) {
			if (!isDefined(players[i + 1].pers["arena"])) {
				players[i + 1].pers["arena"] = arena;
				players[i + 1].pers["lastArena"] = arena;
			}

			if (players[i].pers["lastArena"] < players[i + 1].pers["lastArena"]) {
				players[i] setTeam("allies");
				players[i + 1] setTeam("axis");
			} else {
				players[i + 1] setTeam("allies");
				players[i] setTeam("axis");
			}

			loadout = multi1v1\loadout::decideLoadout(players[i], players[i + 1]);

			players[i + 1].pers["lastArena"] = arena;
			players[i + 1] spawnPlayer(arena, loadout);

			thread arenaWaitForFinish(arena, players[i], players[i + 1]);
		} else {
			players[i] setTeam("allies");
			loadout = level.defaultLoadout;
			players[i].pers["arena"]--;
		}
		players[i].pers["lastArena"] = arena;
		players[i] spawnPlayer(arena, loadout);

		arena++;
	}
}

arenaWaitForFinish (arena, player1, player2) {
	level.arenaCount++;
	level waittill_any("player_death_" + player1 getEntityNumber(), "player_death_" + player2 getEntityNumber());
	level notify("arena_done");
}

setTeam (team) {
	self.pers["team"] = team;
	self.team = team;
	self.sessionteam = team;
}

playerConnect () {
	level notify("connected", self);
	self.statusicon = "hud_status_connecting";
	self setClientDvars("show_hud", "true", "ip", getDvar("net_ip"), "port", getDvar("net_port"));

	if (!isDefined(self.pers["team"])) {
		iPrintLn(self.name + "^7 entered the game");

		self setTeam("spectator");
		self.pers["score"] = 0;
		self.pers["kills"] = 0;
		self.pers["deaths"] = 0;
		self.pers["assists"] = 0;
	} else {
		self.score = self.pers["score"];
		self.kills = self.pers["kills"];
		self.deaths = self.pers["deaths"];
		self.assists = self.pers["assists"];
	}

	if (!isDefined(level.spawn["spectator"])) {
		level.spawn["spectator"] = getEntArray("spawn_allies", "targetname")[0];
	}

	if (game["state"] == "endmap") {
		self spawnSpectator(level.spawn["spectator"].origin, level.spawn["spectator"].angles);
		self.sessionstate = "intermission";
		return;
	}

	if (self.pers["team"] != "spectator") {
		self setTeam(self.pers["team"]);
		self spawnSpectator(level.spawn["spectator"].origin, level.spawn["spectator"].angles);
	} else {
		self spawnSpectator(level.spawn["spectator"].origin, level.spawn["spectator"].angles);
		self thread delayedMenu();
		logPrint("J;" + self getGuid() + ";" + self getEntityNumber() + ";" + self.name + "\n");
	}

	self setClientDvars("cg_drawSpectatorMessages", 1, "g_scriptMainMenu", game["menu_team"]);
}

delayedMenu () {
	self endon("disconnect");
	wait .05;

	self openMenu(game["menu_team"]);
}

playerDisconnect () {
	level notify("disconnected", self);
	level notify("player_death_" + self getEntityNumber());

	iPrintLn(self.name + "^7 left the game");
	logPrint("Q;" + self getGuid() + ";" + self getEntityNumber() + ";" + self.name + "\n");
}

spawnSpectator (origin, angles) {
	if (!isDefined(origin)) {
		origin = (0, 0, 0);
	}
	if (!isDefined(angles)) {
		angles = (0, 0, 0);
	}

	self notify("joined_spectators");

	resetTimeout();
	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.statusicon = "";
	self spawn(origin, angles);

	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("none", false);

	level notify("player_spectator", self);
}

spawnPlayer (arenaNum, loadout) {
	arena = multi1v1\arenas::getArena(arenaNum);

	resetTimeout();

	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";

	self detachAll();
	self setModel("body_mp_usmc_cqb");

	spawnPoint = multi1v1\arenas::getRandomSpawnPoint(arena, self.pers["team"]);
	self spawn(spawnPoint.origin, spawnPoint.angles);

	self setActionSlot(1, "nightvision");

	self.maxhealth = getConstant("playerHealth");
	self.health = getConstant("playerHealth");

	self thread multi1v1\loadout::giveLoadout(loadout);

	self notify("spawned_player");
	level notify("player_spawned", self);
}

playerKilled (eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration) {
	if (isPlayer(attacker) && attacker != self) {
		if (attacker.pers["arena"] > 1) {
			attacker.pers["arena"]--;
		}
	}
	if (self.pers["arena"] * 2 < getPlayingPlayers().size) {
		self.pers["arena"]++;
	}

	level notify("player_death_" + self getEntityNumber());
	[[level.callbackPlayerKilledGlobal]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}
