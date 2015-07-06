package mweb.http;
import haxe.io.*;

using StringTools;

/**
	Abstract class that represents an HTTP Request.

	Any new platform support in mweb should override this and the `Writer` class.
 **/
@:abstract class Request
{
	/**
		The configuration object. Must be set by the constructor
	 **/
	public var config(default,null):mweb.Config;

	private function new(?config:mweb.Config)
	{
		if (config == null) config = mweb.Config.defaultConfig;
		this.config = config;
	}

	/**
		Should return the method (verb) used by the request - values like GET/POST.

		This implementation should support `X-HTTP-Method` header overrides
	 **/
	public function method():Verb
	{
		var method = methodImpl().toUpperCase();
		if (method == "POST")
		{
			// look for the method override header
			var moverride = header('X-HTTP-Method');
			if (moverride == null) moverride = header('X-HTTP-Method-Override');
			if (moverride == null) moverride = header('X-Method-Override');
			if (moverride != null)
				return moverride.toUpperCase();
		}

		return method;
	}

	@:abstract private function methodImpl():String
	{
		throw 'Not implemented';
	}

	/**
		Should return the URI queried by the HTTP request
	 **/
	@:abstract public function uri():String
	{
		throw 'Not implemented';
	}

	/**
		Returns the GET parameter string
	 **/
	@:abstract public function uriParams():String
	{
		throw 'Not implemented';
	}

	/**
		Returns the body of the request.

		If `maxByteSize` is specified, the size restriction *must* be enforced,
		and will only take into effect if it's lower than the restriction set by
		`config.maxBodyByteSize`
	 **/
	@:abstract public function body(?maxByteSize:Int):haxe.io.Bytes
	{
		if (maxByteSize != null)
		{
			if (config.maxBodyByteSize != null)
				if (maxByteSize > config.maxBodyByteSize)
					maxByteSize = config.maxBodyByteSize;
		} else {
			maxByteSize = config.maxBodyByteSize;
		}
		return _body(maxByteSize);
	}

	/**
		Returns the body of the request.

		If `maxByteSize` is specified, the size restriction *must* be enforced,
		and if the POST size is bigger than `maxByteSize`, an exception of
		type `mweb.Errors.RequestError.PostSizeTooBig` must be thrown.
	 **/
	private function _body(maxByteSize:Null<Int>):haxe.io.Bytes
	{
		throw 'Not Implemented';
	}

	/**
		Returns the client header that corresponds to `name` (case insensitive).
		If no client header with this name was found, `null` is returned
	 **/
	@:abstract public function header(name:String):Null<String>
	{
		throw 'Not implemented';
	}

	/**
		Returns all client headers as a Map, where the keys are the
		lowercase headers
	 **/
	@:abstract public function headers():Map<String,Array<String>>
	{
		throw 'Not implemented';
	}

	/**
		Returns the client IP address, as a String
	 **/
	@:abstract public function ip():String
	{
		throw 'Not implemented';
	}

	/**
		Parse the multipart data. Call `onPart` with the parameters (input name, file name)
		when a new part is found with the part name and the filename if present
		and `onData` when some part data is read. You can this way
		directly save the data on hard drive in the case of a file upload.

		`onComplete` is called when the multipart is done. This is specially useful on asynchronous
		platforms, since there would be no way to know when a stream has finished otherwise
	**/
	@:abstract public function parseMultipart(onPart:String->String->Void, onData:Bytes->Int->Int->Void, ?onComplete:Void->Void):Void
	{
		throw 'Not implemented';
	}

	/**
		Gets the parsed parameter object

		The GET and POST parameters will be parsed as urlencoded parameters,
		unless `Content-Type` is set to `application/json`. If it is, the body
		will be parsed as a JSON object.

		In order to understand how arguments are normally parsed, see `mweb.internal.BodyParser`

		If a custom parser is needed, one can use `customParser`
	 **/
	public function params(?customParser:mweb.internal.BodyParser):{ }
	{
		var parser = customParser;
		if (parser == null)
		{
			parser = this.config.parserFromMime( this.contentType() );
		}

		if (parser == null)
		{
			throw mweb.Errors.ParseError.InvalidMimeType(this.contentType());
		}

		return parser.parseRequest(this);
	}

	/**
		Returns the content type of the request.
	 **/
	public function contentType():Null<String>
	{
		var ret = header('content-type');
		if (ret == null)
		{
			if (method() == Get)
				return null;
			else
				return 'application/octet-stream';
		} else {
			return ret.split(';')[0].trim().toLowerCase();
		}
	}
}
