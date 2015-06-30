package mweb.internal.parsers;
using StringTools;

class JsonBody extends BodyParser
{

	override public function parseRequest(req:mweb.http.Request, ?maxByteSize:Int):{ }
	{
		return switch(req.method())
		{
			case Get | Head:
				{};
			case _:
				haxe.Json.parse( req.body(maxByteSize).toString() );
		}
	}

}
