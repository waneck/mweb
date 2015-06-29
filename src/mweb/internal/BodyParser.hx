package mweb.internal;
using StringTools;

/**
	The BodyParser will determine how HTTP requests are parsed into dynamic objects.

	If the method is GET, the get parameters will be parsed; otherwise, it will be parsed
	as `application/x-www-form-urlencoded` unless `application/json` is specified as a content-type

	The default BodyParser doesn't support multipart arguments, and they should be handled by a custom parser

	##
 **/
class BodyParser
{
	/**
		The cached instance. Since there is no state in the default
		`BodyParser` type, it can be safely cached and still be thread-safe
	 **/
	public static var cached(default,null) = new BodyParser();

	public function new()
	{
	}

	public function parseRequest(req:mweb.http.Request, ?maxByteSize:Int):{ }
	{
		return null;
		// return switch(req.method())
		// {
		// 	case Get | Head:
		// 		// always urlencoded
		// 		// var data = req.getUriParams().replace(';','&');
		// 		var data = req.uriParams();
		// 		parseForm(data);
		// 	case _:
		// 		switch (req.contentType())
		// 		{
		// 			case 'application/json':
		// 				haxe.Json.parse( req.body(maxByteSize) );
		// 			// case 'application/x-www-form-ulrencoded':
		// 			case _:
		// 				parseForm( req.body(maxByteSize).toString() );
		// 		}
		// }
	}
}
