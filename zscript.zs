version 4.3.3

// ples do not the looking at spaghetti code

#include "zscript/nicohda/powered7mmreloader.zs"
#include "zscript/nicohda/attachments.zs"
#include "zscript/nicohda/crowbar.zs"
#include "zscript/nicohda/bananba.zs"
#include "zscript/nicohda/cfoam.zs"

class NHDAHandler : EventHandler
{
	transient CVar developer;

	bool HasClass( string className )
	{
		return ( class< object > )( className );
	}

	override void OnRegister( void )
	{
		developer = CVar.FindCVar( "developer" );

		itemsThatUseThis = Dictionary.Create();

		AddItemsThatUseThis( "HDBattery",     "NHDAPoweredReloader" );
		AddItemsThatUseThis( "HD4mMag",       "NHDAPoweredReloader" );
		AddItemsThatUseThis( "FourMilAmmo",   "NHDAPoweredReloader" );
		AddItemsThatUseThis( "SevenMilBrass", "NHDAPoweredReloader" );
	}

	override void WorldThingSpawned( WorldEvent event )
	{
		if( event.Thing is 'HDPickup' ) ApplyItemsThatUseThis( HDPickup( event.Thing ) );
	}

	private Dictionary itemsThatUseThis;

	private void AddItemsThatUseThis( string itemClass, string thisClass )
	{
		let item = itemClass.MakeLower();

		let itutString = itemsThatUseThis.At( item );

		itutString.AppendFormat( "%s;", thisClass );

		itemsThatUseThis.Insert( item, itutString );

		if( !developer ) developer = CVar.FindCVar( "developer" );
		if( developer.GetBool() )
		{
			if( !HasClass( itemClass ) ) console.printf( "Missing item class \"%s\"", itemClass );
			if( !HasClass( thisClass ) ) console.printf( "Missing item class \"%s\"", thisClass );
		}
	}

	private void ApplyItemsThatUseThis( HDPickup thing )
	{
		array< string > tmp;
		// GetClassName is an expression, not a function. (WHY???????)
		string className = thing.GetClassName();
		itemsThatUseThis.At( className.MakeLower() ).Split( tmp, ";", TOK_SKIPEMPTY );

		for( int i = 0; i < tmp.Size(); i++ )
			thing.ItemsThatUseThis.Push( tmp[ i ] );
	}
}
