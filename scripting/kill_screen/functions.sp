#define AddFlag(%0,%1) %0 |= %1
#define HasFlag(%0,%1) %0 & %1
#define ToggleFlag(%0,%1) %0 ^= %1
#define RemoveFlag(%0,%1) %0 &= ~%1

#define FFADE_IN            0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT            0x0002        // Fade out (not in)
#define FFADE_MODULATE        0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT        0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE        0x0010        // Purges all other fades, replacing them with this one

void PerformFade(int iClient, float fDuration, int iColor[4], bool bModulate)
{
	static int iTargets[2];
	iTargets[0] = iClient;
	
	int iDuration = RoundToNearest(fDuration * 1000.0);
	int iFlags = bModulate ? FFADE_IN|FFADE_PURGE|FFADE_MODULATE:FFADE_IN|FFADE_PURGE;

	Handle hMessage = StartMessageEx(g_iFadeUserMsgId, iTargets, 1);
	switch(g_iUserMsgType)
	{
		case UM_Protobuf:
		{
			Protobuf pb = UserMessageToProtobuf(hMessage);
			pb.SetInt("duration", iDuration);
			pb.SetInt("hold_time", 0);
			pb.SetInt("flags", iFlags);
			pb.SetColor("clr", iColor);
		}
		case UM_BitBuf:
		{
			BfWrite bf = UserMessageToBfWrite(hMessage);
			bf.WriteShort(iDuration);
			bf.WriteShort(0);
			bf.WriteShort(iFlags);
			bf.WriteByte(iColor[0]);
			bf.WriteByte(iColor[1]);
			bf.WriteByte(iColor[2]);
			bf.WriteByte(iColor[3]);
		}
		default:
		{
			LogError("Invalid user message type: %d", g_iUserMsgType);
		}
	}
	
	EndMessage();
}

void PerformFOV(int iClient, int iFOV, float fDuration)
{
	SetEntData(iClient, m_iFOVStart, iFOV);
	SetEntDataFloat(iClient, m_flFOVTime, GetGameTime());
	SetEntDataFloat(iClient, m_flFOVRate, fDuration);
}

/*
int g_iStartFOV[MAXPLAYERS+1];
int g_iEndFOV[MAXPLAYERS+1];
float g_fStartTime[MAXPLAYERS+1];
float g_fMidTime[MAXPLAYERS+1];
float g_fEndTime[MAXPLAYERS+1];

void PerformFOV(int iClient, int iFOV, float fDuration)
{
	int iWeapon = GetEntDataEnt2(iClient, m_hActiveWeapon);
	if(iWeapon != -1)
	{
		if(GetEntData(iWeapon, m_zoomLevel) != 0 && !IsWeaponKnife(iWeapon))
		{
			PrintToChatAll("%d", GetEntData(iWeapon, m_zoomLevel));
			PrintToChatAll("m_bIsScoped - %d", GetEntProp(iClient, Prop_Send, "m_bIsScoped"));
			return;
		}
	}

	SetEntData(iClient, m_iFOV, iFOV); 

	g_iStartFOV[iClient] = GetEntData(iClient, m_iDefaultFOV);
	g_iEndFOV[iClient] = iFOV;

	float fTime = GetGameTime();
	g_fStartTime[iClient] = fTime;
	g_fMidTime[iClient] = fTime+fDuration*0.5;
	g_fEndTime[iClient] = fTime+fDuration;
}

public void OnGameFrame()
{
	float fTime = GetGameTime();
	for(int i = 1; i <= MaxClients; i++)
	{
		if(g_fEndTime[i] != 0.0)
		{
			if(g_fEndTime[i] > fTime)
			{
				float fPercent = (fTime-g_fStartTime[i])/(g_fEndTime[i]-g_fStartTime[i])*2.0;
				int iFOV;
				// Reverse
				if(g_fMidTime[i] < fTime)
				{
					fPercent = 1.0 - fPercent;
					iFOV = g_iEndFOV[i];
				}
				else
				{
					iFOV = g_iStartFOV[i];
				}

				iFOV += RoundToNearest(float(g_iEndFOV[i]-g_iStartFOV[i])*fPercent);

				SetEntData(i, m_iFOV, iFOV); 
			}
			else
			{
				g_fEndTime[i] = 0.0;
				SetEntData(i, m_iFOV, 0); 
			}
		}
	}
}
*/

void ExplodeTo(const char[] sBuffer, any[] aValues, int iLen, bool bFloat)
{
	char[][] sExplodedPosition = new char[iLen][16];
	ExplodeString(sBuffer, " ", sExplodedPosition, iLen, 16);
	
	for(int i = 0; i < iLen; i++)
	{
		aValues[i] = bFloat ? view_as<any>(StringToFloat(sExplodedPosition[i])): view_as<any>(StringToInt(sExplodedPosition[i])); // tag mismatch fix ¯\_(ツ)_/¯
	}
}

stock bool IsWeaponKnife(int iWeapon)
{
	char sClass[8];
	GetEntityNetClass(iWeapon, sClass, sizeof(sClass));
	return strncmp(sClass, "CKnife", 6) == 0;
}

bool TranslateIfPosible(int iClient, char[] sTranslation, int iMaxLength)
{
	if(TranslationPhraseExists(sTranslation))
	{
		Format(sTranslation, iMaxLength, "%T", sTranslation, iClient);
		return true;
	}

	return false;
}