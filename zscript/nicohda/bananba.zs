// can u fEel it,, b a n an ba ?
class NHDABananaPeel : HDMagAmmo
{
	default
	{
		+inventory.invbar

		radius 12;
		height 8;

		hdmagammo.maxperunit 3;

		hdpickup.bulk 6;
		hdpickup.refid "BNA";

		obituary "%o slipped.";
		tag "banana peel";
	}

	override String PickupMessage( void )
	{
		return "Picked up (and defused) a banana peel.";
	}

	override bool IsUsed( void ) { return true; }

	override bool CanCollideWith( Actor other, bool passive )
	{
		// HDPickerUpper collision
		if( super.CanCollideWith( other, passive ) ) return true;
		if( pos.z > floorZ || vel.z > 0 ) return false;

		let mob = HDMobBase( other );
		let plr = HDPlayerPawn( other );

		let vel = other.vel.xy;

		// value was selected arbitrarily
		if( ( mob || plr ) && vel dot vel >= 4 )
		{
			let magnitude = vel.Length();

			if( mob && mob.health > 0 && !mob.bNoIncap )
			{
				let incapState = mob.FindState( "falldown" );
				if( incapState && !mob.InStateSequence( mob.CurState, incapState ) )
				{
					mob.vel.z += 2;
					mob.vel.xy += AngleToVector( mob.angle, 10 );

					mob.DamageMobj( mob, self, magnitude * 4, 'falling' );

					mob.stunned = magnitude * 40;
					mob.SetState( incapState );
					mob.A_Pain();

					BananaSquish();
					A_StartSound( "banana/slip" );
				}
			}

			if( plr && plr.health > 0 && !plr.incapacitated )
			{
				plr.vel.z += 2;
				plr.vel.xy += AngleToVector( plr.angle, 6 );

				plr.DamageMobj( plr, self, magnitude * 4, 'falling' );

				plr.A_Incapacitated( HDPlayerPawn.HDINCAP_SCREAM, magnitude * 2 );

				// infinite use for the funnies
				//BananaSquish();
				A_StartSound( "banana/slip" );
			}
		}

		return false;
	}

	void BananaSquish()
	{
		mags[ 0 ]--;

		if( mags[ 0 ] == 0 )
		{
			A_ChangeLinkFlags( 1 );
			scale.y = 0.5;
		}
	}

	states
	{
	spawn:
		BNAN A -1;
		stop;

	use:
		TNT1 A 0 { DropInventory( invoker ); }
		fail;
	}
}
