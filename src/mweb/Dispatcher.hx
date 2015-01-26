package mweb;
import mweb.internal.Data;
import mweb.internal.*;
import mweb.tools.*;
import mweb.Errors;

/**
	A Dispatcher does the dynamic dispatch from an HTTP Request, guided by a `mweb.Route`.
	The type parameter of the Dispatcher relates to the return type of the routes' functions. It may be `Void`
 **/
class Dispatcher<T>
{
#if !macro
	/**
		The original Http Request
	 **/
	public var request(default,null):HttpRequest;

	/**
		The current URI, with the processed arguments taken off
	 **/
	public var uri(get,never):String;

	private var pieces:Array<String>;
	private var args:Map<String,Array<String>>;
	private var verb:String;

	private var routeStack:Array<Route<Dynamic>>;
	private var metaHandlers:Array<Array<String>->Void>;

	/**
		Creates a new Dispatcher class from an HTTP Request. See `mweb.HttpRequest`
	 **/
	public function new(request:HttpRequest)
	{
		this.request = request;
		var uri = request.getUri();
		this.pieces = splitUri(uri);
		this.verb = request.getMethod().toLowerCase();
		this.routeStack = [];
		this.metaHandlers = [];
		this.args = request.getParamsData();
	}

	/**
		Adds a function that is called with all the metadata of the function to be called by the dispatcher.
	 **/
	public function addMetaHandler(handler:Array<String>->Void):Void->Void
	{
		if (metaHandlers.indexOf(handler) < 0)
		{
			metaHandlers.push(handler);
		}

		return function() metaHandlers.remove(handler);
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

	private static function splitUri(uri:String)
	{
		var p = uri.split('/'),
		    np = [];
		for (part in p)
		{
			switch(part)
			{
				case '..':
					if (np.length == 0)
						throw InvalidUri(uri, "The URI goes beyond the server root");
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

	/**
		Dispatches the current HTTP request to the associated function that is specified to deal with thati through `route`
	 **/
	public function dispatch(route:Route<T>):T
	{
		var last = this.routeStack;
		this.routeStack = last.copy();
		try
		{
			var ret = _dispatch(route);
			this.routeStack = last;
			return ret;
		}

		catch(e:Dynamic)
		{
			this.routeStack = last;
#if neko
			neko.Lib.rethrow(e);
#elseif cpp
			cpp.Lib.rethrow(e);
#elseif java
			java.Lib.rethrow(e);
#elseif cs
			cs.Lib.rethrow(e);
#else
			throw e;
#end
		}
		return null;
	}

	private function _dispatch(route:Route<T>):T
	{
		var route:Route<Dynamic> = route;
		var maps = [];
		{
			var map = route._getMapFunction();
			if (map != null)
				maps.push(map);
		}

		var rstack = this.routeStack;
		rstack.push(route);
		var data = route._getDispatchData();
		var subj:Dynamic = route._getSubject();
		var pieces = pieces;

		var lastUri = pieces[pieces.length-1];
		var fields = [];
		var ethis = subj;

		while (true)
		{
			var idx = pieces.length - 1;
			var cur = pieces[idx];
			if (cur == null)
				cur = '';
			switch (data)
			{
				case RouteObj(objData):
					var n = pieces.pop();
					var wasNull = n == null;
					if (wasNull)
						n = '';

					lastUri = n;
					var best = null;
					objData.routes.forEachKey(n, function(route) {
						if (route.verb == 'any' || route.verb == verb)
						{
							if (best == null || route.verb == verb)
								best = route;
						}
					});
					if (best == null)
					{
						objData.routes.forEachKey('default', function(route) {
							if (route.verb == 'any' || route.verb == verb)
							{
								if (best == null || route.verb == verb)
									best = route;
							}
						});
						if (best != null && n != null && !wasNull)
							pieces.push(n);
					}

					if (best == null)
						throw new DispatcherError(lastUri, fields, NoRouteFound(n));

					fields.push(best.name);
					subj = Reflect.field(subj, best.name);
					data = best.data;
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
							if (arg.type == 'mweb.Dispatcher')
							{
								argArray.push(this);
								break;
							}

							cur = pieces.pop();
							if (cur == null)
							{
								if (!arg.opt)
									throw new DispatcherError(lastUri, fields, MissingAddrArguments(arg.name));
								if (!arg.many)
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
						callArgs.push(buildArgs({
							key:'', opt:fn.args.opt, type:AnonType(fn.args.data)
						}, '', new DispatcherError(lastUri, fields, null)));
					}

					for (handler in this.metaHandlers)
					{
						handler(fn.metas);
					}

					var ret = Reflect.callMethod(ethis, subj, callArgs);
					var i = maps.length;
					while (i --> 0)
					{
						ret = maps[i](ret);
					}

					if (this.pieces.length > 0)
					{
						var p = pieces.copy();
						p.reverse();

						throw new DispatcherError(lastUri,fields,TooManyValues(p));
					}

					return ret;
				case RouteCall:
					if (!Std.is(subj, Route))
						throw new DispatcherError(lastUri, fields, Internal(InvalidRoute(subj)));
					route = cast subj;
					rstack.push(route);

					subj = route._getSubject();
					ethis = subj;
					data = route._getDispatchData();
					var map = route._getMapFunction();
					if (map != null)
						maps.push(map);
			}
		}
		return null;
	}

	private static var decoders(get,null):Map<String,Decoder<Dynamic>>;

	private function buildArgs(arg:{ key:String, opt:Bool, type:CType }, prefix:String, err:DispatcherError):Dynamic
	{
		var name = prefix + arg.key;
		switch(arg.type)
		{
			case TypeName(tname,many):
				var uarg = this.args[name];
				if (uarg == null)
					if (arg.opt && many)
						return [];
					else
						return null;
				if (uarg.length > 1 && !many)
					throw err.withError(MultipleParamValues(name,uarg));
				if (many)
				{
					return [ for (arg in uarg) {
						var t = getDecoderFor(tname)(arg);
						if (t == null)
							throw err.withError(InvalidArgumentType(arg,tname));
						t;
					} ];
				} else {
					var t = getDecoderFor(tname)(uarg[0]);
					if (t == null)
						throw err.withError(InvalidArgumentType(uarg[0],tname));
					return t;
				}
			case AnonType(fields):
				var ret:Dynamic = {};
				var hasValue = false;
				var failedFields = [];

				var prefix = name == '' ? name : name +'_';
				for (field in fields)
				{
					var arg = buildArgs(field,prefix,err);
					if (arg == null)
					{
						if (!field.opt)
							failedFields.push(prefix + field.key);
					} else {
						hasValue = true;
						Reflect.setField(ret, field.key, arg);
					}
				}

				if (hasValue && failedFields.length > 0)
					throw err.withError(MissingArgument(failedFields));
				if (!hasValue)
				{
					if (arg.opt)
						return null;
					else
						err.withError(MissingArgument([arg.key]));
				}
				return ret;
		}
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
				"Int" => function(v) return Std.parseInt(v),
				"Float" => function(v):Null<Float> { var ret = Std.parseFloat(v); if (Math.isNaN(ret)) return null; return ret; },
				"String" => function(s) return s,
				"Bool" => function(s:String):Null<Bool> return switch(s.toLowerCase()) {
					case "1" | "true" | "yes":
						true;
					case "0" | "false" | "no":
						false;
					case _:
						null;
				}
			];
			var meta = haxe.rtti.Meta.getType(Dispatcher);
			if (meta != null && meta.abstractDefs != null)
			{
				var dec = decoders;
				var defs = meta.abstractDefs;
				for (def in defs)
				{
					var name:String = def.name;
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

	/**
		The dynamic (non-macro) version of `addDecoder`. Use of `addDecoder` is advised in order to take advatange of the
		compile-time checking if all arguments used have their appropriate decoders associated.
	 **/
	public static function addDecoderRuntime<T>(name:String, d:Decoder<T>):Void
	{
		decoders.set(name,d);
	}

	/**
		Gets a route from the current dispatching Route.
	 **/
	public function getRoute<T : Route<Dynamic>>(t:Class<T>):Null<T>
	{
		var rstack = this.routeStack,
		    i = rstack.length;

		while (i --> 0)
		{
			var route = rstack[i];
			if (Std.is(route,t))
				return cast route;
			var data = route._getDispatchData();
			var ret = traverseRoute(route._getSubject(),data,t);
			if (ret != null) return ret;
		}
		return null;
	}

	private static function traverseRoute<T : Route<Dynamic>>(ethis:Dynamic, data:DispatchData, type:Class<T>):Null<T>
	{
		switch(data)
		{
			case RouteCall:
				if (Std.is(ethis,type))
					return ethis;
			case RouteFunc(_):
				return null;
			case RouteObj(data):
				for (route in data.routes)
				{
					switch(route.data)
					{
						case RouteObj(_) | RouteCall:
							var ret = traverseRoute(Reflect.field(ethis,route.name), route.data, type);
							if (ret != null)
								return ret;
						case _:
					}
				}
		}
		return null;
	}
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
