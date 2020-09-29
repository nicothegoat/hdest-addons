#include "zscript/nicohda/modules/powered7mmreloader.zs"
#include "zscript/nicohda/modules/attachments.zs"
#include "zscript/nicohda/modules/crowbar.zs"
#include "zscript/nicohda/modules/bananba.zs"
#include "zscript/nicohda/modules/cfoam.zs"

class NHDAModule abstract play
{
	NHDAHandler master;
	bool enabled;

	void SetEnabled( bool state )
	{
		if( enabled != state )
		{
			enabled = state;

			if( enabled )
				OnEnable();
			else
				OnDisable();
		}
	}
	void ToggleEnabled( void ) { SetEnabled( !enabled ); }

	virtual void Init( void ) {}

	virtual void OnEnable( void ) {}
	virtual void OnDisable( void ) {}

	virtual void ActorSpawned( Actor this ) {}
	virtual void ActorDestroyed( Actor this ) {}
}

class NHDAHandler : EventHandler
{
	transient CVar developer;

	bool HasClass( string className )
	{
		return ( class< object > )( className );
	}

	void AddItemsThatUseThis( string itemClass, string thisClass )
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

	override void OnRegister( void )
	{
		developer = CVar.FindCVar( "developer" );

		itemsThatUseThis = Dictionary.Create();

		modules.clear();

		for( int i = 0; i < allClasses.size(); i++ )
		{
			class< NHDAModule > modClass = ( class< NHDAModule > )( allClasses[ i ] );

			if( modClass && modClass != "NHDAModule" )
				InitModule( modClass );
		}
	}

	override void WorldThingSpawned( WorldEvent event )
	{
		if( event.Thing is 'HDPickup' ) ApplyItemsThatUseThis( HDPickup( event.Thing ) );

		for( int i = 0; i < modules.Size(); i++ )
			modules[ i ].ActorSpawned( event.Thing );
	}

	override void WorldThingDestroyed( WorldEvent event )
	{
		for( int i = 0; i < modules.Size(); i++ )
			modules[ i ].ActorDestroyed( event.Thing );
	}

	private array< NHDAModule > modules;

	private Dictionary itemsThatUseThis;

	private void InitModule( class< NHDAModule > modName )
	{
		let mod = NHDAModule( new( modName ) );
		if( mod )
		{
			modules.push(mod);

			mod.master = self;
			mod.Init();
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

class NHDAMenu : GenericMenu
{
	// TODO
}
