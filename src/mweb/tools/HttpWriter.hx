package mweb.tools;

@:forward abstract HttpWriter(IHttpWriter) from IHttpWriter
{
	@:extern inline public function new(arg)
	{
		this = arg;
	}

	@:from @:extern inline public static function fromWeb(web:LikeWeb):HttpWriter
	{
		return new WebWriter(web);
	}

	public function writeResponse(resp:HttpResponse<Dynamic>)
	{
		var status = resp.status;

		if (resp.status != 0)
		{
			this.setStatus(resp.status);
		}
		for (header in resp.headers)
		{
			this.setHeader(header.key,header.value);
		}
		for (cookie in resp.cookies)
		{
			this.setHeader("Set-Cookie", cookie.key + "=" + cookie.value + (cookie.options == null || cookie.options.length == 0 ? '' : ';' + cookie.options.join(';')));
		}

		switch(resp.response)
		{
			case None:
				throw "No content was set";
			case Redirect(to):
				this.redirect(to);
			case Content(data):
				this.write(data.execute());
		}
	}
}

interface IHttpWriter
{
	/**
		Sets a header
	 **/
	function setHeader(key:String, value:String):Void;

	/**
		Sets the return status
	 **/
	function setStatus(status:HttpStatus):Void;

	/**
		Writes to the message body stream
	 **/
	function write(str:String):Void;

	/**
		Redirects
	 **/
	function redirect(to:String):Void;
}

private typedef LikeWeb = {
	function setHeader(key:String, value:String):Void;
	function setReturnCode(v:Int):Void;
	function redirect(url:String):Void;
}

#if sys
class WebWriter implements IHttpWriter
{
	private var web:LikeWeb;
	public function new(web)
	{
		this.web = web;
	}

	public function setHeader(key:String, value:String):Void
	{
		web.setHeader(key,value);
	}

	public function setStatus(status:HttpStatus):Void
	{
		web.setReturnCode(cast status);
	}

	public function write(str:String):Void
	{
#if croxit_1
		croxit.Output.print(str);
#else
		Sys.print(str);
#end
	}

	public function redirect(to:String):Void
	{
		web.redirect(to);
	}
}
#end
