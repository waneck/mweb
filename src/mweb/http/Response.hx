package mweb.http;
import mweb.tools.*;
using StringTools;

/**
	The Response class can be used to provide a type-safe way to deliver an HTTP response to the client
 **/
@:forward abstract Response<T>(HttpResponseData<T>) from HttpResponseData<T>
{
	@:extern inline public function new()
		this = new HttpResponseData();

	@:from public static function fromContent<T>(data:TemplateLink<T>):Response<T>
		return new HttpResponseData().setContent(data);

	@:from @:extern inline public static function fromStatus<T>(status:Status):Response<T>
		return new HttpResponseData().setStatus(status);

	@:extern inline public static function empty()
		return new Response();
}

class HttpResponseData<T>
{
	public var response(default,null):HttpResponseState<T>;
	public var status(default,null):Status;
	public var headers(default,null):Array<{ key:String, value:String }>;
	public var cookies(default,null):Map<String, { key:String, value:String, options:Array<String> }>;

	public function new()
	{
		this.response = None;
		this.status = 0;
		this.headers = [];
		this.cookies = new Map();
	}

	public function setHeader(key:String, value:String)
	{
		switch(key.toLowerCase())
		{
			case 'set-cookie':
				var r = value.split(';');
				var value = r.shift();

				var hasOpt = false;
				for (r in r)
				{
					if (r.startsWith('Expires') || r.startsWith('Path') || r.startsWith('HttpOnly') || r.startsWith('Secure') || r.startsWith('Domain'))
					{
						hasOpt = true;
						break;
					}
				}
				if (hasOpt || r.length == 0)
				{
					cookies[key] = { key:key, value:r.shift(), options:r };
				} else {
					r.push('$key=$value');
					for (val in r)
					{
						var ei = val.indexOf('=');
						var key = val.substr(0,ei),
								value = val.substr(ei+1);
						cookies[key] = { key:key, value:value, options:null };
					}
				}
			case 'location':
				redirect(value);
			case _:
				headers.push({ key:key, value:value });
		}
		return this;
	}

	public function setCookie(name:String, value:String, ?options:Array<String>)
	{
		cookies[name] = { key:name, value:value, options:options };
		return this;
	}

	public function setStatus(s:Status)
	{
		if (this.status == 0)
			this.status = s;
		else if (s != this.status)
			throw 'Cannot set status twice. Already set for ${this.status}';
		return this;
	}

	public function setContent(data:TemplateLink<T>)
	{
		switch(response)
		{
			case None:
				this.response = Content(data);
			case _:
				throw 'Cannot replace content for state $response';
		}
		return this;
	}

	public function replaceContent(data:TemplateLink<T>)
	{
		switch(response)
		{
			case None | Content(_):
				this.response = Content(data);
			case _:
				throw 'Cannot replace content for state $response';
		}
		return this;
	}

	public function redirect(location:String)
	{
		switch(response)
		{
			case None:
				this.response = Redirect(location);
			case _:
				throw 'Cannot replace redirection for state $response';
		}
		return this;
	}
}

enum HttpResponseState<T>
{
	/**
		Initial state. Nothing was set
	 **/
	None;

	/**
		A redirection is set to happen
	 **/
	Redirect(to:String);

	/**
		Real content will be displayed
	 **/
	Content(data:TemplateLink<T>);
}
