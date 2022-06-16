/**
 * Called when a new challenge is created
 *
 * @param mapname			map name
 * @param style				challenge style
 * @param points			rank 1 challenge points
 * @param duration	        duration of the challenge
 */
forward void mapchallenge_OnNewChallenge(int client, char szMapName[32], int style, int points, char szFinal_Timestamp[32]);

public __pl_mapchallenge_SetNTVOptional()
{
	MarkNativeAsOptional("mapchallenge_OnNewChallenge");
}