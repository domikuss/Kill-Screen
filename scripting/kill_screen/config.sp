SMCParser g_hConfigParser;

enum EConfigState_t
{
	State_None,
	State_Killscreens,
	State_Killscreen
}

EConfigState_t g_EConfigState;
KillScreen g_ParseKillScreen;
int g_iCurrentLine;
int g_iIgnoreLevel;

#if defined VIP_INCLUDED
	bool g_bAddToVIPByDefault;
#endif

#if defined SHOP_INCLUDED
	bool g_bAddToShopByDefault;
#endif

#define CONFIG_DEFAULT_ADDTOVIP		true
#define CONFIG_DEFAULT_ADDTOSHOP	true

#define CONFIG_DEFAULT_COLOR_R		0
#define CONFIG_DEFAULT_COLOR_G		0
#define CONFIG_DEFAULT_COLOR_B		0
#define CONFIG_DEFAULT_COLOR_A		0
#define CONFIG_DEFAULT_MODULATE		false
#define CONFIG_DEFAULT_DURATION		1.0
#define CONFIG_DEFAULT_FOV	-		1
#define CONFIG_DEFAULT_HEALTHSHOT_EFFECT_ENABLED	false

#define CONFIG_DEFAULT_SHOP_DESCRIPTION		""
#define CONFIG_DEFAULT_SHOP_PRICE			0
#define CONFIG_DEFAULT_SHOP_SELLPRICE		0
#define CONFIG_DEFAULT_SHOP_DURATION		86400
#define CONFIG_DEFAULT_SHOP_LUCKCHANCE	-	0
#define CONFIG_DEFAULT_SHOP_HIDE			false

bool ParseConfig()
{
	g_hKillScreens.Clear();

	#if defined VIP_INCLUDED
		ClearVIP();
		g_bAddToVIPByDefault = CONFIG_DEFAULT_ADDTOVIP;
	#endif

	#if defined SHOP_INCLUDED
		if(GetFeatureStatus(FeatureType_Native, "Shop_UnregisterMe") == FeatureStatus_Available)
		{
			ClearShop();
		}
		g_bAddToShopByDefault = CONFIG_DEFAULT_ADDTOSHOP;
	#endif
	
	if(!g_hConfigParser)
	{
		g_hConfigParser = new SMCParser();
		g_hConfigParser.OnEnterSection = Config_NewSection;
		g_hConfigParser.OnKeyValue = Config_KeyValue;
		g_hConfigParser.OnLeaveSection = Config_EndSection;
		g_hConfigParser.OnRawLine = Config_CurrentLine;
	}
	
	static char sPath[PLATFORM_MAX_PATH];
	if(!sPath[0])
	{
		BuildPath(Path_SM, sPath, sizeof(sPath), "configs/killscreen.ini");
	}

	SMCError hErr = g_hConfigParser.ParseFile(sPath);
	if (hErr != SMCError_Okay)
	{
		char sError[64];
		if (g_hConfigParser.GetErrorString(hErr, sError, sizeof(sError)))
		{
			LogError("Failed to parse: '%s'. Line: %d. Error: %s", sPath, g_iCurrentLine, sError);
		}
		else
		{
			LogError("Failed to parse: '%s'. Line: %d. Unknown error.", g_iCurrentLine, sPath);
		}
		
		return false;
	}

	Debug(1, "ParseConfig", "Config successfully parsed.")
	
	DistributeItems();

	return true;
}

void DistributeItems()
{
	int iLen = g_hKillScreens.Length;
	for(int i = 0; i < iLen; i++)
	{
		g_hKillScreens.GetArray(i, g_ParseKillScreen, sizeof(g_ParseKillScreen));
		#if defined VIP_INCLUDED
			if(HasFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded) && !(HasFlag(g_EPluginStatus, EPluginStatus_VIP_Config_Parsed)) && g_ParseKillScreen.AddToVIP)
			{
				AddVIPMenuItem(i, g_ParseKillScreen.Name);
			}
		#endif

		#if defined SHOP_INCLUDED
			if(HasFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded) && !(HasFlag(g_EPluginStatus, EPluginStatus_Shop_Config_Parsed)) && g_ParseKillScreen.AddToShop)
			{
				AddShopItem(i, g_ParseKillScreen.Name, g_ParseKillScreen.ShopData.Description, g_ParseKillScreen.ShopData.Price, g_ParseKillScreen.ShopData.SellPrice, g_ParseKillScreen.ShopData.Duration, g_ParseKillScreen.ShopData.LuckChance, g_ParseKillScreen.ShopData.Hide);
			}
		#endif
	}

	if(HasFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded))
	{
		AddFlag(g_EPluginStatus, EPluginStatus_VIP_Config_Parsed);
	}

	if(HasFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded))
	{
		AddFlag(g_EPluginStatus, EPluginStatus_Shop_Config_Parsed);
	}
}

SMCResult Config_NewSection(SMCParser hParser, const char[] sName, bool bInQuotes)
{
	if (g_iIgnoreLevel)
	{
		g_iIgnoreLevel++;
		return SMCParse_Continue;
	}
	
	switch(g_EConfigState)
	{
		case State_None:
		{
			if(strcmp(sName, "Killscreens") == 0)
			{
				g_EConfigState = State_Killscreens;
			}
			else
			{
				g_iIgnoreLevel++;
			}
		}
		case State_Killscreens:
		{
			strcopy(g_ParseKillScreen.Name, sizeof(g_ParseKillScreen.Name), sName);
			
			g_ParseKillScreen.Color[0] = CONFIG_DEFAULT_COLOR_R;
			g_ParseKillScreen.Color[1] = CONFIG_DEFAULT_COLOR_G;
			g_ParseKillScreen.Color[2] = CONFIG_DEFAULT_COLOR_B;
			g_ParseKillScreen.Color[3] = CONFIG_DEFAULT_COLOR_A;
			g_ParseKillScreen.Modulate = CONFIG_DEFAULT_MODULATE;
			g_ParseKillScreen.Duration = CONFIG_DEFAULT_DURATION;
			g_ParseKillScreen.FOV = CONFIG_DEFAULT_FOV;
			g_ParseKillScreen.HealthshotEffectEnabled = CONFIG_DEFAULT_HEALTHSHOT_EFFECT_ENABLED;

			#if defined VIP_INCLUDED
				g_ParseKillScreen.AddToVIP = g_bAddToVIPByDefault;
			#endif

			#if defined SHOP_INCLUDED
				g_ParseKillScreen.AddToShop = g_bAddToShopByDefault;

				g_ParseKillScreen.ShopData.Description = CONFIG_DEFAULT_SHOP_DESCRIPTION;
				g_ParseKillScreen.ShopData.Price = CONFIG_DEFAULT_SHOP_PRICE;
				g_ParseKillScreen.ShopData.SellPrice = CONFIG_DEFAULT_SHOP_SELLPRICE;
				g_ParseKillScreen.ShopData.Duration = CONFIG_DEFAULT_SHOP_DURATION;
				g_ParseKillScreen.ShopData.LuckChance = CONFIG_DEFAULT_SHOP_LUCKCHANCE;
				g_ParseKillScreen.ShopData.Hide = CONFIG_DEFAULT_SHOP_HIDE;
			#endif
			
			g_EConfigState = State_Killscreen;
		}
		default:
		{
			g_iIgnoreLevel++;
		}
	}

	return SMCParse_Continue;
}

SMCResult Config_KeyValue(SMCParser hParser, const char[] sKey,  const char[] sValue, bool bKeyInQuotes, bool bValueInQuotes)
{
	if (g_iIgnoreLevel)
	{
		return SMCParse_Continue;
	}
	
	switch(g_EConfigState)
	{
		case State_Killscreens:
		{
			#if defined VIP_INCLUDED
				if(strcmp(sKey, "add_to_vip_by_default") == 0)
				{
					g_bAddToVIPByDefault = view_as<bool>(StringToInt(sValue));
					return SMCParse_Continue;
				}
			#endif

			#if defined SHOP_INCLUDED
				if(strcmp(sKey, "add_to_shop_by_default") == 0)
				{
					g_bAddToShopByDefault = view_as<bool>(StringToInt(sValue));
					return SMCParse_Continue;
				}
			#endif
		}
		case State_Killscreen:
		{
			if(strcmp(sKey, "fade_rgba") == 0)
			{
				ExplodeTo(sValue, g_ParseKillScreen.Color, 4, false);
			}
			else if(strcmp(sKey, "fade_modulate") == 0)
			{
				g_ParseKillScreen.Modulate = view_as<bool>(StringToInt(sValue));
			}
			else if(strcmp(sKey, "duration") == 0)
			{
				g_ParseKillScreen.Duration = StringToFloat(sValue);
			}
			else if(strcmp(sKey, "fov") == 0)
			{
				g_ParseKillScreen.FOV = StringToInt(sValue);
			}
			else if(strcmp(sKey, "healthshot_effect") == 0)
			{
				g_ParseKillScreen.HealthshotEffectEnabled = view_as<bool>(StringToInt(sValue));
			}

			#if defined VIP_INCLUDED
				else if(strcmp(sKey, "vip") == 0)
				{
					g_ParseKillScreen.AddToVIP = view_as<bool>(StringToInt(sValue));
				}
			#endif

			#if defined SHOP_INCLUDED
				else if(strcmp(sKey, "shop") == 0)
				{
					g_ParseKillScreen.AddToShop = view_as<bool>(StringToInt(sValue));
				}
				else if(strcmp(sKey, "shop_description") == 0)
				{
					strcopy(g_ParseKillScreen.ShopData.Description, sizeof(KillScreenShopData::Description), sValue);
				}
				else if(strcmp(sKey, "shop_price") == 0)
				{
					g_ParseKillScreen.ShopData.Price = StringToInt(sValue);
				}
				else if(strcmp(sKey, "shop_sellprice") == 0)
				{
					g_ParseKillScreen.ShopData.SellPrice = StringToInt(sValue);
				}
				else if(strcmp(sKey, "shop_duration") == 0)
				{
					g_ParseKillScreen.ShopData.Duration = StringToInt(sValue);
				}
				else if(strcmp(sKey, "shop_luckchance") == 0)
				{
					g_ParseKillScreen.ShopData.LuckChance = StringToInt(sValue);
				}
				else if(strcmp(sKey, "shop_hide") == 0)
				{
					g_ParseKillScreen.ShopData.Hide = view_as<bool>(StringToInt(sValue));
				}
			#endif
		}
	}
	
	return SMCParse_Continue;
}

SMCResult Config_EndSection(SMCParser hParser)
{
	if (g_iIgnoreLevel)
	{
		g_iIgnoreLevel--;
		return SMCParse_Continue;
	}
	
	switch(g_EConfigState)
	{
		case State_Killscreen:
		{
			g_EConfigState = State_Killscreens;
			g_hKillScreens.PushArray(g_ParseKillScreen, sizeof(KillScreen));
		}
		case State_Killscreens:
		{
			g_EConfigState = State_None;
		}
	}

	return SMCParse_Continue;
}

SMCResult Config_CurrentLine(SMCParser hParser, const char[] sLine, int iLineNum)
{
	g_iCurrentLine = iLineNum;
	return SMCParse_Continue;
}