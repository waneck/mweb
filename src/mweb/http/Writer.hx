package mweb.http;

@:abstract class Writer
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

	public function writeResponse<T>(resp:Response<T>):Void
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
				if (resp.status == 0 || resp.status == 200)
					throw "No content was set";
			case Redirect(to):
				this.redirect(to);
			case Content(data):
				this.write(data.execute());
		}
	}

	/**
		Sets a header
	 **/
	@:abstract public function setHeader(key:String, value:String):Void
	{
		throw 'Not Implemented';
	}

	/**
		Sets the return status
	 **/
	@:abstract public function setStatus(status:Status):Void
	{
		throw 'Not Implemented';
	}

	/**
		Writes to the message body stream
	 **/
	@:abstract public function write(str:String):Void
	{
		throw 'Not Implemented';
	}

	/**
		Redirects
	 **/
	@:abstract public function redirect(to:String):Void
	{
		throw 'Not Implemented';
	}
}
