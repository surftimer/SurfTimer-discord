/**
 * Called when a new challenge is created
 *
 * @param mapname					challenge map name
 * @param style						challenge style
 * @param points					challenge rank 1 challenge points
 * @param szInitial_Timestamp	    challenge start date
 * @param szFinal_Timestamp	        challenge end date
 */
forward void mapchallenge_OnNewChallenge(int client, char szMapName[32], int style, int points, char szInitial_Timestamp[32], char szFinal_Timestamp[32]);

/**
 * Called when a challenge is ended
 *
 * @param mapname					challenge map name
 * @param style						challenge style
 * @param points					challenge rank 1 challenge points
 * @param szInitial_Timestamp	    challenge start date
 * @param szFinal_Timestamp	        challenge end date
 * @param szWinnerName	        	challenge winner
 */
forward void mapchallenge_OnChallengeEnd(int client, char szMapName[32], int style, int points, char szInitial_Timestamp[32], char szFinal_Timestamp[32], ArrayList szChallengeTop5, int totalParticipants);

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
	MarkNativeAsOptional("mapchallenge_OnChallengeEnd");
}