char g_sFeature[] = "KillScreen";
static Menu g_hVIPMenu;

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeature, BOOL, SELECTABLE, OnItemSelect, OnItemDisplay, OnItemDraw);

	if(!(HasFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded)))
	{
		AddFlag(g_EPluginStatus, EPluginStatus_VIP_Loaded);
		DistributeItems();
	}
}

static int OnItemDraw(int iClient, const char[] szFeature, int iStyle)
{
	if(g_hVIPMenu == null)
	{
		return ITEMDRAW_DISABLED;
	}

	return iStyle;
}

static bool OnItemDisplay(int iClient, const char[] szFeature, char[] szDisplay, int iMaxLength)
{
	if(g_PlayerData[iClient].KillScreenIndex == -1)
	{
		FormatEx(szDisplay, iMaxLength, "%T [%T]", "Kill_Screen", iClient, "Not_Selected", iClient);
		return true;
	}

	switch(g_PlayerData[iClient].KillScreenSource)
	{
		case EKillScreenSource_Shop:
		{
			FormatEx(szDisplay, iMaxLength, "%T [%T]", "Kill_Screen", iClient, "Selected_Shop", iClient);
			return true;
		}
		case EKillScreenSource_Normal:
		{
			FormatEx(szDisplay, iMaxLength, "%T [%T]", "Kill_Screen", iClient, "Selected_Normal", iClient);
			return true;
		}
	}
	
	if(TranslationPhraseExists(g_PlayerData[iClient].KillScreen.Name))
	{
		FormatEx(szDisplay, iMaxLength, "%T [%T]", "Kill_Screen", iClient, g_PlayerData[iClient].KillScreen.Name, iClient);
	}
	else
	{
		FormatEx(szDisplay, iMaxLength, "%T [%s]", "Kill_Screen", iClient, g_PlayerData[iClient].KillScreen.Name);
	}

	return true;
}

static bool OnItemSelect(int iClient, const char[] szFeature)
{
	if(g_hVIPMenu == null)
	{
		return true;
	}

	g_hVIPMenu.Display(iClient, MENU_TIME_FOREVER);
	return false;
}

void AddVIPMenuItem(int iIndex, const char[] sName)
{
	if(g_hVIPMenu == null)
	{
		g_hVIPMenu = new Menu(MenuHandler_VIP, MenuAction_Display|MenuAction_DisplayItem|MenuAction_DrawItem|MenuAction_Select|MenuAction_Cancel);
		g_hVIPMenu.AddItem("", "Disable");
		g_hVIPMenu.ExitBackButton = true;
		Debug(1, "AddVIPMenuItem", "VIP menu initialized.")
	}

	char sNum[4];
	IntToString(iIndex, sNum, sizeof(sNum));

	g_hVIPMenu.AddItem(sNum, sName);
	Debug(1, "AddVIPMenuItem", "Item %s:%s added to VIP menu.", sNum, sName)
}

void ClearVIP()
{
	delete g_hVIPMenu;
}

public int MenuHandler_VIP(Menu hMenu, MenuAction iAction, int iClient, int iItem)
{
	switch(iAction)
	{
		case MenuAction_Display:
		{
			char sTranslations[128];
			FormatEx(sTranslations, sizeof(sTranslations), "%T", "Kill_Screen_Title", iClient);
			(view_as<Panel>(iItem)).SetTitle(sTranslations);
		}
		case MenuAction_DisplayItem:
		{
			char sTranslations[128];
			if(iItem == 0)
			{
				FormatEx(sTranslations, sizeof(sTranslations), "%T", "Disable", iClient);
				return RedrawMenuItem(sTranslations);
			}

			hMenu.GetItem(iItem, "", 0, _, sTranslations, sizeof(sTranslations));
			if(TranslationPhraseExists(sTranslations))
			{
				Format(sTranslations, sizeof(sTranslations), "%T", sTranslations, iClient);
				return RedrawMenuItem(sTranslations);
			}
		}
		case MenuAction_DrawItem:
		{
			if(iItem == 0)
			{
				if(g_PlayerData[iClient].KillScreenIndex == -1)
				{
					return ITEMDRAW_DISABLED;
				}
			}
			else
			{
				char sNum[4];
				hMenu.GetItem(iItem, sNum, sizeof(sNum));
				
				if(g_PlayerData[iClient].KillScreenIndex == StringToInt(sNum))
				{
					return ITEMDRAW_DISABLED;
				}
			}
		}
		case MenuAction_Select:
		{
			if(iItem == 0)
			{
				DisableKillScreen(iClient);

				CPrintToChat(iClient, "%t%t", "Prefix", "Kill_Screen_Disabled");
				g_hVIPMenu.Display(iClient, MENU_TIME_FOREVER);
				return 0;
			}

			char sNum[4];
			hMenu.GetItem(iItem, sNum, sizeof(sNum));
			
			int iIndex = StringToInt(sNum);
			EnableKillScreen(iClient, iIndex, EKillScreenSource_VIP);

			g_hVIPMenu.DisplayAt(iClient, GetMenuSelectionPosition(), MENU_TIME_FOREVER);

			char sTranslations[128];
			strcopy(sTranslations, sizeof(sTranslations), g_PlayerData[iClient].KillScreen.Name);
			TranslateIfPosible(iClient, sTranslations, sizeof(sTranslations));

			CPrintToChat(iClient, "%t%t", "Prefix", "Kill_Screen_Selected", sTranslations);
		}
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
				VIP_SendClientVIPMenu(iClient);
			}
		}
	}

	return 0;
}