package mweb.tools;

/**
	An `HttpRequest` represents a
 **/
@:forward abstract HttpRequest(IHttpRequestData) from IHttpRequestData
{
	@:extern inline public function new(data)
	{
		this = data;
	}

	@:from inline public static function fromWeb(cls:LikeWeb):HttpRequest
	{
		return new WebRequest(cls);
	}

	public static function fromData(method:String, uri:String, ?params:Map<String,Array<String>>):HttpRequest
	{
		return new HttpRequestStatic(method,uri,params == null ? new Map() : params);
	}

	public function withURI(uri:String):HttpRequest
	{
		var ret = new ProxyOverride(this);
		ret.uri = uri;
		return ret;
	}

}

interface IHttpRequestData
{
	/**
		Should return the method (verb) used by the request - values like GET/POST
	 **/
	public function getMethod():String;

	/**
		Should return the URI queried by the HTTP request
	 **/
	public function getUri():String;

	/**
		Returns the GET parameter string
	 **/
	public function getParams():String;

	/**
		Returns the body of the request
	 **/
	public function getBody():haxe.io.Bytes;

	/**
		Returns the client header that corresponds to `name` (case insensitive).
		If no client header with this name was found, `null` is returned
	 **/
	public function getHeader(name:String):Null<String>;

	/**
		Returns the client IP address, as a String
	 **/
	public function getIp():String;
}

class ProxyOverride implements IHttpRequestData
{
	public var proxy(default,null):IHttpRequestData;

	public var method:String;
	public var uri:String;
	public var params:String;
	public var body:haxe.io.Bytes;
	public var headers:Map<String,String>;
	public var ip:String;

	public function new(proxy)
	{
		this.proxy = proxy;
	}

	public function getMethod():String
	{
		return if (method != null) method else proxy.getMethod();
	}

	public function getUri():String
	{
		return if (uri != null) uri else proxy.getUri();
	}

	public function getParams():String
	{
		return if (params != null) params else proxy.getParams();
	}

	public function getBody():haxe.io.Bytes
	{
		return if (body != null) body else proxy.getBody();
	}

	public function getHeader(name:String):Null<String>
	{
		return if (headers != null && headers.exists(name)) headers[name] else proxy.getHeader(name);
	}

	public function getIp():String
	{
		return if (ip != null) ip else proxy.getIp();
	}
}

class HttpRequestStatic implements IHttpRequestData
{
	var method:String;
	var uri:String;
	var params:Map<String,Array<String>>;

	public function new(method,uri,params)
	{
		this.method = method;
		this.uri = uri;
		this.params = params;
	}

	/**
		Should return the method (verb) used by the request - values like GET/POST
	 **/
	public function getMethod():String
	{
		return method;
	}

	/**
		Should return the URI queried by the HTTP request
	 **/
	public function getUri():String
	{
		return uri;
	}

	/**
		Should return a String containing the parameters.
		It is advised that as a security measure on a non-GET request, only the parameters passed
		through the body of the message are sent here.
	 **/
	public function getParamsData():Map<String,Array<String>>
	{
		return params;
	}
}

private typedef LikeWeb = {
	function getMethod():String;
	function getURI():String;
	function getParamsString():String;
	function getPostData():String;
	function getClientHeader(k:String):Null<String>;
}

private class WebRequest implements IHttpRequestData
{
	var web:LikeWeb;
	public function new(web)
	{
		this.web = web;
	}

	public function getMethod():String
	{
		var method = web.getMethod();

		if (method.toLowerCase() != "get")
		{
			var h = web.getClientHeader('X-Http-Method-Override');
			if (h != null) switch (h.toLowerCase()) {
				case 'delete' | 'patch' | 'put':
					return h.toUpperCase();
				case _:
			}
		}
		return method;
	}

	public function getUri():String
	{
		return web.getURI();
	}

	public function getParamsData():Map<String,Array<String>>
	{
		var verb = web.getMethod();
		var args = new Map();

		switch(verb.toLowerCase())
		{
			case "get":
				HttpRequest.splitArgs( StringTools.replace(web.getParamsString(), ';', '&'), args );
			case _:
				HttpRequest.splitArgs( web.getPostData(), args );
		}

		return args;
	}
}
