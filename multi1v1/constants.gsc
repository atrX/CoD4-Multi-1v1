init () {
	level.constants = [];

	setConstant("devMode", false);

	setConstant("minPlayers", 2);
	setConstant("maxArenas", 16);

	setConstant("countdownLength", 3);
	setConstant("countdownColor", (.83, .095, .23));

	setConstant("playerHealth", 100);
}

setConstant (name, value) {
	level.constants[toLower(name)] = value;
}

getConstant (name) {
	return level.constants[toLower(name)];
}
