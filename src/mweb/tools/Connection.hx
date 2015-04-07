package mweb.tools;

class Connection implements Dynamic<Connection>
{
	public var addr(default,null):String;
	public var kind(default,null):SerializationKind;

	public function new(addr:String, ?serKind:SerializationKind)
	{
		if (serKind == null)
			serKind = Auto;
		this.addr = addr;
		this.kind = serKind;
	}

	public function resolve(addrPart:String):Connection
	{
		return new Connection('$addr/$addrPart', kind);
	}

	public function call(?verb = HttpVerb.Post, ?addrArgs:Array<Dynamic>, ?args:Dynamic):Dynamic
	{
		var addr = this.addr;
		if (addrArgs != null)
			addr += '/' + addrArgs.join('/');

		var http = new haxe.Http(addr);
		if (args != null)
			CnxHelper.setParameters(http, args, '');

		var isPost = false;
		switch(verb)
		{
			case Post:
				isPost = true;
			case Get:
			case v:
				isPost = true;
				// haxe.Http limitation: use X-Http-Method-Override
				http.setHeader('X-Http-Method-Override',v);
		}

		var ret:Dynamic = null;
		inline function getKind()
		{
			var ser = http.responseHeaders['X-Serialized-With'];
			return switch(kind)
			{
				case Auto:
					if (ser == 'JSON')
						Json;
					else if (ser == 'HAXE')
						HaxeSerialization;
					else
						throw 'Cannot determine method used to serialize response: $ser';
				case v:
					v;
			};
		}

		http.onData = function(data:String) {
			var kind = getKind();
			if (data != '') switch(kind)
			{
				case Json:
					ret = haxe.Json.parse(data);
				case HaxeSerialization:
					ret = haxe.Unserializer.run(data);
				case _:
					throw 'Unsupported serialized input while connecting to $addr: $kind';
			}
		};

		http.onError = function(err:String) {
			var kind = getKind();
			var ret:Dynamic = null;
			try
			{
				if (err != '') switch(kind)
				{
					case Json:
						ret = haxe.Json.parse(data);
					case HaxeSerialization:
						ret = haxe.Unserializer.run(data);
					case _:
						throw 'Unsupported serialized input while connecting to $addr: $kind';
				}
			}
			catch(e:Dynamic)
			{
				ret = 'An error was discovered when connecting to $addr. Additionally, the error could not be unserialized properly: $e';
			}
			throw ret;
		};

		http.request(isPost);
	}
}
