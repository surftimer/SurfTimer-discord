#include <colorvariables>
#include <ripext>
#include <sourcemod>
#include <surftimer>
#include <discordWebhookAPI>
#pragma newdecls required
#pragma semicolon 1


public Plugin myinfo =
{
	name = "SurfTimer-Discord",
	author = "Sarrus",
	description = "A module for SurfTimer-Official to send Discord Notifications when a new record is set.",
	version = "1.0",
	url = "https://github.com/Sarrus1/SurfTimer-discord"
};


HTTPRequest connection;

ConVar g_cvAnnounceMainWebhook;
ConVar g_cvAnnounceBonusWebhook;
ConVar g_cvReportBugsDiscord;
ConVar g_cvCallAdminDiscord;
ConVar g_cvMainUrlRoot;
ConVar g_cvAnnounceMention;
ConVar g_cvBugReportMention;
ConVar g_cvCallAdminMention;
ConVar g_cvBotUsername;
ConVar g_cvFooterUrl;
ConVar g_cvMainEmbedColor;
ConVar g_cvBonusEmbedColor;
ConVar g_cvBugReportEmbedColor;
ConVar g_cvCallAdminEmbedColor;
ConVar g_cvSteamWebAPIKey;
ConVar g_cvHostname;
ConVar g_cvKSFStyle;
ConVar g_cvBonusImage;
ConVar g_cvProfileUrlType;
ConVar g_cvWebStatsUrl;

char g_szHostname[256];
char g_szApiKey[256];
char g_szCurrentMap[256];
char g_szPictureURL[512];
char g_szBugType[MAXPLAYERS + 1][32];
char g_szProfileUrl[256];

bool g_bIsSurfTimerEnabled = false;
bool g_bRedirectToSteam;

enum WaitingFor
{
	None,
	Calladmin,
	BugReport
}

WaitingFor g_iWaitingFor[MAXPLAYERS + 1];

public void OnPluginStart()
{
	g_cvAnnounceMainWebhook = CreateConVar("sm_surftimer_discord_announce_main_webhook", "", "The webhook to the discord channel where you want main record messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceBonusWebhook = CreateConVar("sm_surftimer_discord_announce_bonus_webhook", "", "The webhook to the discord channel where you want bonus record messages to be sent.", FCVAR_PROTECTED);
	g_cvReportBugsDiscord = CreateConVar("sm_surftimer_discord_report_bug_webhook", "", "The webhook to the discord channel where you want bug report messages to be sent.", FCVAR_PROTECTED);
	g_cvCallAdminDiscord = CreateConVar("sm_surftimer_discord_calladmin_webhook", "", "The webhook to the discord channel where you want calladmin messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceMention = CreateConVar("sm_surftimer_discord_announce_mention", "@here", "Optional discord mention to ping users when a new record has been set.");
	g_cvBugReportMention = CreateConVar("sm_surftimer_discord_bug_mention", "@here", "Optional discord mention to notify users when a bug report has been sent.");
	g_cvCallAdminMention = CreateConVar("sm_surftimer_discord_calladmin_mention", "@here", "Optional discord mention to notify users when a calladmin has been sent.");
	g_cvMainEmbedColor = CreateConVar("sm_surftimer_discord_main_embed_color", "#00ffff", "Color of the embed for when main wr is beaten");
	g_cvBonusEmbedColor = CreateConVar("sm_surftimer_discord_bonus_embed_color", "#ff0000", "Color of the embed for when bonus wr is beaten");
	g_cvBugReportEmbedColor = CreateConVar("sm_surftimer_discord_bug_embed_color", "#ff0000", "Color of the embed for when a bug report is sent");
	g_cvCallAdminEmbedColor = CreateConVar("sm_surftimer_discord_admin_embed_color", "#ff0000", "Color of the embed for when an admin is called");
	g_cvMainUrlRoot = CreateConVar("sm_surftimer_discord_main_url_root", "https://raw.githubusercontent.com/Sayt123/SurfMapPics/master/csgo/", "The base url of where the Discord images are stored. Leave blank to disable.");
	g_cvBotUsername = CreateConVar("sm_surftimer_discord_username", "SurfTimer BOT", "Username of the bot");
	g_cvFooterUrl = CreateConVar("sm_surftimer_discord_footer_url", "https://images-ext-1.discordapp.net/external/tfTL-r42Kv1qP4FFY6sQYDT1BBA2fXzDjVmcknAOwNI/https/images-ext-2.discordapp.net/external/3K6ho0iMG_dIVSlaf0hFluQFRGqC2jkO9vWFUlWYOnM/https/images-ext-2.discordapp.net/external/aO9crvExsYt5_mvL72MFLp92zqYJfTnteRqczxg7wWI/https/discordsl.com/assets/img/img.png", "The url of the footer icon, leave blank to disable.");
	g_cvSteamWebAPIKey = CreateConVar("sm_surftimer_discord_steam_api_key", "", "Allows the use of the player profile picture, leave blank to disable. The key can be obtained here: https://steamcommunity.com/dev/apikey", FCVAR_PROTECTED);
	g_cvBonusImage = CreateConVar("sm_surftimer_discord_bonus_image", "1", "Do bonuses have a custom image such as surf_ivory_b1.jpg (1) or not (0).", _, true, 0.0, true, 1.0);
	g_cvKSFStyle = CreateConVar("sm_surftimer_discord_announcement", "0", "Use the KSF style for announcements (1) or the regular style (0)", _, true, 0.0, true, 1.0);
	g_cvProfileUrlType = CreateConVar("sm_surftimer_discord_profile_url_type", "0", "Profile URL redirect to Steam (0) or to your Webstats (1)", _, true, 0.0, true, 1.0);
	g_cvWebStatsUrl = CreateConVar("sm_surftimer_discord_webstats_url", "", "Your webstats URL eg. \"https://www.mywebstats.com\" (only specify if using \"sm_surftimer_discord_profile_url_type 1\")");

	g_cvHostname = FindConVar("hostname");
	g_cvHostname.GetString(g_szHostname, sizeof g_szHostname);
	g_cvHostname.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_ck_discordtest", CommandDiscordTest, ADMFLAG_ROOT, "Test the discord announcement");
	RegConsoleCmd("sm_calladmin", CommandCallAdmin, "Send a calladmin request to a discord server.");
	RegConsoleCmd("sm_bug", CommandReportBug, "Send a bug report to a discord server.");

	AddCommandListener(SayHook, "say");
	AddCommandListener(SayHook, "say_team");

	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	g_bRedirectToSteam = GetConVarBool(g_cvProfileUrlType);

	if(g_bRedirectToSteam)
		GetConVarString(g_cvWebStatsUrl, g_szProfileUrl, sizeof g_szProfileUrl);
	else
		Format(g_szProfileUrl, sizeof g_szProfileUrl, "https://steamcommunity.com/profiles");

	AutoExecConfig(true, "SurfTimer-Discord");

	LoadTranslations("SurfTimer-discord.phrases.txt");
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

public void OnClientDisconnect(int iClient)
{
	g_szBugType[iClient] = "";
	g_iWaitingFor[iClient] = None;
}

public void OnClientConnected(int iClient)
{
	g_szBugType[iClient] = "";
	g_iWaitingFor[iClient] = None;
}

public Action CommandDiscordTest(int client, int args)
{
	CPrintToChat(client, "{blue}[SurfTimer-Discord] {green}Sending main record test message.");
	surftimer_OnNewRecord(client, 0, "00:00:00", "-00:00:00", -1);
	CPrintToChat(client, "{blue}[SurfTimer-Discord] {green}Sending bonus record test message.");
	surftimer_OnNewRecord(client, 0, "00:00:00", "-00:00:00", 1);
	return Plugin_Handled;
}

public Action CommandCallAdmin(int client, int args)
{
	CPrintToChat(client, "{blue}[SurfTimer-Discord] %t", "CallAdmin Callback");
	g_iWaitingFor[client] = Calladmin;
	return Plugin_Handled;
}

public Action CommandReportBug(int client, int args)
{
	ReportBugMenu(client);
	return Plugin_Handled;
}

public void ReportBugMenu(int client)
{
	Menu menu = CreateMenu(ReportBugHandler);
	SetMenuTitle(menu, "Choose a bug type");
	AddMenuItem(menu, "Map Bug", "Map Bug");
	AddMenuItem(menu, "SurfTimer Bug", "SurfTimer Bug");
	AddMenuItem(menu, "Server Bug", "Server Bug");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int ReportBugHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		GetMenuItem(menu, param2, g_szBugType[param1], 32);
		g_iWaitingFor[param1] = BugReport;
		CPrintToChat(param1, "{blue}[SurfTimer-Discord] %t", "BugReport Callback");
	}
	else if(action == MenuAction_End)
		delete menu;
}

public Action SayHook(int client, const char[] command, int args)
{
	if(!IsValidClient(client))
		return Plugin_Continue;

	if(g_iWaitingFor[client] == None)
		return Plugin_Continue;

	char szText[1024];
	GetCmdArgString(szText, sizeof szText);

	StripQuotes(szText);
	TrimString(szText);

	if(StrEqual(szText, "cancel"))
	{
		g_iWaitingFor[client] = None;
		CPrintToChat(client, "{blue}[SurfTimer-Discord] %t", "Cancelled");
		return Plugin_Handled;
	}

	switch(g_iWaitingFor[client])
	{
		case Calladmin:
		{
			g_iWaitingFor[client] = None;
			SendCallAdmin(client, szText);
		}
		case BugReport:
		{
			g_iWaitingFor[client] = None;
			SendBugReport(client, szText);
		}
		default:
		{
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public void SendBugReport(int iClient, char[] szText)
{
	char webhook[1024];
	GetConVarString(g_cvReportBugsDiscord, webhook, 1024);
	if(StrEqual(webhook, ""))
		return;

	// Send Discord Announcement
	Webhook hook = new Webhook();

	char szMention[128];
	GetConVarString(g_cvBugReportMention, szMention, sizeof szMention);
	if(!StrEqual(szMention, "")) //Checks if mention is disabled
	{
		hook.SetContent(szMention);
	}

	char szBugTrackerName[64];
	GetConVarString(g_cvBotUsername, szBugTrackerName, sizeof g_cvBotUsername);

	hook.SetUsername(szBugTrackerName);

	Embed embed = new Embed();

	embed.SetColor(g_cvBugReportEmbedColor.IntValue);

	// Format Title
	char szTitle[256];
	Format(szTitle, sizeof szTitle, "__**Bug Type**__ %s - __**Map**__ %s", g_szBugType[iClient], g_szCurrentMap);
	embed.SetTitle(szTitle);

	// Format Message
	char szPlayerID[256], szSteamId[64], szName[MAX_NAME_LENGTH];
	GetClientName(iClient, szName, sizeof szName);

	if(g_bRedirectToSteam)
		GetClientAuthId(iClient, AuthId_SteamID64, szSteamId, sizeof szSteamId);
	else
		GetClientAuthId(iClient, AuthId_Steam2, szSteamId, sizeof szSteamId);

	Format(szPlayerID, sizeof szPlayerID, "[%s](%s/%s)", szName, g_szProfileUrl, szSteamId);

	EmbedField field = new EmbedField("Player", szPlayerID, true);
	embed.AddField(field);
	field = new EmbedField("Description", szText, false);
	embed.AddField(field);

	// Add Footer
	EmbedFooter footer = new EmbedFooter();
	char buffer[1000];
	Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
	footer.SetText(buffer);

	char szFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
	if(!StrEqual(szFooterUrl, ""))
	{
		footer.SetIconURL(szFooterUrl);
		embed.SetFooter(footer);
	}

	hook.AddEmbed(embed);
	hook.Execute(webhook, OnWebHookExecuted);
	delete hook;
	delete field;
	delete footer;
	delete embed;

	CPrintToChat(iClient, "{blue}[SurfTimer-Discord] %t", "BugReport Sent");
}

public void SendCallAdmin(int iClient, char[] szText)
{
	char webhook[1024];
	GetConVarString(g_cvCallAdminDiscord, webhook, 1024);
	if(StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	// Send Discord Announcement
	Webhook hook = new Webhook();

	char szMention[128];
	GetConVarString(g_cvCallAdminMention, szMention, sizeof szMention);
	if(!StrEqual(szMention, "")) //Checks if mention is disabled
	{
		hook.SetContent(szMention);
	}
	char szCalladminName[64];
	GetConVarString(g_cvBotUsername, szCalladminName, sizeof szCalladminName);

	hook.SetUsername(szCalladminName);

	Embed embed = new Embed();

	embed.SetColor(g_cvCallAdminEmbedColor.IntValue);

	// Format title
	char szTitle[256];
	Format(szTitle, sizeof szTitle, "__**Admin called on %s", g_szCurrentMap);
	embed.SetTitle(szTitle);

	// Format Message
	char szPlayerID[256], szSteamId[64], szName[MAX_NAME_LENGTH];
	GetClientName(iClient, szName, sizeof szName);
	
	if(g_bRedirectToSteam)
		GetClientAuthId(iClient, AuthId_SteamID64, szSteamId, sizeof szSteamId);
	else
		GetClientAuthId(iClient, AuthId_Steam2, szSteamId, sizeof szSteamId);

	Format(szPlayerID, sizeof szPlayerID, "[%s](%s/%s)", szName, g_szProfileUrl, szSteamId);

	EmbedField field = new EmbedField("Player", szPlayerID, false);
	embed.AddField(field);
	field = new EmbedField("Reason", szText, false);
	embed.AddField(field);

	// Add Footer
	EmbedFooter footer = new EmbedFooter();
	char buffer[1000];
	Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
	footer.SetText(buffer);

	char szFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
	if(!StrEqual(szFooterUrl, ""))
	{
		footer.SetIconURL(szFooterUrl);
		embed.SetFooter(footer);
	}

	hook.AddEmbed(embed);
	hook.Execute(webhook, OnWebHookExecuted);
	delete hook;
	delete field;
	delete footer;
	delete embed;

	CPrintToChat(iClient, "{blue}[SurfTimer-Discord] %t", "CallAdmin Sent");
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
		GetProfilePictureURL(client, style, time, timeDif, bonusGroup);
	else
		sendDiscordAnnouncement(client, style, time, timeDif, bonusGroup);
}

stock void sendDiscordAnnouncement(int client, int style, char[] szTime, char[] szTimeDif, int bonusGroup)
{
	//Get the WebHook
	char webhook[1024], webhookName[1024];
	GetConVarString(bonusGroup == -1 ? g_cvAnnounceMainWebhook : g_cvAnnounceBonusWebhook, webhook, 1024);
	GetConVarString(g_cvBotUsername, webhookName, 1024);
	if(StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	char szPlayerID[256], szSteamId[64], szName[MAX_NAME_LENGTH];
	GetClientName(client, szName, sizeof szName);

	if(g_bRedirectToSteam)
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof szSteamId);
	else
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof szSteamId);

	Format(szPlayerID, sizeof szPlayerID, "[%s](%s/%s)", szName, g_szProfileUrl, szSteamId);

	//Test which style to use
	if(!g_cvKSFStyle.BoolValue)
	{
		
		char szMention[128];
		GetConVarString(g_cvAnnounceMention, szMention, 128);
		Webhook hook = new Webhook(szMention);

		hook.SetUsername(webhookName);

		char szPlayerStyle[128];
		switch(style)
		{
			case 0: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Normal");
			case 1: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Sideways");
			case 2: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Half Sideways");
			case 3: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Backwards");
			case 4: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Low Gravity");
			case 5: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Slow Motion");
			case 6: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Fast Forward");
			case 7: strcopy(szPlayerStyle, sizeof szPlayerStyle, "Free Style");
		}

		char szTitle[256];
		if(bonusGroup == -1)
		{
			Format(szTitle, sizeof(szTitle), "__**New World Record**__ | **%s** - **%s**", g_szCurrentMap, szPlayerStyle);
		}
		else
		{
			Format(szTitle, sizeof(szTitle), "__**New Bonus #%i World Record**__ | **%s** - **%s**", bonusGroup, g_szCurrentMap, szPlayerStyle);
		}

		//Create the embed message
		Embed embed = new Embed();

		embed.SetColor(bonusGroup == -1 ? g_cvMainEmbedColor.IntValue : g_cvBonusEmbedColor.IntValue);

		char szTimeDiscord[128];
		Format(szTimeDiscord, sizeof(szTimeDiscord), "%s (%s)", szTime, szTimeDif);

		embed.SetTitle(szTitle);
		EmbedField field = new EmbedField("Player", szPlayerID, true);
		embed.AddField(field);
		field = new EmbedField("Time", szTimeDiscord, true);
		embed.AddField(field);

		char szUrlMain[1024];
		GetConVarString(g_cvMainUrlRoot, szUrlMain, 1024);
		StrCat(szUrlMain, sizeof szUrlMain, g_szCurrentMap);
		if(g_cvBonusImage.BoolValue && bonusGroup != -1)
		{
			char szGroup[8];
			IntToString(bonusGroup, szGroup, sizeof szGroup);
			StrCat(szUrlMain, sizeof(szUrlMain), "_b");
			StrCat(szUrlMain, sizeof(szUrlMain), szGroup);
		}

		StrCat(szUrlMain, sizeof szUrlMain, ".jpg");
		EmbedImage image = new EmbedImage(szUrlMain);
		embed.SetImage(image);
		EmbedThumbnail thumb = new EmbedThumbnail(g_szPictureURL);
		embed.SetThumbnail(thumb);

		// Add Footer
		EmbedFooter footer = new EmbedFooter();
		char buffer[1000];
		Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
		footer.SetText(buffer);

		char szFooterUrl[1024];
		GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
		if(!StrEqual(szFooterUrl, ""))
		{
			footer.SetIconURL(szFooterUrl);
			embed.SetFooter(footer);
		}

		hook.AddEmbed(embed);
		hook.Execute(webhook, OnWebHookExecuted);
		delete hook;
		delete field;
		delete footer;
		delete embed;
		delete thumb;
		delete image;
	}
	else
	{
		// Send Discord Announcement
		Webhook hook = new Webhook();

		hook.SetUsername(webhookName);

		// Format The Message
		char szMessage[256];

		if(bonusGroup == -1 )
		{
			Format(szMessage, sizeof(szMessage), "```md\n# New Server Record on %s #\n\n[%s] beat the server record on < %s > with a time of < %s (%s) > ]:```", g_szHostname, szName, g_szCurrentMap, szTime, szTimeDif);
		}
		else
		{
			Format(szMessage, sizeof(szMessage), "```md\n# New Bonus #%i Record on %s #\n\n[%s] beat the bonus #%i record on < %s > with a time of < %s (%s) > ]:```", bonusGroup, g_szHostname, szName, bonusGroup, g_szCurrentMap, szTime, szTimeDif);
		}

		hook.SetContent(szMessage);
		hook.Execute(webhook, OnWebHookExecuted);
		delete hook;
	}
}

stock void GetProfilePictureURL(int client, int style, char[] time, char[] timeDif, int bonusGroup)
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(style);
	pack.WriteString(time);
	pack.WriteString(timeDif);
	pack.WriteCell(bonusGroup);
	pack.Reset();

	char szRequestBuffer[1024], szSteamID[64];
	
	GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof szSteamID, true);

	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	Format(szRequestBuffer, sizeof szRequestBuffer, "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=json", g_szApiKey,szSteamID);
	connection = new HTTPRequest(szRequestBuffer);
	connection.Get(OnResponseReceived, pack);
}


stock void OnResponseReceived(HTTPResponse response, DataPack pack)
{
	char szTime[32];
	char szTimeDif[32];
	pack.Reset();
	int client = pack.ReadCell();
	int style = pack.ReadCell();
	ReadPackString(pack, szTime, sizeof szTime);
	ReadPackString(pack, szTimeDif, sizeof szTimeDif);
	int bonusGroup = pack.ReadCell();

	if (response.Status != HTTPStatus_OK) 
		return;
	
	JSONObject objects = view_as<JSONObject>(response.Data);
	JSONObject Response = view_as<JSONObject>(objects.Get("response"));
	JSONArray players = view_as<JSONArray>(Response.Get("players"));
	int playerlen = players.Length;
	
	JSONObject player;
	for (int i = 0; i < playerlen; i++)
	{
		player = view_as<JSONObject>(players.Get(i));
		player.GetString("avatarmedium", g_szPictureURL, sizeof(g_szPictureURL));
		delete player;
  }
	delete objects;
	delete Response;
	delete players;
	delete player;
	delete connection;
	sendDiscordAnnouncement(client, style, szTime, szTimeDif, bonusGroup);
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
	} while(szMapName[i] != szCompare[0]);
	szBuffer[i] = szCompare[0];
	ReplaceString(szMapName, len, szBuffer, "", true);
}

stock bool IsValidClient(int iClient, bool bNoBots = true)
{
	if(iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || (bNoBots && IsFakeClient(iClient)))
	{
		return false;
	}
	return IsClientInGame(iClient);
}

public void OnWebHookExecuted(HTTPResponse response, DataPack pack)
{
	int client = pack.ReadCell();

	PrintToServer("Processed client n°%s's webhook, status %d", client, response.Status);
	if (response.Status != HTTPStatus_NoContent)
	{
		PrintToServer("An error has occured while sending the webhook.");
		return;
	}
	PrintToServer("The webhook has been sent successfuly.");
}