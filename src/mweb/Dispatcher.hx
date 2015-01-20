package mweb;
import mweb.internal.Data;
import mweb.internal.*;

class Dispatcher<T>
{
	private function new()
	{
	}

	public function dispatch(route:Route<T>):T
	{
		return null;
	}

	private static var decoders(get,null):Map<String,Decoder<Dynamic>>;

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
				throw new Error("Unsupported decoder type :" + haxe.macro.TypeTools.toString(t), decoder.pos);
		}
		var name = mweb.internal.Build.registerDecoder(type);
		return macro mcli.Dispatch.addDecoderRuntime($v{name}, $decoder);
	}

	private static function getDecoderFor<T>(typeName:String):Null<String->T>
	{
		return decoders[typeName];
	}

	private static function get_decoders()
	{
		if (decoders == null)
		{
			decoders = new Map();
			var meta = haxe.rtti.Meta.getType(Dispatcher);
			if (meta != null && meta.abstractDefs != null)
			{
				var dec = decoders;
				var defs = meta.abstractDefs;
				for (def in defs)
				{
					var name:String = def.name;
					trace(name);
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
}
