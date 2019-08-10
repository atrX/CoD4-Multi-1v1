init () {
	game["menu_team"] = "team_marinesopfor"; // TODO: replace with custom menu

	preCacheMenu(game["menu_team"]);

	level thread onPlayerConnect();
}

onPlayerConnect () {
	for (;;) {
		level waittill("connecting", player);
		player thread onMenuResponse();
	}
}

onMenuResponse () {
	self endon("disconnect");

	for (;;) {
		self waittill("menuresponse", menu, response);

		if (menu == game["menu_team"]) {
			switch (response) {
			case "allies":
			case "axis":
			case "autoassign":
				self closeMenu();
				self closeInGameMenu();

				if (self.pers["team"] != "spectator") {
					continue;
				}

				self multi1v1\mod::setTeam("allies");
				break;
			}
		}
	}
}
