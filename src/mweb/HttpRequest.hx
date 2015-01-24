package mweb;

typedef HttpRequestData = {
	/**
		Should return the method (verb) used by the request - values like GET/POST
	 **/
	function getMethod():String;

	/**
		Should return the URI queried by the HTTP request
	 **/
	function getURI():String;

	/**
		Should return a String containing the GET parameters.
	 **/
	function getParamsString():String;

	/**
		Should return a String containing the body of the HTTP request.

		If the request was a GET request, it must return an empty String, otherwise
		an `InvalidRequest` error will be thrown
	 **/
	function getPostData():String;

	@:optional function getParamsData():Map<String,Array<String>>;
}

@:forward abstract HttpRequest(HttpRequestData) from HttpRequestData
{
	@:extern inline public function new(data)
	{
		this = data;
	}

	public static function fromData(method:String, uri:String, params:Map<String,Array<String>>):HttpRequest
	{
		return {
			getMethod:function() return method,
			getURI:function() return uri,
			getParamsString:function() return '',
			getPostData:function() return '',
			getParamsData:function() return params
		}
	}

	public function withURI(uri:String)
	{
	}
}
