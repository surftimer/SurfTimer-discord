#include <colorvariables>
#include <discordWebhookAPI>
#include <ripext>
#include <sourcemod>
#include <surftimer>
#undef REQUIRE_PLUGIN
#include <mapchallenge>
#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name        = "SurfTimer-Discord",
	author      = "Sarrus",
	description = "A module for SurfTimer-Official to send Discord Notifications when a new record is set.",
	version     = "2.5.5",
	url         = "https://github.com/Sarrus1/SurfTimer-discord"
};

HTTPRequest connection;

ConVar g_cvAnnounceMainWebhook;
ConVar g_cvAnnounceStageWebhook;
ConVar g_cvAnnounceBonusWebhook;
ConVar g_cvAnnounceStyleMainWebhook;
ConVar g_cvAnnounceStyleStageWebhook;
ConVar g_cvAnnounceStyleBonusWebhook;
ConVar g_cvAnnounceChallengeWebhook;
ConVar g_cvAnnounceChallengeEndWebhook;
ConVar g_cvAnnounceChallengeMention;
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
ConVar g_cvEnableCallAdmin;
ConVar g_cvEnableBugReport;

char g_szHostname[256];
char g_szApiKey[256];
char g_szCurrentMap[256];
char g_szPictureURL[512];
char g_szBugType[MAXPLAYERS + 1][32];
char g_szProfileUrl[256];

bool g_bIsSurfTimerEnabled = false;
bool g_bIsChallengeEnabled = false;
bool g_bDebugging          = false;

enum WaitingFor
{
	None,
	Calladmin,
	BugReport
}

enum struct TOP5_entry{
	char szPlayerName[MAX_NAME_LENGTH];
	char szRuntimeFormatted[32];
	char szRuntimeDifference[32];
}

WaitingFor g_iWaitingFor[MAXPLAYERS + 1];

public void OnPluginStart()
{
	g_cvAnnounceMainWebhook       = CreateConVar("sm_surftimer_discord_announce_main_webhook", "", "The webhook to the discord channel where you want main record messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceStageWebhook      = CreateConVar("sm_surftimer_discord_announce_stage_webhook", "", "The webhook to the discord channel where you want stage record messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceBonusWebhook      = CreateConVar("sm_surftimer_discord_announce_bonus_webhook", "", "The webhook to the discord channel where you want bonus record messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceStyleMainWebhook  = CreateConVar("sm_surftimer_discord_announce_style_main_webhook", "", "The webhook to the discord channel where you want style main record messages to be sent. Leave empty to disable", FCVAR_PROTECTED);
	g_cvAnnounceStyleStageWebhook = CreateConVar("sm_surftimer_discord_announce_style_stage_webhook", "", "The webhook to the discord channel where you want style stage record messages to be sent. Leave empty to disable", FCVAR_PROTECTED);
	g_cvAnnounceStyleBonusWebhook = CreateConVar("sm_surftimer_discord_announce_style_bonus_webhook", "", "The webhook to the discord channel where you want style bonus record messages to be sent. Leave empty to disable", FCVAR_PROTECTED);
	g_cvReportBugsDiscord         = CreateConVar("sm_surftimer_discord_report_bug_webhook", "", "The webhook to the discord channel where you want bug report messages to be sent.", FCVAR_PROTECTED);
	g_cvCallAdminDiscord          = CreateConVar("sm_surftimer_discord_calladmin_webhook", "", "The webhook to the discord channel where you want calladmin messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceMention           = CreateConVar("sm_surftimer_discord_announce_mention", "@here", "Optional discord mention to ping users when a new record has been set.");
	g_cvBugReportMention          = CreateConVar("sm_surftimer_discord_bug_mention", "@here", "Optional discord mention to notify users when a bug report has been sent.");
	g_cvCallAdminMention          = CreateConVar("sm_surftimer_discord_calladmin_mention", "@here", "Optional discord mention to notify users when a calladmin has been sent.");
	g_cvMainEmbedColor            = CreateConVar("sm_surftimer_discord_main_embed_color", "0x00ffff", "Color of the embed for when main wr is beaten. Replace the usual '#' with '0x'.");
	g_cvBonusEmbedColor           = CreateConVar("sm_surftimer_discord_bonus_embed_color", "0xff0000", "Color of the embed for when bonus wr is beaten. Replace the usual '#' with '0x'.");
	g_cvBugReportEmbedColor       = CreateConVar("sm_surftimer_discord_bug_embed_color", "0xff0000", "Color of the embed for when a bug report is sent. Replace the usual '#' with '0x'.");
	g_cvCallAdminEmbedColor       = CreateConVar("sm_surftimer_discord_admin_embed_color", "0xff0000", "Color of the embed for when an admin is called. Replace the usual '#' with '0x'.");
	g_cvMainUrlRoot               = CreateConVar("sm_surftimer_discord_main_url_root", "https://raw.githubusercontent.com/Sayt123/SurfMapPics/Maps-and-bonuses/csgo/", "The base url of where the Discord images are stored. Leave blank to disable.");
	g_cvBotUsername               = CreateConVar("sm_surftimer_discord_username", "SurfTimer BOT", "Username of the bot");
	g_cvFooterUrl                 = CreateConVar("sm_surftimer_discord_footer_url", "https://images-ext-1.discordapp.net/external/tfTL-r42Kv1qP4FFY6sQYDT1BBA2fXzDjVmcknAOwNI/https/images-ext-2.discordapp.net/external/3K6ho0iMG_dIVSlaf0hFluQFRGqC2jkO9vWFUlWYOnM/https/images-ext-2.discordapp.net/external/aO9crvExsYt5_mvL72MFLp92zqYJfTnteRqczxg7wWI/https/discordsl.com/assets/img/img.png", "The url of the footer icon, leave blank to disable.");
	g_cvSteamWebAPIKey            = CreateConVar("sm_surftimer_discord_steam_api_key", "", "Allows the use of the player profile picture, leave blank to disable. The key can be obtained here: https://steamcommunity.com/dev/apikey", FCVAR_PROTECTED);
	g_cvBonusImage                = CreateConVar("sm_surftimer_discord_bonus_image", "1", "Do bonuses have a custom image such as surf_ivory_b1.jpg (1) or not (0).", _, true, 0.0, true, 1.0);
	g_cvKSFStyle                  = CreateConVar("sm_surftimer_discord_announcement", "0", "Use the KSF style for announcements (1) or the regular style (0)", _, true, 0.0, true, 1.0);
	g_cvProfileUrlType            = CreateConVar("sm_surftimer_discord_profile_url_type", "0", "Profile URL redirect to Steam (0) or to your Webstats (1)", _, true, 0.0, true, 1.0);
	g_cvWebStatsUrl               = CreateConVar("sm_surftimer_discord_webstats_url", "", "Your webstats URL eg. \"https://www.mywebstats.com\" (only specify if using \"sm_surftimer_discord_profile_url_type 1\")");
	g_cvEnableCallAdmin           = CreateConVar("sm_surftimer_discord_enable_calladmin", "1", "Enable or disable the !calladmin command. 1 to enable, 0 to disable. Requires a plugin restart.", FCVAR_REPLICATED, true, 0.0, true, 1.0);
	g_cvEnableBugReport           = CreateConVar("sm_surftimer_discord_enable_bug_report", "1", "Enable or disable the !bug command. 1 to enable, 0 to disable. Requires a plugin restart.", FCVAR_REPLICATED, true, 0.0, true, 1.0);

	g_cvAnnounceChallengeWebhook  = CreateConVar("sm_mapchallenge_discord_announce_challenge_webhook", "", "The webhook to the discord channel where you want challenge messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceChallengeEndWebhook = CreateConVar("sm_mapchallenge_discord_announce_challenge_end_webhook", "", "The webhook to the discord channel where you want challenge end messages to be sent.", FCVAR_PROTECTED);
	g_cvAnnounceChallengeMention = CreateConVar("sm_surftimer_discord_challenge_mention", "@here", "Optional discord mention to ping users when a new challenge has been created or has ended.");

	g_cvHostname = FindConVar("hostname");
	g_cvHostname.GetString(g_szHostname, sizeof g_szHostname);
	g_cvHostname.AddChangeHook(OnConVarChanged);

	RegAdminCmd("sm_ck_discordtest", CommandDiscordTest, ADMFLAG_ROOT, "Test the discord announcement");

	AddCommandListener(SayHook, "say");
	AddCommandListener(SayHook, "say_team");

	AutoExecConfig(true, "SurfTimer-Discord");

	LoadTranslations("SurfTimer-discord.phrases.txt");
}

public void OnConfigsExecuted()
{
	if (g_cvEnableCallAdmin.BoolValue)
	{
		RegConsoleCmd("sm_calladmin", CommandCallAdmin, "Send a calladmin request to a discord server.");
	}
	if (g_cvEnableBugReport.BoolValue)
	{
		RegConsoleCmd("sm_bug", CommandReportBug, "Send a bug report to a discord server.");
	}

	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	if (g_cvProfileUrlType.BoolValue)
	{
		GetConVarString(g_cvWebStatsUrl, g_szProfileUrl, sizeof g_szProfileUrl);
	}
	else
	{
		strcopy(g_szProfileUrl, sizeof g_szProfileUrl, "https://steamcommunity.com/profiles");
	}

	checkIfValidName();
}

void checkIfValidName()
{
	char szWebhookName[64];
	GetConVarString(g_cvBotUsername, szWebhookName, sizeof szWebhookName);
	char szForbiddenSubStrings[5][32] = {"@", "#", ":", "```", "discord"};
	char szForbiddenStrings[2][32] = {"everyone", "here"};
	for(int i; i<sizeof(szForbiddenStrings); i++){
		if (StrEqual(szForbiddenStrings[i], szWebhookName)){
			SetFailState("Discord does not allow \"%s\" as a Webhook name.", szForbiddenStrings[i]);
		}
	}
	for(int i; i<sizeof(szForbiddenSubStrings); i++){
		if (StrContains(szWebhookName, szForbiddenSubStrings[i]) != -1){
			SetFailState("Webhook name contains an invalid substring: %s (%s)", szForbiddenSubStrings[i], szWebhookName);
		}
	}
}

public void OnAllPluginsLoaded()
{
	g_bIsSurfTimerEnabled = LibraryExists("surftimer");
	g_bIsChallengeEnabled = LibraryExists("map_challenge");
}

public void OnLibraryAdded(const char[] name)
{
	g_bIsSurfTimerEnabled = StrEqual(name, "surftimer") ? true : g_bIsSurfTimerEnabled;
	g_bIsChallengeEnabled = StrEqual(name, "map_challenge") ? true : g_bIsChallengeEnabled;
}

public void OnLibraryRemoved(const char[] name)
{
	g_bIsSurfTimerEnabled = StrEqual(name, "surftimer") ? false : g_bIsSurfTimerEnabled;
	g_bIsChallengeEnabled = StrEqual(name, "map_challenge") ? false : g_bIsChallengeEnabled;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_cvHostname.GetString(g_szHostname, sizeof g_szHostname);
}

public void OnClientDisconnect(int iClient)
{
	g_szBugType[iClient]   = "";
	g_iWaitingFor[iClient] = None;
}

public void OnClientConnected(int iClient)
{
	g_szBugType[iClient]   = "";
	g_iWaitingFor[iClient] = None;
}

public Action CommandDiscordTest(int client, int args)
{
	if (client == 0)
  {
    CReplyToCommand(0, "This command is only available in game.");
    return Plugin_Handled;
  }
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending main record test message.");
	surftimer_OnNewRecord(client, 0, "00:00:00", "-00:00:00", -1);
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending bonus record test message.");
	surftimer_OnNewRecord(client, 0, "00:00:00", "-00:00:00", 1);
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending stage record test message.");
	surftimer_OnNewWRCP(client, 0, "00:00:00", "-00:00:00", 3, 0.0);
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending {red}styled{green} bonus record test message.");
	surftimer_OnNewRecord(client, 5, "00:00:00", "-00:00:00", 1);
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending {red}styled{green} main record test message.");
	surftimer_OnNewRecord(client, 5, "00:00:00", "-00:00:00", -1);
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending {red}styled{green} stage record test message.");
	surftimer_OnNewWRCP(client, 5, "00:00:00", "-00:00:00", 3, 0.0);
	CReplyToCommand(client, "{blue}[SurfTimer-Discord] {green}Sending {red}Challenge{green} test message.");
	
	mapchallenge_OnNewChallenge(client, "surf_beginner", 0, 420, "Mon Jan 1 00:00:00 1969", "Thu Aug 23 14:55:02 2001");

	ArrayList szTop5 = new ArrayList(sizeof TOP5_entry);
	TOP5_entry temp;

	temp.szPlayerName = "gaben";
	temp.szRuntimeFormatted = "00:10.000";
	temp.szRuntimeDifference = "00:00:000";
	szTop5.PushArray(temp, sizeof temp);

	temp.szPlayerName = "marcelo";
	temp.szRuntimeFormatted = "00:05.000";
	temp.szRuntimeDifference = "00:05:000";
	szTop5.PushArray(temp, sizeof temp);

	temp.szPlayerName = "";
	temp.szRuntimeFormatted = "";
	temp.szRuntimeDifference = "";
	for(int i = 0; i < 4; i++)
		szTop5.PushArray(temp, sizeof temp);

	mapchallenge_OnChallengeEnd(client, "surf_beginner", 0, 420, "Mon Jan 1 00:00:00 1969", "Thu Aug 23 14:55:02 2001", szTop5, 666);
	
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
	if (action == MenuAction_Select)
	{
		GetMenuItem(menu, param2, g_szBugType[param1], 32);
		g_iWaitingFor[param1] = BugReport;
		CPrintToChat(param1, "{blue}[SurfTimer-Discord] %t", "BugReport Callback");
	}
	else if (action == MenuAction_End)
		delete menu;
	
	return 0;
}

public Action SayHook(int client, const char[] command, int args)
{
	if (!IsValidClient(client))
		return Plugin_Continue;

	if (g_iWaitingFor[client] == None)
		return Plugin_Continue;

	char szText[1024];
	GetCmdArgString(szText, sizeof szText);

	StripQuotes(szText);
	TrimString(szText);

	if (StrEqual(szText, "cancel"))
	{
		g_iWaitingFor[client] = None;
		CPrintToChat(client, "{blue}[SurfTimer-Discord] %t", "Cancelled");
		return Plugin_Handled;
	}

	switch (g_iWaitingFor[client])
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
	if (StrEqual(webhook, ""))
		return;

	// Send Discord Announcement
	Webhook hook = new Webhook();

	char szMention[128];
	GetConVarString(g_cvBugReportMention, szMention, sizeof szMention);
	if (!StrEqual(szMention, ""))  // Checks if mention is disabled
	{
		hook.SetContent(szMention);
	}

	char szBugTrackerName[64];
	GetConVarString(g_cvBotUsername, szBugTrackerName, sizeof szBugTrackerName);

	hook.SetUsername(szBugTrackerName);

	Embed embed = new Embed();

	char color[16];
	GetConVarString(g_cvBugReportEmbedColor, color, sizeof color);
	embed.SetColor(StringToInt(color, 16));

	// Format Title
	char szTitle[256];
	Format(szTitle, sizeof szTitle, "__**Bug Type**__ %s - __**Map**__ %s", g_szBugType[iClient], g_szCurrentMap);
	embed.SetTitle(szTitle);

	// Format Message
	char szPlayerID[256], szSteamId[64], szName[MAX_NAME_LENGTH];
	GetClientName(iClient, szName, sizeof szName);

	if (g_cvProfileUrlType.BoolValue)
		GetClientAuthId(iClient, AuthId_Steam2, szSteamId, sizeof szSteamId);
	else
		GetClientAuthId(iClient, AuthId_SteamID64, szSteamId, sizeof szSteamId);

	Format(szPlayerID, sizeof szPlayerID, "[%s](%s/%s)", szName, g_szProfileUrl, szSteamId);

	EmbedField field = new EmbedField("Player", szPlayerID, true);
	embed.AddField(field);
	field = new EmbedField("Description", szText, false);
	embed.AddField(field);

	// Add Footer
	EmbedFooter footer = new EmbedFooter();
	char        buffer[1000];
	Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
	footer.SetText(buffer);

	char szFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
	if (!StrEqual(szFooterUrl, ""))
	{
		footer.SetIconURL(szFooterUrl);
		embed.SetFooter(footer);
	}

	hook.AddEmbed(embed);
	hook.Execute(webhook, OnWebHookExecuted, iClient);
	if (g_bDebugging)
	{
		char szDebugOutput[10000];
		hook.ToString(szDebugOutput, sizeof szDebugOutput);
		PrintToServer(szDebugOutput);
	}
	delete hook;

	CPrintToChat(iClient, "{blue}[SurfTimer-Discord] %t", "BugReport Sent");
}

public void SendCallAdmin(int iClient, char[] szText)
{
	char webhook[1024];
	GetConVarString(g_cvCallAdminDiscord, webhook, 1024);
	if (StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	// Send Discord Announcement
	Webhook hook = new Webhook();

	char szMention[128];
	GetConVarString(g_cvCallAdminMention, szMention, sizeof szMention);
	if (!StrEqual(szMention, ""))  // Checks if mention is disabled
	{
		hook.SetContent(szMention);
	}
	char szCalladminName[64];
	GetConVarString(g_cvBotUsername, szCalladminName, sizeof szCalladminName);

	hook.SetUsername(szCalladminName);

	Embed embed = new Embed();

	char color[16];
	GetConVarString(g_cvCallAdminEmbedColor, color, sizeof color);
	embed.SetColor(StringToInt(color, 16));

	// Format title
	char szTitle[256];
	Format(szTitle, sizeof szTitle, "__**Admin called__ on %s**", g_szCurrentMap);
	embed.SetTitle(szTitle);

	// Format Message
	char szPlayerID[256], szSteamId[64], szName[MAX_NAME_LENGTH];
	GetClientName(iClient, szName, sizeof szName);
	if (g_cvProfileUrlType.BoolValue)
	{
		GetClientAuthId(iClient, AuthId_Steam2, szSteamId, sizeof szSteamId);
	}
	else
	{
		GetClientAuthId(iClient, AuthId_SteamID64, szSteamId, sizeof szSteamId);
	}

	Format(szPlayerID, sizeof szPlayerID, "[%s](%s/%s)", szName, g_szProfileUrl, szSteamId);

	EmbedField field = new EmbedField("Player", szPlayerID, false);
	embed.AddField(field);
	field = new EmbedField("Reason", szText, false);
	embed.AddField(field);

	// Add Footer
	EmbedFooter footer = new EmbedFooter();
	char        buffer[1000];
	Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
	footer.SetText(buffer);

	char szFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
	if (!StrEqual(szFooterUrl, ""))
	{
		footer.SetIconURL(szFooterUrl);
		embed.SetFooter(footer);
	}

	hook.AddEmbed(embed);
	if (g_bDebugging)
	{
		char szDebugOutput[10000];
		hook.ToString(szDebugOutput, sizeof szDebugOutput);
		PrintToServer(szDebugOutput);
	}
	hook.Execute(webhook, OnWebHookExecuted, iClient);
	delete hook;

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
	if (strncmp(g_szApiKey, "", 1) != 0)
		GetProfilePictureURL(client, style, time, timeDif, bonusGroup, -1);
	else
		sendDiscordAnnouncement(client, style, time, timeDif, bonusGroup, -1);
}

public void surftimer_OnNewWRCP(int client, int style, char[] time, char[] timeDif, int stage, float fRunTime)
{
	if (strncmp(g_szApiKey, "", 1) != 0)
		GetProfilePictureURL(client, style, time, timeDif, -1, stage);
	else
		sendDiscordAnnouncement(client, style, time, timeDif, -1, stage);
}

public void mapchallenge_OnNewChallenge(int client, char szMapName[32], int style, int points, char szInitial_Timestamp[32], char szFinal_Timestamp[32]){
	char webhook[1024], webhookName[1024];
	
	GetConVarString(g_cvAnnounceChallengeWebhook, webhook, 1024);
	GetConVarString(g_cvBotUsername, webhookName, 1024);
	if (StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	// Send Discord Announcement
	char szMention[128];
	GetConVarString(g_cvAnnounceChallengeMention, szMention, 128);
	Webhook hook = new Webhook(szMention);

	hook.SetUsername(webhookName);

	char szChallenge_Style[32], szChallenge_Points[32];

	Format(szChallenge_Style, sizeof(szChallenge_Style), "%s", "");
	switch (style)
	{
		case 0: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Normal");
		case 1: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Sideways");
		case 2: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Half Sideways");
		case 3: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Backwards");
		case 4: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Low Gravity");
		case 5: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Slow Motion");
		case 6: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Fast Forward");
		case 7: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Free Style");
	}

	Format(szChallenge_Points, sizeof(szChallenge_Points), "%d", points);

	// Format title
	char szTitle[256];
	Format(szTitle, sizeof szTitle, "__**New Challenge**__");

	Embed embed = new Embed();

	char color[16];
	GetConVarString(g_cvMainEmbedColor, color, sizeof color);
	embed.SetColor(StringToInt(color, 16));

	embed.SetTitle(szTitle);
	EmbedField field = new EmbedField("Challenge Map", szMapName, true);
	embed.AddField(field);
	field = new EmbedField("Style", szChallenge_Style, true);
	embed.AddField(field);
	field = new EmbedField("Winner Points", szChallenge_Points, true);
	embed.AddField(field);
	field = new EmbedField("Started", szInitial_Timestamp, true);
	embed.AddField(field);
	field = new EmbedField("Ends", szFinal_Timestamp, true);
	embed.AddField(field);

	char szUrlMain[1024];
	GetConVarString(g_cvMainUrlRoot, szUrlMain, 1024);
	StrCat(szUrlMain, sizeof szUrlMain, szMapName);
	StrCat(szUrlMain, sizeof szUrlMain, ".jpg");
	EmbedImage image = new EmbedImage(szUrlMain);
	embed.SetImage(image);

	// Add Footer
	EmbedFooter footer = new EmbedFooter();
	char buffer[1000];
	Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
	footer.SetText(buffer);

	char szFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
	if (!StrEqual(szFooterUrl, ""))
	{
		footer.SetIconURL(szFooterUrl);
		embed.SetFooter(footer);
	}

	hook.AddEmbed(embed);
	hook.Execute(webhook, OnWebHookExecuted, client);
	if (g_bDebugging)
	{
		char szDebugOutput[10000];
		hook.ToString(szDebugOutput, sizeof szDebugOutput);
		PrintToServer(szDebugOutput);
	}
	delete hook;
}

public void mapchallenge_OnChallengeEnd(int client, char szMapName[32], int style, int points, char szInitial_Timestamp[32], char szFinal_Timestamp[32], ArrayList szChallengeTop5, int totalParticipants){
	char webhook[1024], webhookName[1024];
	
	GetConVarString(g_cvAnnounceChallengeEndWebhook, webhook, 1024);
	GetConVarString(g_cvBotUsername, webhookName, 1024);
	if (StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	// Send Discord Announcement
	char szMention[128];
	GetConVarString(g_cvAnnounceChallengeMention, szMention, 128);
	Webhook hook = new Webhook(szMention);

	hook.SetUsername(webhookName);

	char szChallenge_Style[32], szChallenge_Points[32], szChallengeParticipants[32];

	Format(szChallenge_Style, sizeof(szChallenge_Style), "%s", "");
	switch (style)
	{
		case 0: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Normal");
		case 1: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Sideways");
		case 2: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Half Sideways");
		case 3: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Backwards");
		case 4: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Low Gravity");
		case 5: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Slow Motion");
		case 6: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Fast Forward");
		case 7: strcopy(szChallenge_Style, sizeof szChallenge_Style, "Free Style");
	}
	Format(szChallenge_Style, sizeof(szChallenge_Style), "%s\n", szChallenge_Style);

	Format(szChallenge_Points, sizeof(szChallenge_Points), "%d", points);

	// Format title
	char szTitle[256];
	Format(szTitle, sizeof szTitle, "__**Challenge Ended**__");

	Embed embed = new Embed();

	char color[16];
	GetConVarString(g_cvMainEmbedColor, color, sizeof color);
	embed.SetColor(StringToInt(color, 16));
	embed.SetTitle(szTitle);

	EmbedField field = new EmbedField("Challenge Map", szMapName, true);
	embed.AddField(field);

	field = new EmbedField("Style", szChallenge_Style, true);
	embed.AddField(field);

	field = new EmbedField("‎", "‎", true);
	embed.AddField(field);

	char szInitital_Timestamp_withTimezone[64];
	Format(szInitital_Timestamp_withTimezone, sizeof szInitital_Timestamp_withTimezone, "(UTC) %s", szInitial_Timestamp);
	field = new EmbedField("Started", szInitital_Timestamp_withTimezone, true);
	embed.AddField(field);

	char szFinal_Timestamp_withTimezone[64];
	Format(szFinal_Timestamp_withTimezone, sizeof szFinal_Timestamp_withTimezone, "(UTC) %s", szFinal_Timestamp);
	field = new EmbedField("Ends", szFinal_Timestamp_withTimezone, true);
	embed.AddField(field);

	field = new EmbedField("‎", "‎", true);
	embed.AddField(field);

	Format(szChallengeParticipants, sizeof(szChallengeParticipants), "%d", totalParticipants);
	field = new EmbedField("Participants", szChallengeParticipants, true);
	embed.AddField(field);

	Format(szChallenge_Points, sizeof(szChallenge_Points), "%d", points);
	field = new EmbedField("Winner Points", szChallenge_Points, true);
	embed.AddField(field);

	char szTop5_finalstring[256];
	TOP5_entry temp;
	for(int i = 0; i < 5; i++)
	{
		szChallengeTop5.GetArray(i, temp, sizeof temp);
		if(strcmp(temp.szPlayerName, "", false) != 0){
			if(i == 0)
				Format(szTop5_finalstring, sizeof szTop5_finalstring, "%i. %s | (+%s) | %s", (i+1), temp.szRuntimeFormatted, temp.szRuntimeDifference, temp.szPlayerName);
			else
				Format(szTop5_finalstring, sizeof szTop5_finalstring, "%s\n%i. %s | (+%s) | %s", szTop5_finalstring, (i+1), temp.szRuntimeFormatted, temp.szRuntimeDifference, temp.szPlayerName);
		}
		else{
			if(i == 0)
				Format(szTop5_finalstring, sizeof szTop5_finalstring, "%i. N/A", (i+1));
			else
				Format(szTop5_finalstring, sizeof szTop5_finalstring, "%s\n%i. N/A", szTop5_finalstring, (i+1));
		}
	}
	Format(szTop5_finalstring, sizeof szTop5_finalstring, "```fix\n%s\n```", szTop5_finalstring);

	delete szChallengeTop5;

	field = new EmbedField("TOP 5", szTop5_finalstring, false);
	embed.AddField(field);

	char szUrlMain[1024];
	GetConVarString(g_cvMainUrlRoot, szUrlMain, 1024);
	StrCat(szUrlMain, sizeof szUrlMain, szMapName);
	StrCat(szUrlMain, sizeof szUrlMain, ".jpg");
	EmbedImage image = new EmbedImage(szUrlMain);
	embed.SetImage(image);

	// Add Footer
	EmbedFooter footer = new EmbedFooter();
	char buffer[1000];
	Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
	footer.SetText(buffer);

	char szFooterUrl[1024];
	GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
	if (!StrEqual(szFooterUrl, ""))
	{
		footer.SetIconURL(szFooterUrl);
		embed.SetFooter(footer);
	}

	hook.AddEmbed(embed);
	hook.Execute(webhook, OnWebHookExecuted , client);
	if (g_bDebugging)
	{
		char szDebugOutput[10000];
		hook.ToString(szDebugOutput, sizeof szDebugOutput);
		PrintToServer(szDebugOutput);
	}
	delete hook;
}

stock void sendDiscordAnnouncement(int client, int style, char[] szTime, char[] szTimeDif, int bonusGroup, int stage)
{
	// Get the WebHook
	char webhook[1024], webhookName[1024];
	if (bonusGroup == -1 && stage < 1)
	{
		GetConVarString(style == 0 ? g_cvAnnounceMainWebhook : g_cvAnnounceStyleMainWebhook, webhook, 1024);
	}
	else
	{
		if (stage > 0)
		{
			GetConVarString(style == 0 ? g_cvAnnounceStageWebhook : g_cvAnnounceStyleStageWebhook, webhook, 1024);
		}
		else
		{
			GetConVarString(style == 0 ? g_cvAnnounceBonusWebhook : g_cvAnnounceStyleBonusWebhook, webhook, 1024);
		}
	}
	GetConVarString(g_cvBotUsername, webhookName, 1024);
	if (StrEqual(webhook, ""))
	{
		PrintToServer("[SurfTimer-Discord] No webhook specified, aborting.");
		return;
	}

	char szPlayerID[256], szSteamId[64], szName[MAX_NAME_LENGTH];
	GetClientName(client, szName, sizeof szName);

	if (g_cvProfileUrlType.BoolValue)
	{
		GetClientAuthId(client, AuthId_Steam2, szSteamId, sizeof szSteamId);
	}
	else
	{
		GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof szSteamId);
	}

	Format(szPlayerID, sizeof szPlayerID, "[%s](%s/%s)", szName, g_szProfileUrl, szSteamId);

	// Test which style to use
	if (!g_cvKSFStyle.BoolValue)
	{
		char szMention[128];
		GetConVarString(g_cvAnnounceMention, szMention, 128);
		Webhook hook = new Webhook(szMention);

		hook.SetUsername(webhookName);

		char szPlayerStyle[128];
		switch (style)
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
		if (bonusGroup == -1 && stage < 1)
		{
			Format(szTitle, sizeof(szTitle), "__**New World Record**__ | **%s** - **%s**", g_szCurrentMap, szPlayerStyle);
		}
		else
		{
			if (stage > 0)
			{
				Format(szTitle, sizeof(szTitle), "__**New Stage #%i World Record**__ | **%s** - **%s**", stage, g_szCurrentMap, szPlayerStyle);
			}
			else
			{
				Format(szTitle, sizeof(szTitle), "__**New Bonus #%i World Record**__ | **%s** - **%s**", bonusGroup, g_szCurrentMap, szPlayerStyle);
			}
		}

		// Create the embed message
		Embed embed = new Embed();

		char color[16], MapTier[16];
		IntToString(surftimer_GetMapTier(), MapTier, sizeof(MapTier));
		GetConVarString(bonusGroup == -1 ? g_cvMainEmbedColor : g_cvBonusEmbedColor, color, sizeof color);
		embed.SetColor(StringToInt(color, 16));

		char szTimeDiscord[128];
		Format(szTimeDiscord, sizeof(szTimeDiscord), "%s (%s)", szTime, szTimeDif);

		embed.SetTitle(szTitle);
		EmbedField field = new EmbedField("Player", szPlayerID, true);
		embed.AddField(field);
		field = new EmbedField("Time", szTimeDiscord, true);
		embed.AddField(field);
		field = new EmbedField("Map Tier", MapTier, true);
		embed.AddField(field);

		char szUrlMain[1024];
		GetConVarString(g_cvMainUrlRoot, szUrlMain, 1024);
		StrCat(szUrlMain, sizeof szUrlMain, g_szCurrentMap);
		if (g_cvBonusImage.BoolValue && bonusGroup != -1)
		{
			char szGroup[8];
			IntToString(bonusGroup, szGroup, sizeof szGroup);
			StrCat(szUrlMain, sizeof(szUrlMain), "_b");
			StrCat(szUrlMain, sizeof(szUrlMain), szGroup);
		}

		StrCat(szUrlMain, sizeof szUrlMain, ".jpg");
		EmbedImage image = new EmbedImage(szUrlMain);
		embed.SetImage(image);

		if (strncmp(g_szPictureURL, "", 1) != 0)
		{
			EmbedThumbnail thumb = new EmbedThumbnail(g_szPictureURL);
			embed.SetThumbnail(thumb);
		}

		// Add Footer
		EmbedFooter footer = new EmbedFooter();
		char        buffer[1000];
		Format(buffer, sizeof buffer, "Server: %s", g_szHostname);
		footer.SetText(buffer);

		char szFooterUrl[1024];
		GetConVarString(g_cvFooterUrl, szFooterUrl, sizeof szFooterUrl);
		if (!StrEqual(szFooterUrl, ""))
		{
			footer.SetIconURL(szFooterUrl);
			embed.SetFooter(footer);
		}

		hook.AddEmbed(embed);
		hook.Execute(webhook, OnWebHookExecuted, client);
		if (g_bDebugging)
		{
			char szDebugOutput[10000];
			hook.ToString(szDebugOutput, sizeof szDebugOutput);
			PrintToServer(szDebugOutput);
		}
		delete hook;
	}
	else
	{
		// Send Discord Announcement
		Webhook hook = new Webhook();

		hook.SetUsername(webhookName);

		// Format The Message
		char szMessage[256];

		if (bonusGroup == -1 && stage < 1)
		{
			Format(szMessage, sizeof(szMessage), "```md\n# New Server Record on %s #\n\n[%s] beat the server record on < %s > with a time of < %s (%s) > ]:```", g_szHostname, szName, g_szCurrentMap, szTime, szTimeDif);
		}
		else
		{
			if (stage > 0)
			{
				Format(szMessage, sizeof(szMessage), "```md\n# New Stage #%i Record on %s #\n\n[%s] beat the stage #%i record on < %s > with a time of < %s (%s) > ]:```", stage, g_szHostname, szName, stage, g_szCurrentMap, szTime, szTimeDif);
			}
			else
			{
				Format(szMessage, sizeof(szMessage), "```md\n# New Bonus #%i Record on %s #\n\n[%s] beat the bonus #%i record on < %s > with a time of < %s (%s) > ]:```", bonusGroup, g_szHostname, szName, bonusGroup, g_szCurrentMap, szTime, szTimeDif);
			}
		}
		hook.SetContent(szMessage);
		hook.Execute(webhook, OnWebHookExecuted, client);
		if (g_bDebugging)
		{
			char szDebugOutput[10000];
			hook.ToString(szDebugOutput, sizeof szDebugOutput);
			PrintToServer(szDebugOutput);
		}
		delete hook;
	}
}

stock void GetProfilePictureURL(int client, int style, char[] time, char[] timeDif, int bonusGroup, int stage)
{
	DataPack pack = new DataPack();
	pack.WriteCell(client);
	pack.WriteCell(style);
	pack.WriteString(time);
	pack.WriteString(timeDif);
	pack.WriteCell(bonusGroup);
	pack.WriteCell(stage);
	pack.Reset();

	char szRequestBuffer[1024], szSteamID[64];

	GetClientAuthId(client, AuthId_SteamID64, szSteamID, sizeof szSteamID, true);

	GetConVarString(g_cvSteamWebAPIKey, g_szApiKey, sizeof g_szApiKey);

	Format(szRequestBuffer, sizeof szRequestBuffer, "https://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s&format=json", g_szApiKey, szSteamID);
	connection = new HTTPRequest(szRequestBuffer);
	connection.Get(OnResponseReceived, pack);
}

stock void OnResponseReceived(HTTPResponse response, DataPack pack)
{
	char szTime[32];
	char szTimeDif[32];
	pack.Reset();
	int client = pack.ReadCell();
	int style  = pack.ReadCell();
	ReadPackString(pack, szTime, sizeof szTime);
	ReadPackString(pack, szTimeDif, sizeof szTimeDif);
	int bonusGroup = pack.ReadCell();
	int stage      = pack.ReadCell();

	if (response.Status != HTTPStatus_OK)
		return;

	JSONObject objects   = view_as<JSONObject>(response.Data);
	JSONObject Response  = view_as<JSONObject>(objects.Get("response"));
	JSONArray  players   = view_as<JSONArray>(Response.Get("players"));
	int        playerlen = players.Length;

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
	sendDiscordAnnouncement(client, style, szTime, szTimeDif, bonusGroup, stage);
}

stock void RemoveWorkshop(char[] szMapName, int len)
{
	int  i = 0;
	char szBuffer[16], szCompare[1] = "/";

	// Return if "workshop/" is not in the mapname
	if (ReplaceString(szMapName, len, "workshop/", "", true) != 1)
		return;

	// Find the index of the last /
	do
	{
		szBuffer[i] = szMapName[i];
		i++;
	}
	while (szMapName[i] != szCompare[0]);
	szBuffer[i] = szCompare[0];
	ReplaceString(szMapName, len, szBuffer, "", true);
}

stock bool IsValidClient(int iClient, bool bNoBots = true)
{
	if (iClient <= 0 || iClient > MaxClients || !IsClientConnected(iClient) || (bNoBots && IsFakeClient(iClient)))
	{
		return false;
	}
	return IsClientInGame(iClient);
}

public void OnWebHookExecuted(HTTPResponse response, int client)
{
	if (g_bDebugging)
	{
		PrintToServer("Processed client n°%d's webhook, status %d", client, response.Status);
		if (response.Status != HTTPStatus_NoContent)
		{
			PrintToServer("An error has occured while sending the webhook.");
			return;
		}
		PrintToServer("The webhook has been sent successfuly.");
	}
}
