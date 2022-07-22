/**
 * Called when a new challenge is created
 *
 * @param mapname			map name
 * @param style				challenge style
 * @param points			rank 1 challenge points
 * @param duration	        duration of the challenge
 */
forward void mapchallenge_OnNewChallenge(int client, char szMapName[32], int style, int points, char szInitial_Timestamp[32], char szFinal_Timestamp[32]);

public SharedPlugin:__pl_mapchallenge =
{
	name = "map_challenge",
	file = "map_challenge.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

public __pl_mapchallenge_SetNTVOptional()
{
	MarkNativeAsOptional("mapchallenge_OnNewChallenge");
}