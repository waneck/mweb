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
		var ct = req.contentType();
		if (ct == null || ct.endsWith('urlencoded'))
			return new mweb.internal.parsers.FormBody().parseRequest(req,maxByteSize);
		else
			return new mweb.internal.parsers.JsonBody().parseRequest(req,maxByteSize);
	}
}
