package mweb.tools;

@:forward abstract HttpWriter(IHttpWriter) from IHttpWriter
{
	@:extern inline public function new(arg)
	{
		this = arg;
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
			this.setHeader(cookie.key, cookie.value + (cookie.options == null || cookie.options.length == 0 ? '' : ';' + cookie.options.join(';')));
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
