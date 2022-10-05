#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <vip_core>
#include <shop>

static const char g_sFeature[] = "KillScreen";
static const char g_sCategory[] = "effects";

enum
{
	LIB_VIP = 0,
	LIB_SHOP,
	LIB_COUNT
}

bool g_bActiveLib[LIB_COUNT];

int g_iPrice, g_iSellPrice, g_iDuration;
float g_fEffectDuration;

CategoryId g_CategoryId;
ItemId g_ItemId;

public Plugin myinfo =
{
	name = "Kill Screen",
	author = "Domikuss",
	description = "Color screen when killing another player",
	version = "1.0.0",
	url = "https://github.com/domikuss/Kill-Screen"
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);

	ConVar Convar;

	(Convar = CreateConVar("sm_killscreen_shop_price", "5000", 
		"Price for a product in Shop"
	)).AddChangeHook(ChangeCvar_Shop_Price);
	ChangeCvar_Shop_Price(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar("sm_killscreen_shop_sell_price", "2500", 
		"Price for sell a product in Shop"
	)).AddChangeHook(ChangeCvar_Shop_SellPrice);
	ChangeCvar_Shop_SellPrice(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar("sm_killscreen_shop_duration", "3600", 
		"The duration of an item when you buy it in Shop"
	)).AddChangeHook(ChangeCvar_Shop_Duration);
	ChangeCvar_Shop_Duration(Convar, NULL_STRING, NULL_STRING);

	(Convar = CreateConVar("sm_killscreen_effectduration",	"1.0", 
		"Total duration of effect.",
		_, true, 0.5, _, _
	)).AddChangeHook(ChangeCvar_EffectDuration);
	ChangeCvar_EffectDuration(Convar, NULL_STRING, NULL_STRING);

	AutoExecConfig();
	CheckLibrary();

	if(g_bActiveLib[LIB_VIP] && VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
	if(g_bActiveLib[LIB_SHOP] && Shop_IsStarted()) Shop_Started();
}

public void OnPluginEnd()
{
	if(CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") == FeatureStatus_Available)
	{
		VIP_UnregisterFeature(g_sFeature);
	}
	if(g_bActiveLib[LIB_SHOP]) 
	{
		Shop_UnregisterMe();
	}
}

void ChangeCvar_Shop_Price(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_iPrice = Convar.IntValue;
}

void ChangeCvar_Shop_SellPrice(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_iSellPrice = Convar.IntValue;
}

void ChangeCvar_Shop_Duration(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_iDuration = Convar.IntValue;
}

void ChangeCvar_EffectDuration(ConVar Convar, const char[] oldValue, const char[] newValue)
{
	g_fEffectDuration = Convar.FloatValue;
}

void SetLibState(const char[] szName, bool bValue)
{
	static char szLibs[][] = {"vip_core", "shop"};
	for (int i = 0; i < sizeof(szLibs); i++)
	{
		if (!strcmp(szName, szLibs[i]))
		{
			g_bActiveLib[i] = bValue;
		}
	}
}

public void OnAllPluginsLoaded()
{
	int iCount;
	for(int i = 0; i < LIB_COUNT; i++)
	{
		if(!g_bActiveLib[i])
		{
			iCount++;
		}
	}
	if(iCount == LIB_COUNT)
	{
		SetFailState("You do not have at least one of the cores!");
	}
}

void CheckLibrary()
{
	if(LibraryExists("vip_core")) OnLibraryAdded("vip_core");
	if(LibraryExists("shop")) OnLibraryAdded("shop");
}

public void OnLibraryAdded(const char[] szName)
{
	SetLibState(szName, true);
}

public void OnLibraryRemoved(const char[] szName)
{
	SetLibState(szName, false);
}

public void VIP_OnVIPLoaded()
{
	LoadTranslations("vip_modules.phrases");
	VIP_RegisterFeature(g_sFeature, BOOL, TOGGLABLE);
}

public void Shop_Started()
{
	g_CategoryId = Shop_RegisterCategory(g_sCategory, "Effects", "Effects for players");
	if(g_iPrice != -1 && Shop_StartItem(g_CategoryId, g_sFeature))
	{
		Shop_SetInfo("Kill Screen", "Color screen when killing another player", g_iPrice, g_iSellPrice, Item_Togglable, g_iDuration);
		Shop_SetCallbacks(OnItemRegistered, Shop_OnItemUseToggleCallback);
		Shop_EndItem();
	}
}

ShopAction Shop_OnItemUseToggleCallback(int client, CategoryId category_id, const char[] category, ItemId item_id, const char[] item, bool isOn, bool elapsed)
{
	return isOn ? Shop_UseOff : Shop_UseOn;
}

public void OnItemRegistered(CategoryId category_id, const char[] sCategory, const char[] sItem, ItemId item_id)
{
	g_ItemId = item_id;
}

Action OnPlayerDeath(Event hEvent, const char[] name, bool dont_broadcast)
{
	bool bState;
	int iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if ((g_bActiveLib[LIB_VIP] && VIP_IsClientVIP(iAttacker) && VIP_IsClientFeatureUse(iAttacker, g_sFeature) ||
	g_bActiveLib[LIB_SHOP] && Shop_IsClientHasItem(iAttacker, g_ItemId) && Shop_IsClientItemToggled(iAttacker, g_ItemId) && Shop_GetClientItemTimeleft(iAttacker, g_ItemId) >= 0))
	{
		bState = true;
	}
	if(bState)
	{
		SetEntPropFloat(iAttacker, Prop_Send, "m_flHealthShotBoostExpirationTime", GetGameTime() + g_fEffectDuration);
	}

	return Plugin_Continue;
}