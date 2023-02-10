#include <sourcemod>
#include <clientprefs>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

#define INCLUDE_VIP		// Comment this to disable VIP
#define INCLUDE_SHOP	// Comment this to disable Shop

#undef REQUIRE_PLUGIN

#tryinclude <vip_core>
#if defined _vip_core_included && defined INCLUDE_VIP
	#define VIP_INCLUDED
	static const char VIP_LIBRARY[] = "vip_core";
#else
	#warning VIP not included. (vip_core.inc)
#endif

#tryinclude <shop>
#if defined _shop_included && defined INCLUDE_SHOP
	#define SHOP_INCLUDED
	static const char SHOP_LIBRARY[] = "shop";
#else
	#warning Shop not included. (shop.inc)
#endif

#define REQUIRE_PLUGIN

#if !defined VIP_INCLUDED && !defined SHOP_INCLUDED
	#error VIP or Shop not included. (vip_core.inc) (shop.inc)
#endif

EngineVersion g_EngineVersion;

enum EPluginStatus
{
	EPluginStatus_None = 0,
	EPluginStatus_VIP_Loaded = (1 << 0), 			// When a VIP is loaded
	EPluginStatus_VIP_Config_Parsed = (1 << 1),		// When a Kill Screen added to VIP
	EPluginStatus_Shop_Loaded = (1 << 2),			// When a Shop is loaded
	EPluginStatus_Shop_Config_Parsed = (1 << 3)		// When a Kill Screen added to Shop
}

EPluginStatus g_EPluginStatus;

// Where a Kill Screen selected
enum EKillScreenSource
{
	EKillScreenSource_None = 0,
	EKillScreenSource_VIP = 1,
	EKillScreenSource_Shop = 2,
	EKillScreenSource_Normal = 3
}

enum EPlayerStatus
{
	EPlayerStatus_None = 0,
	EPlayerStatus_VIP_Authorized = (1 << 0),
	EPlayerStatus_Cookie_Authorized = (1 << 1),
	EPlayerStatus_Cookie_Parsed = (1 << 2)
}

#if defined SHOP_INCLUDED
	enum struct KillScreenShopData
	{
		char 	Description[SHOP_MAX_STRING_LENGTH];
		int 	Price;
		int 	GoldPrice;
		int 	SellPrice;
		int 	GoldSellPrice;
		int 	Duration;
		int 	LuckChance;
		bool 	Hide;
	}
#endif

#define MAX_KILLSCREEN_NAME 32

enum struct KillScreen
{
	char 	Name[MAX_KILLSCREEN_NAME];
	int 	Color[4];
	bool 	Modulate;
	float 	Duration;
	int 	FOV;
	bool 	HealthshotEffectEnabled;

	#if defined VIP_INCLUDED
		bool AddToVIP;
	#endif

	#if defined SHOP_INCLUDED
		bool AddToShop;
		KillScreenShopData ShopData;
	#endif
}

ArrayList g_hKillScreens;

enum struct KillScreenPlayer
{
	char 	Name[MAX_KILLSCREEN_NAME];
	int 	Color[4];
	bool 	Modulate;
	float 	Duration;
	int 	FOV;
	bool 	HealthshotEffectEnabled;
}

enum struct PlayerData
{
	int 	KillScreenIndex;
	EKillScreenSource KillScreenSource;
	KillScreenPlayer KillScreen;
	EPlayerStatus Status;

	void 	Init()
	{
		this.KillScreenIndex = -1;
		this.KillScreenSource = EKillScreenSource_None;

		this.Status = EPlayerStatus_None;
	}
}

PlayerData g_PlayerData[MAXPLAYERS+1];

UserMsg g_iFadeUserMsgId;
UserMessageType g_iUserMsgType;

//int m_iFOV = -1;
int m_iFOVStart = -1;
//int m_iDefaultFOV = -1;
int m_flFOVTime = -1;
int m_flFOVRate = -1;
//int m_hActiveWeapon = -1;
int m_flHealthShotBoostExpirationTime = -1;
//int m_zoomLevel = -1;

Handle g_hCookie;

#define VIP_COOKIE_CHAR 'v'
#define NORMAL_COOKIE_CHAR 'n'
static const int g_iSource[] = {'\0', VIP_COOKIE_CHAR, '\0', NORMAL_COOKIE_CHAR};

#define PLUGIN_VERSION "2.1.0"

#define DEBUG_LEVEL 0

#if DEBUG_LEVEL > 0
	char g_sLogPath[PLATFORM_MAX_PATH];
	stock void Debug(int iLine, int iLevel, const char[] sFunction, const char[] sMessage, any ...)
	{
		if(DEBUG_LEVEL >= iLevel)
		{	
			static char sBuffer[512];
			VFormat(sBuffer, sizeof(sBuffer), sMessage, 5);
			LogToFile(g_sLogPath, "[L:%d][V:%s][LVL:%d][F:%s] %s", iLine, PLUGIN_VERSION, iLevel, sFunction, sBuffer);
		}
	}

	#define Debug(%0) Debug(__LINE__, %0);

	#define PrepareDebug();		BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/killscreen_debug.log");\
								Debug(1, "OnPluginStart", "Plugin load start. Debug level %d.", DEBUG_LEVEL);
#else
	#define PrepareDebug();
	#define Debug(%0)
#endif

#include "kill_screen/functions.sp"
#include "kill_screen/config.sp"

#if defined VIP_INCLUDED
	#include "kill_screen/vip.sp"
#endif

#if defined SHOP_INCLUDED
	#include "kill_screen/shop.sp"
#endif

public Plugin myinfo =
{
	name = "Kill Screen",
	author = "Domikuss, Someone",
	description = "Color screen when killing another player",
	version = PLUGIN_VERSION,
	url = "https://github.com/domikuss/Kill-Screen"
};

public void OnPluginStart()
{
	PrepareDebug();

	LoadTranslations("killscreen.phrases");
	g_hKillScreens = new ArrayList(sizeof(KillScreen));
	HookEvent("player_death", OnPlayerDeath);
	RegAdminCmd("sm_killscreen_reload", CMD_RELOAD, ADMFLAG_ROOT, "Reload a Kill Screen config.");

	g_hCookie = RegClientCookie("KillScreen_Cookie", "KillScreen Cookie", CookieAccess_Private);

	g_EngineVersion = GetEngineVersion();

	g_iUserMsgType = GetUserMessageType();
	g_iFadeUserMsgId = GetUserMessageId("Fade");

	//m_iFOV = FindSendPropInfo("CCSPlayer", "m_iFOV");
	m_iFOVStart = FindSendPropInfo("CCSPlayer", "m_iFOVStart");
	//m_iDefaultFOV = FindSendPropInfo("CCSPlayer", "m_iDefaultFOV");
	m_flFOVTime = FindSendPropInfo("CCSPlayer", "m_flFOVTime");
	m_flFOVRate = FindSendPropInfo("CCSPlayer", "m_flFOVRate");
	//m_hActiveWeapon = FindSendPropInfo("CCSPlayer", "m_hActiveWeapon");
	m_flHealthShotBoostExpirationTime = FindSendPropInfo("CCSPlayer", "m_flHealthShotBoostExpirationTime");
	//m_zoomLevel = FindSendPropInfo("CWeaponCSBaseGun", "m_zoomLevel");

	CheckLibrary();

	Debug(1, "OnPluginStart", "Plugin loaded.")
}

Action CMD_RELOAD(int iClient, int iArgs)
{
	RemoveFlag(g_EPluginStatus, (EPluginStatus_VIP_Config_Parsed|EPluginStatus_Shop_Config_Parsed));
	if(!ParseConfig())
	{
		ReplyToCommand(iClient, "Failed to reload config.");
		return Plugin_Handled;
	}

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			EnableKillScreenByName(i, g_PlayerData[i].KillScreen.Name, g_PlayerData[i].KillScreenSource);
		}
	}

	ReplyToCommand(iClient, "Config successfully reloaded.");

	Debug(3, "CMD_RELOAD", "Config reloaded by '%d:%N'.", iClient, iClient)

	return Plugin_Handled;
}

public void OnPluginEnd()
{
	Debug(3, "OnPluginEnd", "Plugin ended.")

	#if defined VIP_INCLUDED
		if(GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
		{
			VIP_UnregisterFeature(g_sFeature);
		}
	#endif

	#if defined SHOP_INCLUDED
		if(GetFeatureStatus(FeatureType_Native, "Shop_UnregisterMe") == FeatureStatus_Available)
		{
			ClearShop();
		}
	#endif
}

public void OnAllPluginsLoaded()
{
	ParseConfig();

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			g_PlayerData[i].Init();

			#if defined VIP_INCLUDED
				if(VIP_IsClientVIP(i))
				{
					VIP_OnVIPClientLoaded(i);
				}
			#endif

			OnClientCookiesCached(i);
		}
	}
}

public void OnClientConnected(int iClient)
{
	Debug(2, "OnClientConnected", "Client %d connnected.", iClient)

	g_PlayerData[iClient].Init();
}

#if defined VIP_INCLUDED
	public void VIP_OnVIPClientLoaded(int iClient)
	{
		Debug(2, "VIP_OnVIPClientLoaded", "Client '%d:%N' loaded. Status: %d.", iClient, iClient, g_PlayerData[iClient].Status)

		if(VIP_GetClientFeatureBool(iClient, g_sFeature))
		{
			Debug(3, "VIP_OnVIPClientLoaded", "Client '%d:%N' feature use. Status: %d.", iClient, iClient, g_PlayerData[iClient].Status)

			AddFlag(g_PlayerData[iClient].Status, EPlayerStatus_VIP_Authorized);
			if(HasFlag(g_PlayerData[iClient].Status, EPlayerStatus_Cookie_Authorized))
			{
				Debug(3, "VIP_OnVIPClientLoaded", "Client '%d:%N' cookies already cached. Status: %d.", iClient, iClient, g_PlayerData[iClient].Status)

				OnClientCookiesCached(iClient);
			}
		}
	}
#endif

public void OnClientCookiesCached(int iClient)
{
	AddFlag(g_PlayerData[iClient].Status, EPlayerStatus_Cookie_Authorized);
	char szCookie[MAX_KILLSCREEN_NAME+4];
	GetClientCookie(iClient, g_hCookie, szCookie, sizeof(szCookie));

	Debug(2, "OnClientCookiesCached", "Client '%d:%N' loaded. Cookie: '%s'. Status: %d.", iClient, iClient, szCookie, g_PlayerData[iClient].Status)

	switch(szCookie[0])
	{
		#if defined VIP_INCLUDED
			case VIP_COOKIE_CHAR:
			{
				Debug(2, "OnClientCookiesCached", "Found VIP-cookie for '%d:%N'. Cookie: '%s'. Status: %d.", iClient, iClient, szCookie, g_PlayerData[iClient].Status)

				if(HasFlag(g_PlayerData[iClient].Status, EPlayerStatus_VIP_Authorized))
				{
					EnableKillScreenByNameWithoutCookie(iClient, szCookie[2], EKillScreenSource_VIP);
					AddFlag(g_PlayerData[iClient].Status, EPlayerStatus_Cookie_Parsed);

					Debug(3, "OnClientCookiesCached", "VIP-cookie parsed for '%d:%N'. Cookie: '%s'. Status: %d.", iClient, iClient, szCookie, g_PlayerData[iClient].Status)
				}
			}
		#endif
		
		case NORMAL_COOKIE_CHAR:
		{
			
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	g_PlayerData[iClient].Status = EPlayerStatus_None;

	Debug(3, "OnClientDisconnect", "Client disconnected '%d:%N'.", iClient, iClient)
}

void CheckLibrary()
{
	#if defined VIP_INCLUDED
		if(LibraryExists(VIP_LIBRARY))
		{
			OnLibraryAdded(VIP_LIBRARY);
		}
	#endif

	#if defined SHOP_INCLUDED
		if(LibraryExists(SHOP_LIBRARY))
		{
			OnLibraryAdded(SHOP_LIBRARY);
		}
	#endif
}

public void OnLibraryAdded(const char[] szName)
{
	#if defined VIP_INCLUDED
		if(!strcmp(szName, VIP_LIBRARY) && !(HasFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded)))
		{
			Debug(3, "OnLibraryAdded", "VIP library added.")

			//AddFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded);
			if(VIP_IsVIPLoaded())
			{
				VIP_OnVIPLoaded();
			}
		}
	#endif

	#if defined SHOP_INCLUDED
		if(!strcmp(szName, SHOP_LIBRARY) && !(HasFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded)))
		{
			Debug(3, "OnLibraryAdded", "Shop library added.")

			//AddFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded);
			if(Shop_IsStarted())
			{
				Shop_Started();
			}
		}
	#endif
}

public void OnLibraryRemoved(const char[] szName)
{
	#if defined VIP_INCLUDED
		if(!strcmp(szName, VIP_LIBRARY) && HasFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded))
		{
			Debug(3, "OnLibraryRemoved", "VIP library removed.")

			RemoveFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded);
			ClearVIP();
			DisableKillScreenBySource(EKillScreenSource_VIP);
		}
	#endif

	#if defined SHOP_INCLUDED
		if(!strcmp(szName, SHOP_LIBRARY) && HasFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded))
		{
			Debug(3, "OnLibraryRemoved", "Shop library removed.")

			RemoveFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded);
			DisableKillScreenBySource(EKillScreenSource_Shop);
		}
	#endif
}

void OnPlayerDeath(Event hEvent, const char[] name, bool dont_broadcast)
{
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	Debug(2, "OnPlayerDeath", "Player %d killed '%d:%N'.", iAttacker, GetClientOfUserId(hEvent.GetInt("userid")), GetClientOfUserId(hEvent.GetInt("userid")))

	if(iAttacker != 0 && IsClientInGame(iAttacker) && g_PlayerData[iAttacker].KillScreenIndex != -1 && !IsFakeClient(iAttacker) && IsPlayerAlive(iAttacker))
	{
		if(g_PlayerData[iAttacker].KillScreen.Color[3] > 0)
		{
			PerformFade(iAttacker, g_PlayerData[iAttacker].KillScreen.Duration, g_PlayerData[iAttacker].KillScreen.Color, g_PlayerData[iAttacker].KillScreen.Modulate);
		}

		if(g_PlayerData[iAttacker].KillScreen.FOV > 0)
		{
			PerformFOV(iAttacker, g_PlayerData[iAttacker].KillScreen.FOV, g_PlayerData[iAttacker].KillScreen.Duration);
		}
		
		if(g_EngineVersion == Engine_CSGO && g_PlayerData[iAttacker].KillScreen.HealthshotEffectEnabled)
		{
			SetEntDataFloat(iAttacker, m_flHealthShotBoostExpirationTime, GetGameTime() + g_PlayerData[iAttacker].KillScreen.Duration);
		}
	}
}

void DisableKillScreen(int iClient)
{
	g_PlayerData[iClient].KillScreenIndex = -1;
	g_PlayerData[iClient].KillScreenSource = EKillScreenSource_None;

	Debug(3, "DisableKillScreen", "KillScreen disabled for %d.", iClient)
}

void DisableKillScreenBySource(EKillScreenSource iSource)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_PlayerData[i].KillScreenSource == iSource)
		{
			DisableKillScreen(i);
		}
	}
}

void EnableKillScreen(int iClient, int iIndex, EKillScreenSource iSource)
{
	if(g_PlayerData[iClient].KillScreenSource != iSource)
	{
		#if defined SHOP_INCLUDED
			if(g_PlayerData[iClient].KillScreenSource == EKillScreenSource_Shop && HasFlag(g_EPluginStatus, EPluginStatus_Shop_Config_Parsed))
			{
				Shop_ToggleClientCategoryOff(iClient, g_iCategoryId);

				Debug(3, "EnableKillScreen", "KillScreen '%d:%s' disabled for '%d:%N'.", g_PlayerData[iClient].KillScreenIndex, g_PlayerData[iClient].KillScreen.Name, iClient, iClient)
			}
		#endif
	}

	g_hKillScreens.GetArray(iIndex, g_PlayerData[iClient].KillScreen, sizeof(KillScreenPlayer));
	g_PlayerData[iClient].KillScreenIndex = iIndex;
	g_PlayerData[iClient].KillScreenSource = iSource;

	Debug(3, "EnableKillScreen", "KillScreen '%d:%s' enabled for '%d:%N'.", iIndex, g_PlayerData[iClient].KillScreen.Name, iClient, iClient)

	if(g_iSource[iSource] != 0)
	{
		char szCookie[MAX_KILLSCREEN_NAME+4];
		FormatEx(szCookie, sizeof(szCookie), "%c:%s", g_iSource[iSource], g_PlayerData[iClient].KillScreen.Name);
		SetClientCookie(iClient, g_hCookie, szCookie);

		Debug(3, "EnableKillScreen", "Cookie saved for '%d:%N'. Cookie: '%s'", iClient, iClient, szCookie)
	}
	else
	{
		SetClientCookie(iClient, g_hCookie, "");
		Debug(3, "EnableKillScreen", "Cookie cleared for '%d:%N'.", iClient, iClient)
	}
}

bool EnableKillScreenByNameWithoutCookie(int iClient, const char[] sName, EKillScreenSource iSource)
{
	if(sName[0] == 0)
	{
		return false;
	}
	
	int iLen = g_hKillScreens.Length;
	for(int i = 0; i < iLen; i++)
	{
		g_hKillScreens.GetArray(i, g_ParseKillScreen, sizeof(g_ParseKillScreen));

		/*
		#if defined SHOP_INCLUDED
			if(iSource == EKillScreenSource_Shop && !g_ParseKillScreen.AddToShop)
			{
				continue;
			}
		#endif
		*/

		#if defined VIP_INCLUDED
			if(iSource == EKillScreenSource_VIP && !g_ParseKillScreen.AddToVIP)
			{
				continue;
			}
		#endif

		if(strcmp(sName, g_ParseKillScreen.Name) == 0)
		{
			g_hKillScreens.GetArray(i, g_PlayerData[iClient].KillScreen, sizeof(KillScreenPlayer));
			g_PlayerData[iClient].KillScreenIndex = i;
			g_PlayerData[iClient].KillScreenSource = iSource;

			Debug(3, "EnableKillScreenByNameWithoutCookie", "KillScreen '%d:%s' enabled for '%d:%N'.", i, sName, iClient, iClient)
			
			return true;
		}
	}

	Debug(3, "EnableKillScreenByNameWithoutCookie", "KillScreen %s not found for '%d:%N'.", sName, iClient, iClient)

	return false;
}

void EnableKillScreenByName(int iClient, const char[] sName, EKillScreenSource iSource)
{
	if(EnableKillScreenByNameWithoutCookie(iClient, sName, iSource))
	{
		if(g_iSource[iSource] != 0)
		{
			char szCookie[MAX_KILLSCREEN_NAME+4];
			FormatEx(szCookie, sizeof(szCookie), "%c:%s", g_iSource[iSource], g_PlayerData[iClient].KillScreen.Name);
			SetClientCookie(iClient, g_hCookie, szCookie);

			Debug(3, "EnableKillScreenByName", "Cookie saved for '%d:%N'. Cookie: '%s'", iClient, iClient, szCookie)
		}
		else
		{
			SetClientCookie(iClient, g_hCookie, "");
			Debug(3, "EnableKillScreenByName", "Cookie cleared for '%d:%N'.", iClient, iClient)
		}
	}
}
