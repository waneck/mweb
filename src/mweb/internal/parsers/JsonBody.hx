package mweb.internal.parsers;
using StringTools;

class JsonBody extends BodyParser
{
	public var maxByteSize:Null<Int>;

	public function new()
	{
	}

	override public function parseRequest(req:mweb.http.Request):{ }
	{
		return switch(req.method())
		{
			case Get | Head:
				{};
			case _:
				var body = req.body(maxByteSize).toString();
				if (body == '')
					{};
				else
					haxe.Json.parse(body);
		}
	}

	override public function mimeType():String
	{
		return 'application/json';
	}
}
