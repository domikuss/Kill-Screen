CategoryId g_iCategoryId = INVALID_CATEGORY;
static const char g_sCategory[] = "killscreen_effects";

public void Shop_Started()
{	
	if(!(HasFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded)))
	{
		AddFlag(g_EPluginStatus, EPluginStatus_Shop_Loaded);
		DistributeItems();
	}
}

void AddShopItem(int iIndex, const char[] sName, const char[] sDescription, int iPrice, int iSellPrice, int iGoldPrice, int iGoldSellPrice, int iDuration, int iLuckChance, bool bHide)
{
	if(g_iCategoryId == INVALID_CATEGORY)
	{
		g_iCategoryId = Shop_RegisterCategory(g_sCategory, "Kill Screen", "Kill Screen Effects", Shop_CategoryDisplayCallback, Shop_CategoryDescriptionCallback);

		Debug(2, "AddShopItem", "Shop category '%d:%s' created.", g_iCategoryId, g_sCategory)
	}

	if(Shop_StartItem(g_iCategoryId, sName))
	{
		Shop_SetInfo(sName, sDescription, iPrice, iSellPrice, Item_Togglable, iDuration, iGoldPrice, iGoldSellPrice);
		if((iPrice <= 0 && iGoldPrice  <= 0) || bHide)
		{
			Shop_SetHide(true);
		}
		Shop_SetLuckChance(iLuckChance);
		Shop_SetCallbacks(_, Shop_OnItemUseToggleCallback, _, Shop_ItemDisplayCallback, Shop_ItemDescriptionCallback);
		Shop_SetCustomInfo("index", iIndex);
		Shop_EndItem();

		Debug(1, "AddShopItem", "Item '%d:%s' added to Shop menu.", iIndex, sName)
	}
}

static bool Shop_CategoryDisplayCallback(int iClient, CategoryId iCategoryId, const char[] sCategory, const char[] sName, char[] szDisplay, int iMaxLength, ShopMenu hMenu)
{
	if(g_PlayerData[iClient].KillScreenIndex == -1)
	{
		FormatEx(szDisplay, iMaxLength, "%T [%T]", "Kill_Screen", iClient, "Not_Selected", iClient);
		return true;
	}

	switch(g_PlayerData[iClient].KillScreenSource)
	{
		case EKillScreenSource_VIP:
		{
			FormatEx(szDisplay, iMaxLength, "%T [%T]", "Kill_Screen", iClient, "Selected_VIP", iClient);
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

static bool Shop_CategoryDescriptionCallback(int iClient, CategoryId iCategoryId, const char[] sCategory, const char[] sDescription, char[] szDisplay, int iMaxLength, ShopMenu hMenu)
{
	FormatEx(szDisplay, iMaxLength, "%T", "Shop_Description", iClient);
	return true;
}

static bool Shop_ItemDisplayCallback(int iClient, CategoryId iCategoryId, const char[] sCategory, ItemId iItemId, const char[] sItem, ShopMenu hMenu, bool &bDisabled, const char[] sName, char[] szDisplay, int iMaxLength)
{
	if(TranslationPhraseExists(sName))
	{
		FormatEx(szDisplay, iMaxLength, "%T", sName, iClient);
		return true;
	}

	return false;
}

static bool Shop_ItemDescriptionCallback(int iClient, CategoryId iCategoryId, const char[] sCategory, ItemId iItemId, const char[] sItem, ShopMenu hMenu, const char[] sDescription, char[] szDisplay, int iMaxLength)
{
	if(TranslationPhraseExists(sDescription))
	{
		FormatEx(szDisplay, iMaxLength, "%T", sDescription, iClient);
		return true;
	}

	return false;
}

static ShopAction Shop_OnItemUseToggleCallback(int iClient, CategoryId iCategoryId, const char[] sCategory, ItemId iItemId, const char[] sItem, bool bIsOn, bool bElapsed)
{
	Shop_ToggleClientCategoryOff(iClient, iCategoryId);
	if(bElapsed || bIsOn)
	{
		DisableKillScreen(iClient);
		CPrintToChat(iClient, "%t%t", "Prefix", "Kill_Screen_Disabled");

		return Shop_UseOff;
	}

	int iIndex = Shop_GetItemCustomInfo(iItemId, "index", -1);
	if(iIndex == -1)
	{
		ThrowError("Invalid item index.");
		return Shop_UseOff;
	}

	EnableKillScreen(iClient, iIndex, EKillScreenSource_Shop);

	char sTranslations[128];
	strcopy(sTranslations, sizeof(sTranslations), g_PlayerData[iClient].KillScreen.Name);
	TranslateIfPosible(iClient, sTranslations, sizeof(sTranslations));

	CPrintToChat(iClient, "%t%t", "Prefix", "Kill_Screen_Selected", sTranslations);

	return Shop_UseOn;
}

void ClearShop()
{
	g_iCategoryId = INVALID_CATEGORY;
	Shop_UnregisterMe();
}