// TODO
class NHDAAttachment : Inventory abstract
{
	override void Tick( void )
	{
		if( master && master.inv != self )
		{
			if( owner )
			{
				let ownerInv = owner;
				do
				{
					if( ownerInv.inv == self )
					{
						ownerInv.inv = inv;
						break;
					}
				}
				while ( ownerInv = ownerInv.inv );
			}

			let masterItem = Inventory( master );

			if( masterItem && masterItem.owner )
			{
				owner = masterItem.owner;
			}
			else owner = master;

			inv = master.inv;
			master.Inv = self;
		}
	}
}
