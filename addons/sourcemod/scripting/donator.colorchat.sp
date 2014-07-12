#include <sourcemod>
#include <colors>
#include <clientprefs>
#include <loghelper>
#include <donator>

#pragma semicolon 1

//Uncomment for yellow (majority of the time) in TF2
#define TF2

#define PLUGIN_VERSION "0.3.1"

// These define the text players see in the donator menu
#define MENUTEXT_DONATOR_CHAT_COLOR "Chat Color"


enum
{
 	cNone = 0,
	cTeamColor,
	cGreen,
	cOlive,
	#if defined TF2
	cCustom,
	#endif
	cRandom,
	cMax
};

new String:szColorCodes[][] = {
	"\x01", "\x03", "\x04", "\x05"
	#if defined TF2
	, "\x06"
	#endif
};

new const String:szColorNames[cMax][] = {
	"None",
	"Team Color",
	"Green",
	"Olive",
	#if defined TF2
	"Custom",
	#endif
	"Random"
};

new g_iColor[MAXPLAYERS + 1];
new bool:g_bIsDonator[MAXPLAYERS + 1];
new Handle:g_ColorCookie = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Donator: Colored Chat",
	author = "Nut",
	description = "Donators get colored chat!",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
	
	g_ColorCookie = RegClientCookie("donator_colorcookie", "Chat color for donators.", CookieAccess_Private);
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	Donator_RegisterMenuItem(MENUTEXT_DONATOR_CHAT_COLOR, ChatColorCallback);
}

public OnPostDonatorCheck(iClient)
{
	if (!(g_bIsDonator[iClient] = IsPlayerDonator(iClient))) return;
	g_iColor[iClient] = cNone;

	if (AreClientCookiesCached(iClient))
	{
		new String:szBuffer[2];
		GetClientCookie(iClient, g_ColorCookie, szBuffer, sizeof(szBuffer));

		if (strlen(szBuffer) > 0)
			g_iColor[iClient] = StringToInt(szBuffer);
	}
}

public OnClientDisconnect(iClient)
{
	g_iColor[iClient] = cNone;
	g_bIsDonator[iClient] = false;
}

public Action:SayCallback(iClient, const String:szCommand[], iArgc)
{
	if (!iClient) return Plugin_Continue;
	if (!g_bIsDonator[iClient]) return Plugin_Continue;
	
	decl String:szArg[255], String:szChatMsg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if(szArg[0] == '/' || szArg[0] == '!' || szArg[0] == '@')	return Plugin_Continue;

	new iColor = g_iColor[iClient];
	if (!iColor) return Plugin_Continue;
	
	if (iColor == cRandom)
		iColor = GetRandomInt(cNone+1, cRandom-1);
	
	PrintToServer("%N: %s", iClient, szArg);
	
	if (StrEqual(szCommand, "say", true))
	{
		LogPlayerEvent(iClient, "say_team", szArg);
		FormatEx(szChatMsg, 255, "\x03%N\x01 :  %c%s", iClient, szColorCodes[iColor], szArg);
		CPrintToChatAllEx(iClient, szChatMsg);
	}
	else
	{
		LogPlayerEvent(iClient, "say", szArg);
		FormatEx(szChatMsg, 255, "(TEAM) \x03%N\x01 :  %c%s", iClient, szColorCodes[iColor], szArg);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(GetClientTeam(iClient) == GetClientTeam(i))
			CPrintToChatEx(i, iClient, szChatMsg);
		}
	}
	return Plugin_Handled;
}

public DonatorMenu:ChatColorCallback(iClient) Panel_SetColor(iClient);

public Action:Panel_SetColor(iClient)
{
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "Donator: Set Chat Color:");
	
	for(new i = 0; i < cMax; i++)
		if (g_iColor[iClient] == i)
			DrawPanelItem(hPanel, szColorNames[i], ITEMDRAW_DISABLED);
		else
			DrawPanelItem(hPanel, szColorNames[i], ITEMDRAW_DEFAULT);

	SendPanelToClient(hPanel, iClient, PanelHandler, 20);
	CloseHandle(hPanel);
}

public PanelHandler(Handle:menu, MenuAction:action, iClient, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new iColor = param2 - 1;
			g_iColor[iClient] = iColor;
			
			decl String:szColor[5];
			FormatEx(szColor, sizeof(szColor), "%i", iColor);
			SetClientCookie(iClient, g_ColorCookie, szColor);
			if (iColor == cRandom)
				CPrintToChat(iClient, "[SM]: Your new chat color is {olive}random{default}.");
			else
				CPrintToChatEx(iClient, iClient, "[SM]: %cThis is your new chat color.", szColorCodes[iColor]);
		}
	}
}
