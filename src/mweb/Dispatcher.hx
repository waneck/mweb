package mweb;
import mweb.internal.Data;
import mweb.internal.*;
import mweb.Errors;

class Dispatcher<T>
{
#if !macro
	public var request(default,null):HttpRequest;
	public var originalURI(default,null):String;
	public var uri(get,never):String;

	private var pieces:Array<String>;
	private var args:Map<String,Array<String>>;
	private var verb:String;

	private function new(request:HttpRequest)
	{
		this.request = request;
		var uri = this.originalURI = request.getURI();
		this.pieces = splitURI(uri);
		this.verb = request.getMethod().toLowerCase();

		var args = this.args = new Map();
		switch(verb)
		{
			case "get":
				splitArgs( StringTools.replace(request.getParamsString(), ';', '&'), args );
			case _:
				splitArgs( request.getPostData(), args );
		}
	}

	private static function splitArgs(data:String, into:Map<String,Array<String>>)
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

	private static function splitURI(uri:String)
	{
		var p = uri.split('/'),
		    np = [];
		for (part in p)
		{
			switch(part)
			{
				case '..':
					if (np.length == 0)
						throw InvalidURI(uri, "The URI goes beyond the server root");
					np.pop();
				case '.' | '':
				case _:
					np.push(part);
			}
		}

		np.reverse();
		return np;
	}

	private function get_uri()
	{
		var ret = new StringBuf(),
		    pieces = this.pieces,
		    len = pieces.length;
		while (len --> 0)
		{
			ret.add(pieces[len]);
			if (len != 0)
				ret.add('/');
		}
		return ret.toString();
	}

	public function dispatch(route:Route<T>):T
	{
		var route:Route<Dynamic> = route;
		var map = route._getMapFunction();
		var data = route._getDispatchData();
		var subj = route._getSubject();
		var pieces = pieces;

		var lastUri = pieces[pieces.length-1];
		var fields = [];

		while (true)
		{
			var idx = pieces.length - 1;
			var cur = pieces[idx];
			if (cur == null)
				cur = '';
			switch (data)
			{
				case RouteObj(objData):
				case RouteFunc(fn):
					if (!Reflect.isFunction(subj))
						throw new DispatcherError(lastUri, fields, Internal(InvalidFunction(subj)));
					var callArgs:Array<Dynamic> = [];
					for (arg in fn.addrArgs)
					{
						var argArray = callArgs;
						if (arg.many)
						{
							argArray = [];
							callArgs.push(argArray);
						}

						do
						{
							cur = pieces.pop();
							if (cur == null)
							{
								if (!arg.opt)
									throw new DispatcherError(lastUri, fields, MissingAddrArguments(arg.name));
								argArray.push(null);
							} else {
									var t = getDecoderFor(arg.type)(cur);
								if (t == null)
									throw new DispatcherError(lastUri, fields, InvalidArgumentType(cur,arg.type));
								argArray.push(t);
							}
						} while(arg.many && pieces.length > 0);
					}

					if (fn.args != null)
					{
						callArgs.push(buildArgs({ key:'', opt:fn.args.opt, type:AnonType(fn.args.data) }, ''));
					}
				case RouteCall:
					if (!Std.is(subj, Route))
						throw new DispatcherError(lastUri, fields, Internal(InvalidRoute(subj)));
					route = cast subj;
					subj = route._getSubject();
					data = route._getDispatchData();
			}
		}
		return null;
	}

	private static var decoders(get,null):Map<String,Decoder<Dynamic>>;

	private function buildArgs(arg:{ key:String, opt:Bool, type:CType }, prefix:String):Dynamic
	{
		var name = prefix + arg.key;
		switch(arg.type)
		{
			case TypeName(name,many):
			case AnonType(names):
		}
		return null;
	}

	private static function getDecoderFor<T>(typeName:String):Null<String->T>
	{
		var ret = decoders[typeName];
		if (ret == null)
		{
			var cls:Dynamic = Type.resolveClass(typeName);
			if (cls == null)
				cls = Type.resolveEnum(typeName);
			if (cls == null)
				throw TypeNotFound(typeName);
			ret = Reflect.field(cls,'fromString');
			if (ret != null)
			{
				decoders[typeName] = ret;
			} else {
				try
				{
					var ens = Type.getEnumConstructs(cls);
					if (ens != null)
					{
						var ens = [for (e in ens) e.toLowerCase() => Type.createEnum(cls,e)];
						ret = function(s:String) return ens[s.toLowerCase()];
						decoders[typeName] = ret;
					}
				}
				catch(e:Dynamic)
				{
				}
				if (ret == null)
					throw DecoderNotFound(typeName);
			}
		}
		return ret;
	}

	private static function get_decoders()
	{
		if (decoders == null)
		{
			decoders = [
				"Int" => function(v) return Std.parseInt,
				"Float" => function(v):Null<Float> { var ret = Std.parseFloat(v); if (Math.isNaN(ret)) return null; return ret; },
				"String" => function(s) return s,
			];
			var meta = haxe.rtti.Meta.getType(Dispatcher);
			if (meta != null && meta.abstractDefs != null)
			{
				var dec = decoders;
				var defs = meta.abstractDefs;
				for (def in defs)
				{
					var name:String = def.name;
					// trace(name);
					if (def.fnName == null)
					{
						dec[name] = function(s:String) return s;
					} else {
						var t = Type.resolveClass(def.type);
						if (t != null)
						{
							var fn = Reflect.field(t,def.fnName);
							if (fn == null)
								trace('WARNING: Type $name was included in build, but the field ${def.fnName} was not found. Perhaps it was eliminated by DCE?');
							else
								dec[name] = fn;
						}
					}
				}
			}
		}
		return decoders;
	}

	public static function addDecoderRuntime<T>(name:String, d:Decoder<T>):Void
	{
		decoders.set(name,d);
	}

	// public function getRoute<T : Route>(t:Class<T>):Opt<T>
	// {
	// }
#end

	/**
		Registers a custom Decoder<T> that will be used to decode 'T' types.
		This function is type-checked and calling it will avoid the 'no Decoder was declared' warnings.
		IMPORTANT: this function must be called before the first .dispatch() that uses the custom type is called
	 **/
	macro public static function addDecoder(decoder:haxe.macro.Expr.ExprOf<Decoder<Dynamic>>)
	{
		var t = haxe.macro.Context.typeof(decoder);
		var field = null;
		var type = switch(haxe.macro.Context.follow(t))
		{
			case TFun([str],ret) if (haxe.macro.Context.unify(str.t, haxe.macro.Context.getType("String"))):
				ret;
			default:
				throw new haxe.macro.Expr.Error("Unsupported decoder type :" + haxe.macro.TypeTools.toString(t), decoder.pos);
		}
		var name = mweb.internal.Build.registerDecoder(type,decoder.pos);
		return macro mweb.Dispatcher.addDecoderRuntime($v{name}, $decoder);
	}
}
