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
			var t = Type.resolveClass('mweb.internal.AbstractDecoders');
			trace(t);
			if (t != null)
			{
				trace('t != null!');
				Type.createInstance(t,[]).init();
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
