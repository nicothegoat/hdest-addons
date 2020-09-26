struct NHDA
{
	// runtime class check
	static clearscope bool HasClass( string className )
	{
		return ( class< object >)( className );
	}
}
