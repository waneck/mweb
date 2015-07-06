package mweb.internal;
using StringTools;

/**
	The BodyParser will determine how HTTP requests are parsed into dynamic objects.

	If the method is GET, the get parameters will be parsed; otherwise, it will be parsed
	as `application/x-www-form-urlencoded` unless `application/json` is specified as a content-type

	The default BodyParser doesn't support multipart arguments, and they should be handled by a custom parser
 **/
class BodyParser
{
	public function parseRequest(req:mweb.http.Request):{ }
	{
		throw 'Not Implemented';
	}

	// TODO: provide a MIME (RFC 6838) reader
	public function mimeType():String
	{
		throw 'Not Implemented';
	}
}
