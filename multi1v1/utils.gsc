getAllPlayers () {
	return getEntArray("player", "classname");
}

getPlayingPlayers () {
	players = getAllPlayers();
	playingPlayers = [];
	for (i = 0; i < players.size; i++) {
		if (players[i].pers["team"] == "allies" || players[i].pers["team"] == "axis") {
			playingPlayers[playingPlayers.size] = players[i];
		}
	}
	return playingPlayers;
}
