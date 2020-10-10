class NHDAPoweredReloaderTracker : Thinker
{
	array< int > allocated;
	array< int > localID;
	array< NHDAPoweredReloader > reloader;
	array< NHDAPoweredReloaderTicker > ticker;

	int firstFree;

	static NHDAPoweredReloaderTracker Instance( bool spawn = false )
	{
		let iter = ThinkerIterator.Create( "NHDAPoweredReloaderTracker", STAT_STATIC );

		let this = NHDAPoweredReloaderTracker( iter.next() );
		if( !this && spawn ) this = new( "NHDAPoweredReloaderTracker" );

		return this;
	}

	static int GetGID( void )
	{
		let this = Instance( true );

		int gid = this.firstFree;
		if( gid >= this.allocated.Size() )
		{
			gid = this.allocated.Push( 1 );
			this.localID.Push( 0 );
			this.reloader.Push( NULL );
			this.ticker.Push( NULL );
		}
		else this.allocated[ gid ] = 1;

		this.firstFree = this.allocated.Size();
		for ( int i = gid + 1; i < this.allocated.Size(); i++ )
		{
			if( !this.allocated[ i ] )
			{
				this.firstFree = i;
				break;
			}
		}

		return gid + 1;
	}

	// "bad" - obamacare tf2
	static void AttachReloader( NHDAPoweredReloader reloader )
	{
		let this = Instance( true );

		let gid = reloader.weaponstatus[ NHDAPoweredReloader.PRLS_GLOBALID ] - 1;

		for( int i = 0; i < MAXPLAYERS; i++ )
		{
			if( !playeringame[ i ] ) continue;

			let backpack = HDBackpack( players[ i ].ReadyWeapon );
			if( !backpack ) continue;

			// class names are inconsistent - sometimes all lowercase, sometimes not.
			// HD doesn't make the name lowercase - it'll match the one returned by GetClassName
			int index = backpack.invclasses.find( reloader.GetClassName() );
			if( index >= backpack.invclasses.Size() ) continue;

			array< string > weaponStatus;
			backpack.amounts[ index ].split( weaponStatus, " " );
			if( weaponStatus.Size() < 1 ) continue;

			for ( int j = 0; j < weaponStatus.Size(); j += ( HDWEP_STATUSSLOTS + 1 ) )
			{
				if( weaponStatus[j + NHDAPoweredReloader.PRLS_GLOBALID].ToInt() - 1 == gid )
				{
					let ticker = GetTicker( backpack );

					ticker.AttachReloader( reloader );

					this.localID[ gid ] = reloader.weaponstatus[ NHDAPoweredReloader.PRLS_LOCALID ];
					this.ticker[ gid ] = ticker;

					let owner = "NULL";
					let inv = "NULL";
					if( ticker.owner ) owner = ticker.owner.GetClassName();
					if( ticker.Inv ) inv = ticker.Inv.GetClassName();

					return;
				}
			}
		}
	}

	static void DetachReloader( NHDAPoweredReloader reloader )
	{
		let this = Instance();
		if( !this ) return;

		let gid = reloader.weaponstatus[ NHDAPoweredReloader.PRLS_GLOBALID ] - 1;
		if( gid < 0 ) return; // spawned in backpack

		if( !this.ticker[ gid ] ) return;

		reloader.weaponstatus[ NHDAPoweredReloader.PRLS_LOCALID ] = this.localID[ gid ];
		this.ticker[ gid ].DetachReloader( reloader );

		this.ticker[ gid ] = NULL;

		this.reloader[ gid ] = reloader;
	}

	static void Cleanup( void )
	{
		let this = Instance();
		if( !this ) return;

		bool canPop = true;

		for ( int i = this.allocated.Size() - 1; i >= 0; i-- )
		{
			if( this.allocated[ i ] && !this.ticker[ i ] && !this.reloader[ i ] )
			{
				this.allocated[ i ] = 0;
			}
			else if( this.allocated[ i ] ) canPop = false;

			if( canPop )
			{
				this.allocated.Pop();
				this.reloader.Pop();
				this.localID.Pop();
				this.ticker.Pop();
			}
		}
	}

	static NHDAPoweredReloaderTicker GetTicker( Actor owner )
	{
		// check if they already have one
		let inv = owner.Inv;
		do
		{
			if( inv is 'NHDAPoweredReloaderTicker' && inv.master == owner )
				return NHDAPoweredReloaderTicker( inv );
		}
		while ( inv = inv.Inv );

		// didn't find one - spawn one
		let this = NHDAPoweredReloaderTicker( Actor.Spawn( 'NHDAPoweredReloaderTicker' ) );
		if( this )
		{
			this.bCountItem = false;
			this.ChangeStatNum( thinker.STAT_INVENTORY );

			owner.AddInventory( this );

			let ownerItem = Inventory( owner );
			if( ownerItem && ownerItem.owner )
				this.owner = ownerItem.owner;

			this.master = owner;
		}

		return this;
	}

	override void PostBeginPlay( void ) { ChangeStatNum( STAT_STATIC ); }
}

class NHDAPoweredReloaderTicker : Inventory
{
	array< int > allocated;

	array< int > drainage;
	array< int > progress;
	array< int > livernds;

	array< int > brass;
	array< int > powders;

	array< int > battery;

	void AttachReloader( NHDAPoweredReloader reloader )
	{
		int index = -1;

		for ( int i = 0; i < allocated.Size(); i++ )
		{
			if( allocated[ i ] ) continue;

			index = i;
			break;
		}

		if( index >= 0 )
		{
			allocated[ index ] = true;

			drainage[ index ] = reloader.drainage;
			progress[ index ] = reloader.progress;
			livernds[ index ] = reloader.livernds;

			brass[ index ] = reloader.brass;
			powders[ index ] = reloader.powders;

			battery[ index ] = reloader.battery;
		}
		else
		{
			index = allocated.Push( true );

			drainage.Push( reloader.drainage );
			progress.Push( reloader.progress );
			livernds.Push( reloader.livernds );

			brass.Push( reloader.brass );
			powders.Push( reloader.powders );

			battery.Push( reloader.battery );
		}

		reloader.weaponstatus[ NHDAPoweredReloader.PRLS_LOCALID ] = index + 1;
	}

	void DetachReloader( NHDAPoweredReloader reloader )
	{
		let index = reloader.weaponstatus[ NHDAPoweredReloader.PRLS_LOCALID ] - 1;

		if( index >= 0 && allocated[ index ] )
		{
			allocated[ index ] = false;

			reloader.drainage = drainage[ index ];
			reloader.progress = progress[ index ];
			reloader.livernds = livernds[ index ];

			reloader.brass = brass[ index ];
			reloader.powders = powders[ index ];

			reloader.battery = battery[ index ];

			reloader.weaponstatus[ NHDAPoweredReloader.PRLS_LOCALID ] = 0;

			Cleanup();
		}
	}

	void CheckBFGCharge( NHDAPoweredReloader reloader )
	{
		let flags = reloader.weaponstatus[ 0 ];

		reloader.weaponstatus[ 0 ] = 0;
		bool canCharge = reloader.CheckBFGCharge( 0 );
		reloader.weaponstatus[ 0 ] = flags;

		if( !canCharge ) return;

		for ( int i = 0; i < allocated.Size(); i++ )
			if( allocated[ i ] && battery[ i ] >= 0 ) battery[ i ] = 20;
	}

	void Cleanup( void )
	{
		for ( int i = allocated.Size() - 1; i >= 0; i-- )
		{
			// delete from the end to keep the indices the same
			if( !allocated[ i ] )
			{
				allocated.Pop();

				drainage.Pop();
				progress.Pop();
				livernds.Pop();

				brass.Pop();
				powders.Pop();

				battery.Pop();
			}
			else break;
		}

		if( allocated.Size() == 0 ) Destroy();
	}

	override void Travelled( void ) { Cleanup(); }

	override void Tick( void )
	{
		if( allocated.Size() == 0 ) return;

		if( master.Inv != self )
		{
			if( owner )
			{
				let ownerInv = owner;
				do
				{
					if( ownerInv.Inv == self )
					{
						ownerInv.Inv = Inv;
						break;
					}
				}
				while ( ownerInv = ownerInv.Inv );
			}

			let masterItem = Inventory( master );

			if( masterItem && masterItem.owner )
			{
				owner = masterItem.owner;
			}
			else owner = master;

			Inv = master.Inv;
			master.Inv = self;
		}

		for ( int i = 0; i < allocated.Size(); i++ )
		{
			if( allocated[ i ] )
			{
				if( ( battery[ i ] > 0 ) && ( brass[ i ] > 0 ) && ( powders[ i ] >= 4 ) )
				{
					progress[ i ]++;

					// make a round every 8 seconds
					if( progress[ i ] == 280 )
					{
						if( owner ) owner.A_StartSound( "rndmaker2/pop", 32 + ( 2 * i ) );

						drainage[ i ] += 2;
						if( drainage[ i ] >= 20 )
						{
							battery[ i ]--;
							drainage[ i ] -= 20;
						}

						progress[ i ] = -35;

						brass[ i ]--;
						powders[ i ] -= 4;

						livernds[ i ]++;
					}
					else if( progress[ i ] > 0 && owner ) owner.A_StartSound( "rndmaker2/chug", 33 + ( i * 2 ) );
				}
				else progress[ i ] = 0;
			}
		}
	}
}

class NHDAPoweredReloader : AutoReloader
{
	default
	{
		inventory.pickupmessage "You got the electric 7.76mm reloading machine!";
		hdweapon.refid "7re";
		tag "electric 7.76mm reloading device";

		// TODO: make ticker not curse backpack
//		-hdweapon.fitsinbackpack;
	}

	enum PoweredReloaderStatus
	{
		PRLF_JUSTUNLOAD = 1,
		PRLF_NOTINSPARES = 2,
	
		PRLS_FLAGS = 0,
		PRLS_LOCALID = 1,
		PRLS_GLOBALID = 2
	}

	bool attached;

	int drainage;
	int progress;
	int livernds;

	int battery;

	NHDAPoweredReloaderTicker ticker;

	override void MarkPrecacheSounds( void )
	{
		MarkSound( "rndmaker2/chug" );
		MarkSound( "rndmaker2/pop" );
	}

	override double GunMass( void ) { return 6; }
	override double WeaponBulk( void )
	{
		return
			20 +
			( battery > 0 ? ENC_BATTERY_LOADED : 0 )
		;
	}

	override string GetHelpText( void )
	{
		return
			WEPHELP_RELOAD                          .. " Load 7.76 brass and 4.26 rounds\n" ..
			WEPHELP_UNLOAD                          .. " Unload live 7.76 rounds\n" ..
			WEPHELP_ALTRELOAD                       .. " Reload battery\n" ..
			WEPHELP_USE .. "+" .. WEPHELP_ALTRELOAD .. " Unload battery\n"
		;
	}

	override void PostBeginPlay( void )
	{
		super.PostBeginPlay();

		if( !weaponstatus[ PRLS_GLOBALID ] )
			weaponstatus[ PRLS_GLOBALID ] = NHDAPoweredReloaderTracker.GetGID();

		else if( weaponstatus[ 0 ] & PRLF_NOTINSPARES ) 
			NHDAPoweredReloaderTracker.DetachReloader( self );

		weaponstatus[ 0 ] |= PRLF_NOTINSPARES;
	}

	override void OnDestroy( void )
	{
		// didn't reach AddSpareWeapon - could be entering backpack
		if( ( weaponstatus[ 0 ] & PRLF_NOTINSPARES ) )
			NHDAPoweredReloaderTracker.AttachReloader( self );

		super.OnDestroy();
	}

	// removes the stock reloader's unload on pickup
	override void ActualPickup( Actor other, bool silent )
	{
		HDWeapon.ActualPickup( other, silent );
	}

	override bool AddSpareWeapon( Actor newOwner )
	{
		weaponstatus[ 0 ] &= ~PRLF_NOTINSPARES;

		if( !ticker ) ticker = NHDAPoweredReloaderTracker.GetTicker( newOwner );
		ticker.AttachReloader( self );

		return AddSpareWeaponRegular( newOwner );
	}

	override HDWeapon GetSpareWeapon( Actor newOwner, bool reverse, bool doSelect )
	{
		let wep = GetSpareWeaponRegular( newOwner, reverse, doSelect );

		// don't detach from player ticker ifnot leaving SpareWeapons
		if( !( weaponstatus[ 0 ] & PRLF_NOTINSPARES ) )
		{
			weaponstatus[ 0 ] |= PRLF_NOTINSPARES;

			let reloader = NHDAPoweredReloader( wep );

			if( !ticker ) ticker = NHDAPoweredReloaderTracker.GetTicker( newOwner );
			if( reloader && reloader.weaponstatus[ PRLS_LOCALID ] )
				ticker.DetachReloader( reloader );
		}

		return wep;
	}

	override void Consolidate( void )
	{
		if( ticker ) ticker.CheckBFGCharge( self );

		super.consolidate();
	}

	override void DrawHUDStuff( HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl )
	{
		let this = NHDAPoweredReloader( hdw );
		if( !this ) return;

		if( sb.hudlevel == 1 )
		{
			sb.drawbattery( -54, -4, sb.DI_SCREEN_CENTER_BOTTOM, reloadorder:true );
			sb.drawnum( hpl.countinv( "HDBattery" ), -46, -8, sb.DI_SCREEN_CENTER_BOTTOM );
		}

		int bat = this.battery;
		if( bat > 0 ) sb.drawwepnum( bat, 20 );
		else if( !bat ) sb.drawstring(
			sb.mamountfont, "00000",
			( -16, -9 ), sb.DI_TEXT_ALIGN_RIGHT | sb.DI_TRANSLATABLE | sb.DI_SCREEN_CENTER_BOTTOM,
			Font.CR_DARKGRAY
		);

		sb.drawnum( this.brass,    -36, -17, sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_GOLD );
		sb.drawnum( this.powders,  -26, -17, sb.DI_SCREEN_CENTER_BOTTOM, Font.CR_LIGHTBLUE );
		sb.drawnum( this.livernds, -16, -17, sb.DI_SCREEN_CENTER_BOTTOM );

		super.DrawHUDStuff( sb, hdw, hpl );
	}

	override void InitializeWepStats( bool idfa )
	{
		battery = 20;
	}

	override void Tick( void )
	{
		super.Tick();
		if( ( battery > 0 ) && ( brass > 0 ) && ( powders >= 4 ) )
		{
			progress++;

			// make a round every 8 seconds
			if( progress == 280 )
			{
				if( !owner ) A_StartSound( "rndmaker2/pop", 4 );
				else owner.A_StartSound( "rndmaker2/pop", 30 );

				drainage += 2;
				if( drainage >= 20 )
				{
					battery--;
					drainage -= 20;
				}

				progress = -35;

				brass--;
				powders -= 4;

				livernds++;
			}
			else if( progress > 0 )
				if( !owner ) A_StartSound( "rndmaker2/chug", 5 );
				else owner.A_StartSound( "rndmaker2/chug", 31 );
		}
		else progress = 0;
	}

	int hand;

	states
	{
		ready:
			TNT1 A 1 A_WeaponReady( WRF_ALL );
			goto readyend;

		reload:
			---- A 0
			{
				if(
					invoker.battery < 0
					&& countinv( "HDBattery" )
				)
				{
					invoker.weaponstatus[ 0 ] &= ~PRLF_JUSTUNLOAD;
					setweaponstate( "unmag" );
				}
				else if(
					( invoker.brass   < 20 && countinv( "SevenMilBrass" ) ) ||
					( invoker.powders < 80 && countinv( "FourMilAmmo" ) )
				) setweaponstate( "loadparts" );
			}
			goto nope;

		altreload:
			---- A 0
			{
				if( player.cmd.buttons&BT_USE )
				{
					invoker.weaponstatus[ 0 ] |= PRLF_JUSTUNLOAD;
					setweaponstate( "unmag" );
				}
				else
				{
					invoker.weaponstatus[ 0 ] &= ~PRLF_JUSTUNLOAD;
					if(
						invoker.battery < 20
						&& countinv( "HDBattery" )
					) setweaponstate( "unmag" );
				}
			}
			goto nope;

		user3:
			---- A 0
			{
				if     ( countinv( "HD4mMag"  ) ) A_MagManager( "HD4mMag" );
				else if( countinv( "HD7mMag"  ) ) A_MagManager( "HD7mMag" );
				else if( countinv( "HD7mClip" ) ) A_MagManager( "HD7mClip" );
				else                              A_MagManager( "HDBattery" );
			}
			goto nope;

		user4:
		unloadlive:
			---- A 0 A_Jumpif( invoker.livernds == 0, "ready" );
			---- A 4
			{
				invoker.hand = min( 5, invoker.livernds );
				invoker.livernds -= invoker.hand;
			}
			---- AA 8 A_StartSound( "weapons/pocket", 9 );
			---- A 10
			{
				HDF.Give( self, "SevenMilAmmo", invoker.hand );
				invoker.hand = 0;
			}
			---- A 0 A_Jumpif( PressingUnload(), "unloadlive" );
			goto nope;

		loadparts:
			---- A 16
			{
				let fourm = countinv( "FourMilAmmo" );
				let brass = countinv( "SevenMilBrass" );

				if( // can't load fourmil/brass or not reloading
					( invoker.powders >= 80 || !fourm )
					&& ( invoker.brass >= 20 || !brass )
					|| !PressingReload()
				) {
					setweaponstate( "nope" );
					return;
				}

				let diffBrass = min( 20 - invoker.brass, min( 4, brass ) );
				let diffFourm = min( 80 - invoker.powders, min( 16, fourm ) );

				if( diffBrass ) A_TakeInventory( "SevenMilBrass", diffBrass );
				if( diffFourm ) A_TakeInventory( "FourMilAmmo", diffFourm );

				invoker.brass += diffBrass;
				invoker.powders += diffFourm;

				A_StartSound( "weapons/pocket", 9 );
			}
			loop;

		unmag:
			---- A 5;
			---- A 2 A_StartSound( "weapons/plasopen", 8 );
			---- A 0
			{
				if(
					( invoker.battery < 0 ) ||
					(
						!PressingUnload() &&
						!PressingReload()
					)
				) return resolvestate( "dropmag" );
				return resolvestate( "pocketmag" );
			}

		dropmag:
			---- A 0
			{
				let bat = invoker.battery;
				invoker.battery = -1;

				if( bat >= 0 ) HDMagAmmo.SpawnMag( self, "HDBattery", bat );
			}
			goto magout;

		pocketmag:
			---- A 0
			{
				let bat = invoker.battery;
				invoker.battery = -1;

				if( bat >= 0 ) HDMagAmmo.GiveMag( self, "HDBattery", bat );
			}
			---- AA 8 A_StartSound( "weapons/pocket", 9 );
		magout:
			---- A 0 A_Jumpif( invoker.weaponstatus[ 0 ] & PRLF_JUSTUNLOAD, "Reload3" );
		loadmag:
			---- A 4;
			---- AA 2 A_StartSound( "weapons/pocket", 9 );
			---- A 8;
			---- A 8 A_StartSound( "weapons/plasload", 8 );
			---- A 4 { if( health > 39 ) A_SetTics( 0 ); }
			---- A 4 A_StartSound( "weapons/plasclose", 8 );

			---- A 0
			{
				let mmm = HDMagAmmo( findinventory( "HDBattery" ) );
				if( mmm ) invoker.battery = mmm.TakeMag( true );
			}
		reload3:
			---- A 12 { A_StartSound( "weapons/plasclose2", 8 ); }
			goto nope;

		spawn:
			RLDR A -1;
			stop;
	}
}
