package mweb.tools;
import mweb.Errors;

/**
	This class abstracts how requests are validated and generated. Normally, one would use
	`PostRequestValidator`, which parses a POST request as a series of URL encoded name=value pairs.

	However, on some cases one may expect also to receive a JSON encoded object, or other kinds of data.

	The dispatcher will delegate the choice of a validator to this
 **/
class RequestValidator
{
	/**
		Builds and validates the `args` object based on the `arg` argument descriptor; `err` is an object
		that provides additional contextual information should any error be found
	 **/
	public function buildArgs(request:HttpRequest, arg:{ key:String, opt:Bool, type:CType }, err:DispatcherError):Dynamic
	{
		throw 'Not Implemented';
	}
}


class PostRequestValidator extends RequestValidator
{
	public function new()
	{
	}

	override public function buildArgs(request:HttpRequest, arg:{ key:String, opt:Bool, type:CType }, err:DispatcherError):Dynamic
	{
	}

	private function getInitialData(request:HttpRequest):Map<String, Array<String>>
	{
	}

	static function splitArgs(data:String, into:Map<String,Array<String>>)
	{
		if (data == null || data.length == 0)
			return;
		for ( part in data.split("&") )
		{
			var i = part.indexOf("=");
			var k = part.substr(0, i);
			var v = part.substr(i + 1);
			if ( v != "" )
				v = StringTools.urlDecode(v);
			var data = into[k];
			if (data == null)
			{
				into[k] = data = [];
			}
			data.push(v);
		}
	}
}
