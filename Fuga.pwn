/*

	SISTEMA CRIADO POR WILLIAM BORGES PADILHA (NICK:Will_33)

*/


#include <a_samp>
#include <tick-difference> //Necessária esta include, link: https://github.com/ScavengeSurvive/tick-difference

#define FLOAT_NAN					(Float:0x7FFFFFFF)
#define pb_percent(%1,%2,%3,%4)	((%1 - 6.0) + ((((%1 + 6.0 + %2 - 2.0) - %1) / %3) * %4))

new EmFuga[MAX_PLAYERS];
new AdversarioId[MAX_PLAYERS];
new OldState[MAX_PLAYERS];
new Time[MAX_PLAYERS];

// OldState 0 = atrás
// OldState 1 = na frente

#define ForEach(%0,%1) \
for(new %0 = 0; %0 != %1; %0++) if(IsPlayerConnected(%0) && !IsPlayerNPC(%0))
#define COLOUR_ERRO 0xFF0000FF

new Timer,TimerVazio;

public OnFilterScriptInit()
{
	print("\n--------------------------------------\n");
	print(" Sistema de fuga carregado\n");
	print("--------------------------------------\n");
	TimerVazio = SetTimer("Nothing",30000,1); // Esse timer é necessário pois o primeiro timer sempre buga.
	Timer = SetTimer("UpdateFuga", 500, 1);
	return 1;
}

public OnFilterScriptExit()
{
	KillTimer(Timer);
	KillTimer(TimerVazio);
	return 1;
}

public OnPlayerConnect(playerid)
{
	EmFuga[playerid] = 0;
	AdversarioId[playerid] = -1;
	OldState[playerid] = -1;
	Time[playerid] = GetTickCount();
	//Reseta todas as variáveis
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	if(EmFuga[playerid] == 1)
	{
	   	EmFuga[playerid] = 0;
		AdversarioId[playerid] = -1;
		OldState[playerid] = -1;
	}
	//Reseta todas as variáveis
	return 1;
}


public OnPlayerDeath(playerid, killerid, reason)
{
	if(EmFuga[playerid] == 1)
	{
		EndFugaPerdedor(playerid);
	}
	return 1;
}


public OnPlayerCommandText(playerid, cmdtext[])
{
    new cmd[128];
	new idx;
    cmd = strtok(cmdtext, idx);
	if (strcmp(cmd, "/fuga", true) == 0)
	{
 		new parametro[128],parametro_int;
		parametro = strtok(cmdtext, idx);
		parametro_int = strval(parametro);
		
		if(!IsPlayerSpawned(playerid)) return 1;
		if(strlen(parametro) == 0) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Comando correto: /fuga [id]");
		if(!IsNumeric(parametro)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} ID Inválido");
		if(parametro_int == playerid) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Você não pode desafiar você mesmo");
		if(EmFuga[playerid] == 1) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Você já está em fuga!");
		if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Você não está num veículo como motorista");
        if(!IsPlayerConnected(parametro_int)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador não conectado");
        if(!IsPlayerSpawned(parametro_int)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador não está nascido");
        if(EmFuga[parametro_int] == 1) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador já está em fuga!");
        if(AdversarioId[parametro_int] != -1) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador já foi desafiado!");
        if(GetPlayerState(parametro_int) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador não está num veículo como motorista");

		new Float:playerposx, Float:playerposy, Float:playerposz;
		GetPlayerPos(playerid, playerposx, playerposy, playerposz);
		if(!IsPlayerInRangeOfPoint(parametro_int, 15.0, playerposx, playerposy, playerposz)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador está muito longe! Chegue mais perto!");

		SetarAdversario(parametro_int, playerid);

		new string[128];
        new DesafiadoNome[128];
        new PlayerName[128];
        GetPlayerName(playerid, PlayerName, MAX_PLAYER_NAME);
		GetPlayerName(parametro_int, DesafiadoNome, MAX_PLAYER_NAME);
		
        format(string,sizeof(string),"{C14124}[FUGA]{FFFFFF} Você desafiou %s(id:%i) para uma fuga! Ele tem 30 segundos para aceitar",DesafiadoNome,parametro_int);
        SendClientMessage(playerid,COLOUR_ERRO,string);
        
        format(string,sizeof(string),"{C14124}[FUGA]{FFFFFF} Você foi desafiado por %s(id:%i) para uma fuga! Para aceitar use /accfuga",PlayerName,playerid);
        SendClientMessage(parametro_int,COLOUR_ERRO,string);
        
		SetTimerEx("ZerarDesafiante", 30000, false, "i", parametro_int);
		return 1;
	}
	if (strcmp("/accfuga", cmdtext, true, 10) == 0)
	{
	    new Adversario = AdversarioId[playerid];
	    
		if(!IsPlayerSpawned(playerid)) return 1;
		if(Adversario == -1) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Você não foi desafiado por ninguém");
		if(EmFuga[playerid] == 1) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Você já está em fuga!");
		if(GetPlayerState(playerid) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Você não está num veículo como motorista");
        if(!IsPlayerConnected(Adversario)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador não conectado");
        if(!IsPlayerSpawned(Adversario)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador não está nascido");
        if(EmFuga[Adversario] == 1) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador já está em fuga!");
        if(GetPlayerState(Adversario) != PLAYER_STATE_DRIVER) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador não está num veículo como motorista");

		new Float:playerposx, Float:playerposy, Float:playerposz;
		GetPlayerPos(playerid, playerposx, playerposy, playerposz);
		if(!IsPlayerInRangeOfPoint(Adversario, 15.0, playerposx, playerposy, playerposz)) return SendClientMessage(playerid,COLOUR_ERRO,"{FF8C00}[ERRO]{FFFFFF} Jogador está muito longe! Chegue mais perto!");

		SetarAdversario(Adversario, playerid);
		EmFuga[playerid] = 1;
		EmFuga[Adversario] = 1;
		OldState[playerid] = 1;
		OldState[Adversario] = 0;
		
		SendClientMessage(playerid,COLOUR_ERRO,"");
		SendClientMessage(playerid,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF}	Fuga Iniciada !!!");
		SendClientMessage(playerid,COLOUR_ERRO,"");
		SendClientMessage(playerid,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF} Você está na frente! Fuja para longe!");
		
		SendClientMessage(Adversario,COLOUR_ERRO,"");
		SendClientMessage(Adversario,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF}	Fuga Iniciada !!!");
		SendClientMessage(Adversario,COLOUR_ERRO,"");
        SendClientMessage(Adversario,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF} Você está atrás! Ultrapasse ou mate-o!");
		return 1;
	}
	if (strcmp(cmd, "/sobrefuga", true) == 0)
	{
		new Creditos2[1500];
        strins(Creditos2,"{FFFFFF}Este servidor possui um sistema de fuga/racha.\n\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}Para utilizá-lo basta digitar {00CED1}/fuga [id do desafiado]\n\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}Para desafiar, você deve estar num veículo como motorista\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}E deve estar próximo do adversário, que também deve estar dirigindo\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}A fuga pode ser feita com qualquer veículo e com ou sem caronas.\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}Os caronas podem reparar o carro e atirar nos adversários\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}Ganha quem se afastar mais na frente ou quem conseguir matar o outro\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}Sair do servidor ou do carro também conta como derrota.\n",strlen(Creditos2));
        strins(Creditos2,"{FFFFFF}O desafiado sempre começa fugindo\n",strlen(Creditos2));
        ShowPlayerDialog(playerid,202, DIALOG_STYLE_MSGBOX, "» Sistema de Fuga/Racha «",Creditos2, "Ok", "");
		return 1;
	}
	return 0;
}

forward Nothing();
public Nothing()
{
	return 1;
}

stock SetarAdversario(playerid, i)
{
	AdversarioId[playerid] = i;
	//printf("Adversário do id %i = id %i",playerid,AdversarioId[playerid]); //tire o comentário para debug
	return 1;
}

public OnPlayerStateChange(playerid, newstate, oldstate)
{
	if(EmFuga[playerid] == 1 && oldstate == PLAYER_STATE_DRIVER)
	{
		EndFugaPerdedor(playerid);
	}
	return 1;
}

forward ZerarDesafiante(playerid);
public ZerarDesafiante(playerid)
{
	if(EmFuga[playerid] == 0)
	{
     	AdversarioId[playerid] = -1;
    	SendClientMessage(playerid,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF} Tempo esgotado para aceitar a fuga");
    }
	return 1;
}

stock EndFugaPerdedor(playerid)
{
	//Reseta variaveis
	EmFuga[playerid] = 0;
	AdversarioId[playerid] = -1;
	OldState[playerid] = -1;
	
	if(!IsPlayerConnected(playerid)){return 1;}
	
	SendClientMessage(playerid,COLOUR_ERRO,"");
	SendClientMessage(playerid,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF}	Fuga Terminada. Você perdeu.");
	SendClientMessage(playerid,COLOUR_ERRO,"");
	
	return 1;
}


stock EndFugaGanhador(playerid)
{
	//Reseta variaveis
	EmFuga[playerid] = 0;
	AdversarioId[playerid] = -1;
	OldState[playerid] = -1;
	
	SendClientMessage(playerid,COLOUR_ERRO,"");
	SendClientMessage(playerid,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF}	Fuga Terminada. Você ganhou e recebeu $750!");
	SendClientMessage(playerid,COLOUR_ERRO,"");
	
	GivePlayerMoney(playerid, 750);//dar dinheiro
	return 1;
}

forward FugaStatus(playerid);
public FugaStatus(playerid)
{
	return EmFuga[playerid];
}

forward UpdateFuga();
public UpdateFuga()
{
	ForEach(i, MAX_PLAYERS)
	{
	    if(EmFuga[i] == 1)
	    {
	    	if(GetPlayerState(i) == PLAYER_STATE_DRIVER)//verifica se está num carro
	    	{
	    		new vehicleid;
        		vehicleid = GetPlayerVehicleID(i);//pega o id do carro
	    		new Float:Ax,Float:Ay,Float:Az;
	    		GetVehicleRelativePos(vehicleid, Ax, Ay, Az, 0.0, 1.5, 0.0); //pega a posição do capô do carro
	    		new Float:Bx,Float:By,Float:Bz;
	    		GetVehicleRelativePos(vehicleid, Bx, By, Bz, 0.0, -1.5, 0.0);//pega a posição do parachoque traseiro do carro

				//printf("id %i frente = x:%f y:%f z:%f",i,Ax,Ay,Az); //tire o comentário para debug
				//printf("id %i atrás = x:%f y:%f z:%f",i,Bx,By,Bz); //tire o comentário para debug

                new adversario = AdversarioId[i];
                
				if(EmFuga[adversario] == 0)
				{
				return EndFugaGanhador(i);
				}

	    		if(EmFuga[adversario] == 1)//vê se o adversario está em fuga
				{
					if(GetPlayerState(adversario) == PLAYER_STATE_DRIVER)//verifica se está num carro
	    			{
	    				new vehicleidB;
        				vehicleidB = GetPlayerVehicleID(adversario);//pega o id do carro
	    				new Float:Cx,Float:Cy,Float:Cz;
	    				GetVehicleRelativePos(vehicleidB, Cx, Cy, Cz, 0.0, 1.5, 0.0);//pega a posição do capo do carro
	    				new Float:Dx,Float:Dy,Float:Dz;
	    				GetVehicleRelativePos(vehicleidB, Dx, Dy, Dz, 0.0, -1.5, 0.0);//pega a posição do parachoque traseiro do carro
	    			
    					//printf("id %i frente = x:%f y:%f z:%f",adversario,Cx,Cy,Cz); //tire o comentário para debug
						//printf("id %i atrás = x:%f y:%f z:%f",adversario,Dx,Dy,Dz); //tire o comentário para debug
	    			
						new Float:AC,Float:AD,Float:BC,Float:BD;
						
						AC = GetPointDistanceToPoint(Ax,Ay,Az,Cx,Cy,Cz);
						AD = GetPointDistanceToPoint(Ax,Ay,Az,Dx,Dy,Dz);
						
						BC = GetPointDistanceToPoint(Bx,By,Bz,Cx,Cy,Cz);
						BD = GetPointDistanceToPoint(Bx,By,Bz,Dx,Dy,Dz);
						
	  					//printf("AC:%f, AD:%f, BC:%f, BD:%f",AC,AD,BC,BD);  //tire o comentário para debug
	  					
						
						if(!(AC > BD)) //Necessário para evitar bug quando os carros estão de costas um para o outro
						{
							if((AC > AD) && (BC > BD)) //Verifica se (i) está na frente
							{
							    if(OldState[i] == 1)
							    {
						   		 	SendClientMessage(i,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF} Você está atrás! Ultrapasse ou mate-o!");
						    		SendClientMessage(adversario,COLOUR_ERRO,"{C14124}[FUGA]{FFFFFF} Você está na frente! Fuja para longe!");
						    	}
								OldState[i] = 0;
								OldState[adversario] = 1;
							}
						}
						// OldState 0 = atrás
						// OldState 1 = na frente

						new Float:Distancia;
						Distancia = GetVehicleDistanceToVehicle(vehicleid, vehicleidB);//Distancia entre vehicleid e vehicleidB
						if(Distancia > 300)// Encerrar corrida
						{
							if(OldState[i] == 1)
							{
								EndFugaGanhador(i);
								EndFugaPerdedor(adversario);
							}
							if(OldState[i] == 0)
							{
								EndFugaGanhador(adversario);
								EndFugaPerdedor(i);
							}
							return 1;
						}

						if(GetTickCountDifference(GetTickCount(),Time[i]) > 5000) //Mostra a distância a cada 5 segundos
						{
							new string[128];
							format(string,sizeof(string),"{C14124}[FUGA]{FFFFFF} Você está a %f metros de distância do adversário. Final = 300 metros.",Distancia);
        					SendClientMessage(i,COLOUR_ERRO,string);
							printf("Distancia: %f",Distancia);
							Time[i] = GetTickCount();
						}
					}
				}
	    	}
	    }
	}
	return 1;
}

/*

DAQUI PARA BAIXO SÃO FUNÇÕES FEITAS POR TERCEIROS UTILIZADAS PARA O SCRIPT

*/

stock GetVehicleRelativePos(vehicleid, &Float:x, &Float:y, &Float:z, Float:xoff=0.0, Float:yoff=0.0, Float:zoff=0.0)
{
    new Float:rot;
    GetVehicleZAngle(vehicleid, rot);
    rot = 360 - rot;    // Making the vehicle rotation compatible with pawns sin/cos
    GetVehiclePos(vehicleid, x, y, z);
    x = floatsin(rot,degrees) * yoff + floatcos(rot,degrees) * xoff + x;
    y = floatcos(rot,degrees) * yoff - floatsin(rot,degrees) * xoff + y;
    z = zoff + z;

    /*
       where xoff/yoff/zoff are the offsets relative to the vehicle
       x/y/z then are the coordinates of the point with the given offset to the vehicle
       xoff = 1.0 would e.g. point to the right side of the vehicle, -1.0 to the left, etc.
    */
}


stock IsNumeric(string[])
{
	for (new i = 0, j = strlen(string); i < j; i++)
	{
		if (string[i] > '9' || string[i] < '0') return 0;
	}
	return 1;
}

strtok(const string[], &index)
{
	new length = strlen(string);
	while ((index < length) && (string[index] <= ' '))
	{
		index++;
	}

	new offset = index;
	new result[20];
	while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
	{
		result[index - offset] = string[index];
		index++;
	}
	result[index - offset] = EOS;
	return result;
}

IsPlayerSpawned(playerid)
{
	new statex = GetPlayerState(playerid);
	if(statex != PLAYER_STATE_NONE && statex != PLAYER_STATE_WASTED && statex != PLAYER_STATE_SPAWNED)
	{
		if(statex != PLAYER_STATE_SPECTATING)
		{
		return true;
		}
	}
	return false;
}

forward Float:GetPointDistanceToPoint(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2 = FLOAT_NAN, Float:z2 = FLOAT_NAN);
stock Float:GetPointDistanceToPoint(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2 = FLOAT_NAN, Float:z2 = FLOAT_NAN) {
	if (_:y2 == _:FLOAT_NAN) {
		return VectorSize(x1 - z1, y1 - x2, 0.0);
	}

	return VectorSize(x1 - x2, y1 - y2, z1 - z2);
}

forward Float:GetVehicleDistanceToVehicle(vehicleid, targetid);
stock Float:GetVehicleDistanceToVehicle(vehicleid, targetid) {
	new Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2;

	if (GetVehiclePos(vehicleid, x1, y1, z1) && GetVehiclePos(targetid, x2, y2, z2)) {
		return VectorSize(x1 - x2, y1 - y2, z1 - z2);
	}

	return FLOAT_NAN;
}
