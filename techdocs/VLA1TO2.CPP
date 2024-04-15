
/* PROGRAMME: VLA1TO2.CPP
   BUT:       Programme de convertion de tableaux
			  de VLAMITS en format VLAMITSII.
   AUTEUR:    Francois Blanchette
			  */

#include <stdio.h>
#include <process.h>

#define ima_blank 0
#define ima_diamond 2
#define ima_orb 4
#define ima_oxygen 5
#define ima_chest 6
#define ima_neckless 7
#define ima_flower 8
#define ima_algue 9
#define ima_ladder 0xd
#define ima_rope 0xe
#define ima_bridge 0xf
#define ima_brick 0x10
#define ima_walla 0x11
#define ima_wallb 0x12
#define ima_wallc 0x13
#define ima_walld 0x14
#define ima_walle 0x15
#define ima_wallf 0x16
#define ima_wallg 0x17
#define ima_wallh 0x18
#define ima_waterup 0x19
#define ima_waterdn 0x1b
#define ima_lavaup 0x1c
#define ima_lavadn 0x1e
#define ima_flyplatform 0x22
#define ima_lfish 0x24
#define ima_vampireplant 0x26
#define ima_tomb 0x2b
#define ima_gkey 0x2c
#define ima_gdoor 0x2d
#define ima_hkey 0x2e
#define ima_hdoor 0x2f
#define ima_ykey 0x30
#define ima_ydoor 0x31
#define ima_wkey 0x32
#define ima_wdoor 0x33
#define ima_vcreature 0x34
#define ima_rock 0x3a
#define ima_rock2 0x3b
#define ima_rock3 0x3c
#define ima_stop 0x3d
#define ima_player 0x4d

#define class_blank 0
#define class_player 1
#define class_oxygen 3
#define class_transporter 4
#define class_destination 4
#define class_diamond 0x10
#define class_chest 0x10
#define class_flower 0x11
#define class_fruit 0x12
#define class_fishs 0xc0
#define class_vcrea 0xc1
#define class_vplant 0xc2
#define class_flyplat 0xc3
#define class_ladder 0xd0
#define class_tree 0xd1
#define class_sand 0xdd
#define class_waterup 0xde
#define class_waterdn 0xdf
#define class_obst 0xe0
#define class_stop 0xf0
#define class_lava 0xff

#define task_ignore 0
#define task_remove 1
#define task_source 2
#define task_dest 3
#define task_change 4

#define ScrAtt 0
#define ScrClass 1
#define ScrU1 2
#define ScrU2 3
#define ScrIma 4
#define ScrX 6
#define ScrY 7

#define enhaut 0
#define enbas 1
#define agauche 2
#define adroite 3

FILE *VlaFile;
FILE *ScrFile;

char VlaLevel[64][128];
char ScrTable[2560][8];
int x,y;
int ScriptEntry = 0;
int AllEntries =0;
void additem(char ObjClass, char U1, char U2, int ImaNo)
{
	AllEntries++;
	if (ScriptEntry<2048)
	{
		 ScrTable[ScriptEntry][ScrAtt]=0;
		 ScrTable[ScriptEntry][ScrClass]=ObjClass;
		 ScrTable[ScriptEntry][ScrU1]=U1;
		 ScrTable[ScriptEntry][ScrU2]=U2;
		 ScrTable[ScriptEntry][ScrIma]=ImaNo;
		 ScrTable[ScriptEntry][ScrX]=x*2;
		 ScrTable[ScriptEntry][ScrY]=y*2;
		 ScriptEntry++;
	}

	if (AllEntries==2048)
	{
		puts("WARNING: Maximum 2048 script entries reached.");

	}
}

void addcustom(char DA, char ObjClass, char U1, char U2, int ImaNo)
{
	 ScrTable[ScriptEntry][ScrAtt]=DA;
	 ScrTable[ScriptEntry][ScrClass]=ObjClass;
	 ScrTable[ScriptEntry][ScrU1]=U1;
	 ScrTable[ScriptEntry][ScrU2]=U2;
	 ScrTable[ScriptEntry][ScrIma]=ImaNo;
	 ScrTable[ScriptEntry][ScrX]=x*2;
	 ScrTable[ScriptEntry][ScrY]=y*2;
	ScriptEntry++;
	if (ScriptEntry==2048)
	{
		puts("FATAL: Maximum 2048 script entries reached.");
		exit(3);

	}
}

void Script()
{
	char item;
	item = VlaLevel[y][x];

	switch (item)
	{
		case 1: additem(class_obst, 0,0, ima_brick);
				break;
		case 2: additem(class_player, 0,0, ima_player);
				break;
		case 4: additem(class_stop, 0,0, ima_stop);
				break;

		case 5:
		case 6: additem(class_ladder, 0,0, ima_ladder);
				break;

		case 7: additem(class_ladder, 0,0, ima_rope);
				break;

		case 0xa: additem(class_chest, 0,0, ima_chest);
				  break;

		case 0xb: additem(class_oxygen, 0,0, ima_oxygen);
				  break;

		case 0xc: additem(class_flower, 0,0, ima_flower);
				  break;

		case 0xd: additem(class_diamond, 0,0, ima_diamond);
				  break;

		case 0x14:
		case 0x15: additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x16: additem(class_ladder, 0,0, ima_ladder);
				   additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x17: additem(class_ladder, 0,0, ima_rope);
				   additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x19: additem(class_chest, 0,0, ima_chest);
				   additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x1a: additem(class_oxygen, 0,0, ima_oxygen);
				   additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x1b: additem(class_flower, 0,0, ima_flower);
				   additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x1c: additem(class_diamond, 0,0, ima_diamond);
				   additem(class_waterdn, 0,0, ima_waterdn);
				   break;

		case 0x1d: additem(class_waterdn, 0,0, ima_waterdn);
				   additem(class_blank, 0,0, ima_algue);
				   break;

		case 0x24:
				   additem(class_waterup, 0,0, ima_waterup);
				   break;

		case 0x25:
				   additem(class_waterup, 0,0, ima_waterup);
				   additem(class_ladder, 0,0, ima_ladder);
				   break;

		case 0x26:
				   additem(class_waterup, 0,0, ima_waterup);
				   additem(class_ladder, 0,0, ima_rope);
				   break;

		case 0x28:
		case 0x29:
		case 0x2a:
		case 0x2b:
		case 0x2c:
				   additem(class_obst, 0,0, ima_wallf);
				   break;

		case 0x2d:
				   additem(class_waterdn,0,0,ima_waterdn);
				   additem(class_blank, 0,0, ima_algue);
				   additem(class_blank, 0,0, ima_rock);
				   break;

		case 0x2e:
				   additem(class_waterdn,0,0,ima_waterdn);
				   additem(class_blank, 0,0, ima_rock);
				break;

		case 0x2f:
				   additem(class_waterdn,0,0,ima_waterdn);
				   additem(class_blank, 0,0, ima_rock2);
				break;

		case 0x30:
				   additem(class_waterdn,0,0,ima_waterdn);
				   additem(class_blank, 0,0, ima_rock3);
				break;

		case 0x31:
				   additem(class_waterdn,0,0,ima_waterdn);
				   additem(class_blank, 0,0, ima_rock3);
				break;

		case 0x32:
					additem(class_ladder, 0,0, ima_bridge);
					additem(class_ladder, 0,0, ima_rope);
					break;

		case 0x33:
		case  0x34:
		case	 0x35:
		case	 0x36:
		case	 0x37:
		case	 0x38:
		case	 0x39:
		case	 0x3a:
		case	 0x3b:
		case	 0x3c:
		case	 0x3d:
		case	 0x3e:
		case	 0x3f:
				   additem(class_ladder,0,0,ima_bridge);
				break;

		case
			0x40:
				  additem(class_ladder, 0,0, ima_rope);
			break;

		case
			0x41:
				  additem(class_lava, 0,0, ima_lavaup);
			break;

		case
			0x42:
				  additem(class_lava, 0,0, ima_lavadn);
			break;

		case	0x43:
		case	0x45:
		case	0x47:
		case	0x49:
		case	0x4b:
		case	0x4d:
		case	0x4f:
		case	0x51:
		case	0x53:
		case	0x55:
		case	0x57:
		case	0x59:
			addcustom(task_remove,class_flower, item , 0, ima_flower);
			if (item >= 0x49)
				additem(class_waterdn, 0,0, ima_waterdn);
		break;

		case	0x5b:
		case	0x5d:
		case	0x5f:
		case	0x61:
		case	0x63:
		case	0x65:
		case	0x67:
		case	0x69:
				addcustom(task_change,class_flower,item,ima_wallf,ima_flower);
		break;

			case	0x44:
			case	0x46:
			case	0x48:
			case	0x4a:
			case	0x4c:
			case	0x4e:
			case	0x50:
			case	0x52:
			case	0x54:
			case	0x56:
			case	0x58:
			case	0x5a:
				addcustom(task_ignore,class_obst, item-1,0, ima_wallf);
				if (item>=0x54)
					additem(class_waterdn, 0,0, ima_waterdn);
			break;

			case 	0x5c:
			case    0x5e:
			case 	0x60:
			case 	0x62:
			case 	0x64:
			case 	0x66:
			case	0x68:
			case	0x6a:

				if (item>=(0x64))
				{
				addcustom(task_ignore,class_waterdn, item-1,0, ima_waterdn);
				}

				else
					addcustom(task_ignore,class_blank, item-1,0, ima_blank);

			break;

			case 	0x6b:
			case 	0x6d:
			case 	0x6f:
			case 	0x71:
			case 	0x73:
			case 	0x75:
					if (item>=0x71)
						additem(class_waterdn, 0,0, ima_waterdn);
					addcustom(task_source, class_transporter, item, 0, ima_orb);
			break;

			case 	0x6c:
			case 	0x6e:
			case 	0x70:
			case 	0x72:
			case 	0x74:
			case 	0x76:
					addcustom(task_dest, class_destination, item-1, 0, ima_blank);
			break;


			case	0x77:
				additem(class_flyplat, enhaut, 0, ima_flyplatform);
			break;

			case 0x7d:
				additem(class_vcrea, 0, 0, ima_vcreature);
			break;

			case 0x7e:
				additem(class_ladder, 0,0, ima_bridge);
				additem(class_vcrea, 0, 0, ima_vcreature);
			break;

			case 0x7f:
				additem(class_ladder, 0,0, ima_ladder);
				additem(class_vcrea, 0, 0, ima_vcreature);
			break;

			case	0x8f:
				additem(class_flyplat, agauche, 0, ima_flyplatform);
			break;

			case 0x90:
				additem(class_waterdn, 0,0, ima_waterdn);
				additem(class_fishs, 0,0, ima_lfish);
			break;

			case 0x92:
				additem(class_waterup,0,0,ima_waterup);
			break;
	}

}

void ConvertLevel()
{
	for (y=4; y<64-4-1; y++)
		for (x=8+1; x<128-8; x++)
			Script();
}

void main()
{
	 char NomFicSource[64];
	 char NomFicDest[64];
	 fflush(stdin);
	 printf("Entrez le nom du fichier source:");
	 scanf("%s",&NomFicSource);

	 VlaFile = fopen(NomFicSource, "rb");
	 if (VlaFile)
	 {

		 fread(&VlaLevel,8192,1,VlaFile);
		 fclose (VlaFile);
		 ConvertLevel();

		 printf("Nombre total d'entrees: %x (%d en dec.):\n", AllEntries,AllEntries);
		 fflush(stdin);
		 printf("Entrez le nom du fichier destination:");
		 scanf("%s",&NomFicDest);
		 ScrFile = fopen(NomFicDest,"wb");

		 if (ScrFile)
		 {
			 fprintf(ScrFile,"%c%c",(ScriptEntry*8)%256, (ScriptEntry*8)/256);
			 fprintf(ScrFile,"oldvla.sto%c     ",0);
			 fwrite(&ScrTable, 8, ScriptEntry, ScrFile);
			 fprintf(ScrFile,"THE VLAMITS (c) 1993 Francois Blanchette.");
			 fclose(ScrFile);
		 }

		 else
		 {
			printf("Le fichier %c%s%c ne peut pas etre cree.\n", 34,NomFicDest,34);
			exit(-1);
		 }



	 }
	 else
	 {
		 printf("Le fichier %c%s%c n'exite pas.\n", 34,NomFicSource,34);
		 exit(-1);
	 }
}