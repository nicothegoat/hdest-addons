
class NHDACFoamModule : NHDAModule
{
	// SORRY NOTHING
}

class NHDACFoamSprayer : HDWeapon
{
	default
	{
		weapon.slotnumber 5;
		weapon.slotpriority 4;
		weapon.kickback 40;

		inventory.pickupmessage "";

		hdweapon.barrelsize 32, 3.1, 5;
		hdweapon.refid "CFS";

		scale 0.6;

		obituary "%k sprayed %o with hot, sticky goo.";
		tag "C-Foam sprayer";
	}

	states
	{
	spawn:
		LAUN A -1;
		stop;

	// copied from zscript/wep/rocketlauncher.zs:148
	select0:
		LAUG AB 0;
		MISG AB 0;
		MISG A 0 A_CheckIdSprite( "LAUGA0", "MISGA0" );
		goto select0big;

	deselect0:
		MISG # 0 A_CheckIdSprite( "LAUGA0", "MISGA0" );
		---- A 0;
		goto deselect0small;

	ready:
		MISG A 0 A_CheckIdSprite( "LAUGA0", "MISGA0" );
		#### A 1 A_WeaponReady( WRF_ALL );
		goto readyend;

	fire:
		#### A 1;
	hold:
		#### A 1;
	}

	enum Status
	{
		CFSS_STATUS = 0,
		CFSS_MAG = 1,
	}
}
