#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <surftimer>
#include <discord>
#include <steamworks>
#include <smjansson>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "SurfTimer-discord",
	author = "Sarrus",
	description = "",
	version = "1.0",
	url = "https://github.com/Sarrus1/SurfTimer-discord"
};

ConVar g_cvWebhook;
ConVar g_cvThumbnailUrlRoot;
ConVar g_cvMainUrlRoot;
ConVar g_cvTitle;
ConVar g_cvMention;
ConVar g_cvBotUsername;
ConVar g_cvFooterUrl;
ConVar g_cvMainEmbedColor;
ConVar g_cvBonusEmbedColor;
ConVar g_cvSteamWebAPIKey;
ConVar g_cvHostname;
ConVar g_cvKSFStyle;

char g_szHostname[256];
char g_szApiKey[256];
char g_szCurrentMap[256];
char g_szPictureURL[512];

bool g_bIsSurfTimerEnabled = false;

public void OnPluginStart()
{
	//TODO: g_cvMinimumrecords = CreateConVar("sm_surftimer_discord_min_record", "0", "Minimum number of records before they are sent to the discord channel.", _, true, 0.0);
	g_cvWebhook = CreateConVar("sm_surftimer_discord_webhook", "", "The webhook to the discord channel where you want record messages to be sent.", FCVAR_PROTECTED);
	g_cvMention = CreateConVar("sm_surftimer_discord_mention", "@here", "Optional discord mention to notify users.");
	g_cvMainEmbedColor = CreateConVar("sm_surftimer_discord_main_embed_color", "#00ffff", "Color of embed for when main wr is beaten");
	g_cvBonusEmbedColor = CreateConVar("sm_surftimer_discord_bonus_embed_color", "#ff0000", "Color of embed for when bonus wr is beaten");
	g_cvTitle = CreateConVar("sm_surftimer_discord_title", "A new record has been set.", "Title of the discord announcement");
	g_cvThumbnailUrlRoot = CreateConVar("sm_surftimer_discord_thumbnail_url_root", "https://image.gametracker.com/images/maps/160x120/csgo/", "The base url of where the Discord images are stored. Leave blank to disable.");
	g_cvMainUrlRoot = CreateConVar("sm_surftimer_discord_main_url_root", "https://image.gametracker.com/images/maps/160x120/csgo/", "The base url of where the Discord images are stored. Leave blank to disable.");
	g_cvBotUsername = CreateConVar("sm_surftimer_discord_username", "", "Username of the bot");
	g_cvFooterUrl = CreateConVar("sm_surftimer_discord_footer_url", "https://images-ext-1.discordapp.net/external/tfTL-r42Kv1qP4FFY6sQYDT1BBA2fXzDjVmcknAOwNI/https/images-ext-2.discordapp.net/external/3K6ho0iMG_dIVSlaf0hFluQFRGqC2jkO9vWFUlWYOnM/https/images-ext-2.discordapp.net/external/aO9crvExsYt5_mvL72MFLp92zqYJfTnteRqczxg7wWI/https/discordsl.com/assets/img/img.png", "The url of the footer icon, leave blank to disable.");
	g_cvSteamWebAPIKey = CreateConVar("sm_surftimer_discord_steam_api_key", "", "Allows the use of the player profile picture, leave blank to disable. The key can be obtained here: https://steamcommunity.com/dev/apikey", FCVAR_PROTECTED);
	g_cvKSFStyle = CreateConVar("sm_ksf_style_announcement", "", "Use the KSF style for announcements (1) or the regular style (0)", _, true, 0.0, true, 1.0);
	g_cvHostname = FindConVar("hostname");
	g_cvHostname.GetString( g_szHostname, sizeof( g_szHostname ) );
	g_cvHostname.AddChangeHook( OnConVarChanged );
	RegAdminCmd("sm_ck_discordtest", CommandDiscordTest, ADMFLAG_ROOT, "Test the discord announcement");

	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	AutoExecConfig(true, "SurfTimer-Discord");
}

public void OnAllPluginsLoaded()
{
	g_bIsSurfTimerEnabled = LibraryExists("surftimer");
}


public void OnLibraryAdded(const char[] name)
{
	g_bIsSurfTimerEnabled = StrEqual(name, "surftimer") ? true : g_bIsSurfTimerEnabled;
}


public void OnLibraryRemoved(const char[] name)
{
	g_bIsSurfTimerEnabled = StrEqual(name, "surftimer") ? false : g_bIsSurfTimerEnabled;
}


public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_cvHostname.GetString(g_szHostname, sizeof g_szHostname);
}

public Action CommandDiscordTest(int client, int args)
{
	surftimer_OnNewRecord(client, 0, "00:00:00", "-00:00:00", -1);
	PrintToChat(client, "[SurfTimer-Discord] Sending the message.");
	return Plugin_Handled;
}

public void OnMapStart()
{
	GetCurrentMap(g_szCurrentMap, sizeof g_szCurrentMap);
	RemoveWorkshop(g_szCurrentMap, sizeof g_szCurrentMap);
	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);
}

public void surftimer_OnNewRecord(int client, int style, char[] time, char[] timeDif, int bonusGroup)
{
	if(!StrEqual(g_szApiKey, ""))
		GetProfilePictureURL(client, time, timeDif);
	else
		sendDiscordAnnouncement(client, time, timeDif);
}

stock void sendDiscordAnnouncement(int client, char[] szTime, char[] szTimeDif)
{
	//Get the WebHook
	char webhook[1024], webhookName[1024];
	GetConVarString(g_cvWebhook, webhook, 1024);
	GetConVarString(g_cvBotUsername, webhookName, 1024);
	if (StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	char szPlayerID[256], szSteamId64[64], szName[128];
	GetClientName(client, szName, sizeof szName);
	GetClientAuthId(client, AuthId_SteamID64, szPlayerID, sizeof szPlayerID);
	Format(szPlayerID, sizeof szPlayerID, "[%s](https://steamcommunity.com/profiles/%s)", szName, szSteamId64);

	//Test which style to use
	if (!g_cvKSFStyle.BoolValue)
	{
		DiscordWebHook hook = new DiscordWebHook(webhook);
		char szMention[128];
		hook.SlackMode = true;
		GetConVarString(g_cvMention, szMention, 128);
		if (!StrEqual(szMention, "")) //Checks if mention is disabled
		{
			hook.SetContent(szMention);
		}
		hook.SetUsername(webhookName);

		//Format the message
		char szTitle[256];
		GetConVarString(g_cvTitle, szTitle, 256);
		ReplaceString(szTitle, sizeof szTitle, "{Server_Name}", g_szHostname);
		//Create the embed message
		MessageEmbed Embed = new MessageEmbed();

		char szColor[128];
		GetConVarString(g_cvMainEmbedColor, szColor, 128);

		char szTimeDiscord[128];
		Format(szTimeDiscord, sizeof(szTimeDiscord), "%s (%s)", szTime, szTimeDif);

		Embed.SetColor(szColor);
		Embed.SetTitle(szTitle);
		Embed.AddField("Player", szPlayerID, true);
		Embed.AddField("Time", szTimeDiscord, true);
		Embed.AddField("Map", g_szCurrentMap, true);

		char szUrlMain[1024];
		GetConVarString(g_cvMainUrlRoot, szUrlMain, 1024);
		char szUrlThumb[1024];
		GetConVarString(g_cvThumbnailUrlRoot, szUrlThumb, 1024);
		if(StrEqual(g_szPictureURL, ""))
			Embed.SetThumb(szUrlThumb);
		else
		{
			Embed.SetImage(szUrlMain);
			Embed.SetThumb(g_szPictureURL);
		}

		char szFooterUrl[1024];
		GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
		if (!StrEqual(szFooterUrl, ""))
		Embed.SetFooterIcon(szFooterUrl);
		char buffer[1000];
		Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
		Embed.SetFooter( buffer );

		//Send the message
		hook.Embed(Embed);

		hook.Send();
		delete hook;
	}
	else
	{
		// Send Discord Announcement
		DiscordWebHook hook = new DiscordWebHook(webhook);
		hook.SlackMode = true;

		hook.SetUsername(webhookName);

		// Format The Message
		char szMessage[256];

		Format(szMessage, sizeof(szMessage), "```md\n# New Server Record on %s #\n\n[%s] beat the server record on < %s > with a time of < %s (%s) > ]:```", g_szHostname, szName, g_szCurrentMap, szTime, szTimeDif);

		hook.SetContent(szMessage);
		hook.Send();
		delete hook;
	}
}

stock void GetProfilePictureURL(int client, char[] time, char[] timeDif)
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteString(time);
	pack.WriteString(timeDif);
	pack.Reset();

	char szSteamID[64];
	GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof szSteamID, true);

	char szURL[256] = "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/";
	Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, szURL);
	SteamWorks_SetHTTPRequestNetworkActivityTimeout(request, 10);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "key", g_szApiKey);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "steamids", szSteamID);
	SteamWorks_SetHTTPRequestGetOrPostParameter(request, "format", "json");
	SteamWorks_SetHTTPCallbacks(request, OnResponseReceived);
	SteamWorks_SetHTTPRequestContextValue(request, pack);
	bool bIsSentRequest = SteamWorks_SendHTTPRequest(request);
	if(!bIsSentRequest)
		PrintToServer("[SurfTimer-Discord] There was an error when sending the request to the Steam API.");
	PrintToConsoleAll("Request sent");
}

stock void OnResponseReceived(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode, DataPack pack)
{
	char szTime[32];
	char szTimeDif[32];
	pack.Reset();
	int client = pack.ReadCell();
	ReadPackString(pack, szTime, sizeof szTime);
	ReadPackString(pack, szTimeDif, sizeof szTimeDif);

	if (eStatusCode != k_EHTTPStatusCode200OK || !bRequestSuccessful || bFailure)
	{
		PrintToServer("[SurfTimer-Discord] There was an error in the Steam API's response. Is your API key valid ?");
		sendDiscordAnnouncement(client, szTime, szTimeDif);
		return;
	}
	PrintToServer("Request received");
	int iSize;
	SteamWorks_GetHTTPResponseBodySize(hRequest, iSize);
	if (iSize >= 2048)
		return;
	char[] szData = new char[iSize];
	SteamWorks_GetHTTPResponseBodyData(hRequest, szData, iSize);
	PrintToServer("The data %s", szData);
	Handle hData = json_load(szData);
	Handle hResponse = json_object_get(hData, "response");
	Handle hPlayers = json_object_get(hResponse, "players");
	int playerslen = json_array_size(hPlayers);

	Handle hPlayer;
	for (int i = 0; i < playerslen; i++)
	{
		hPlayer = json_array_get(hPlayers, i);
		json_object_get_string(hPlayer, "avatarmedium", g_szPictureURL, sizeof g_szPictureURL);
	}
	delete hData;
	delete hResponse;
	delete hPlayer;
	delete hPlayer;
	sendDiscordAnnouncement(client, szTime, szTimeDif);
}

stock void RemoveWorkshop(char[] szMapName, int len)
{
	int i = 0;
	char szBuffer[16], szCompare[1] = "/";

	// Return if "workshop/" is not in the mapname
	if(ReplaceString(szMapName, len, "workshop/", "", true) != 1)
	return;

	// Find the index of the last /
	do
	{
		szBuffer[i] = szMapName[i];
		i++;
	}
	while(szMapName[i] != szCompare[0]);
	szBuffer[i] = szCompare[0];
	ReplaceString(szMapName, len, szBuffer, "", true);
}