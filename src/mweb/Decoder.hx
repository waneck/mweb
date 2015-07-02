package mweb;
#if !macro
import mweb.Errors;
#end
using StringTools;

class Decoder
{
#if !macro
	var data:Map<String, DecoderData>;

	public static var current(get,null):Decoder;

	private static function get_current():Decoder
		return current == null ? (current = new Decoder()) : current;

	private function new()
	{
		this.data = new Map();
		initFromMetas();
	}

	private function initFromMetas()
	{
		var meta = haxe.rtti.Meta.getType(Decoder);
		if (meta != null && meta.abstractDefs != null)
		{
			var dec = data;
			var defs = meta.abstractDefs;
			for (def in defs)
			{
				var name:String = def;
				var cls = Type.resolveClass('mweb.decoders.' + name.replace('.','_'));
				if (cls != null)
				{
					data[name] = Reflect.field(cls, 'data');
				} else {
					trace('WARNING: Type $name was included in build, but the helper class was not found. Perhaps it was eliminated by DCE?');
				}
			}
		}
	}

	private function getData(typeName:String, toCreate=true):DecoderData
	{
		var data = this.data[typeName];
		if (data == null)
		{
			var cls:Dynamic = Type.resolveClass(typeName);
			if (cls == null)
				cls = Type.resolveEnum(typeName);
			if (cls == null)
				throw TypeNotFound(typeName);

			var found = false;
			var d:DecoderData = {};
			inline function findField(name:String)
			{
				var f = Reflect.field(cls, name);
				if (f != null)
				{
					found = true;
					Reflect.setField(d,name,f);
				}
			}
			findField('fromString');
			findField('fromInt');
			findField('fromFloat');
			findField('fromArray');
			findField('fromDynamic');

			if (!found && !toCreate)
			{
				try {
					var ens = Type.getEnumConstructs(cls);
					if (ens != null)
					{
						var ensMap = [for (e in ens) e.toLowerCase() => Type.createEnum(cls,e)];
						d.fromString = function(s:String) return ensMap[s.toLowerCase()];
						var ensArray = [ for (e in ens) Type.createEnum(cls,e) ];
						d.fromInt = function(i:Int) return ensArray[i];
						found = true;
					}
				} catch(e:Dynamic) {
				}
			}

			this.data[typeName] = data = d;
		}
		return data;
	}

	/**
		Decodes `obj` to the type `typeName`
	 **/
	public function decode(typeName:String, obj:Dynamic):Dynamic
	{
		switch(typeName)
		{
			case 'Int':
				if (Std.is(obj,Int))
					return obj;
				if (Std.is(obj,String))
					return Std.parseInt(obj);
				return null;
			case 'Float':
				if (Std.is(obj,Float))
					return obj;
				if (Std.is(obj,String))
				{
					var ret = Std.parseFloat(obj);
					if (Math.isNaN(ret))
						return null;
					return ret;
				}
				return null;
			case 'String':
				if (Std.is(obj,String))
					return obj;
				if (obj == null)
					return null;
				return Std.string(obj);
			case 'Bool':
				if (Std.is(obj,Bool))
					return obj;
				if (obj == null)
					return false;
				return switch (Std.string(obj)) {
					case '1' | 'true' | 'yes':
						true;
					case '0' | 'false' | 'no':
						false;
					case _:
						null;
				}
		}

		var data = getData(typeName,false);

		if (Std.is(obj, Float))
		{
			if (data.fromInt != null && Std.is(obj, Int))
				return data.fromInt(obj);
			if (data.fromFloat != null)
				return data.fromFloat(obj);
		} else if (data.fromString != null && (obj == null || Std.is(obj, String))) {
			return data.fromString(obj);
		} else if (data.fromArray != null && (obj == null || Std.is(obj, Array))) {
			return data.fromArray(obj);
		}
		if (data.fromDynamic != null)
			return data.fromDynamic(obj);
		if (data.fromString != null)
			return data.fromString(Std.string(obj));
		throw DecoderNotFound(typeName);
	}
#end
	/**
		Registers a custom decoder that will be used to decode 'T' types.
		This function is type-checked and calling it will avoid the 'no Decoder was declared' warnings.
		IMPORTANT: this function must be called before the first .dispatch() that uses the custom type is called
	 **/
	macro public static function add(decoder:haxe.macro.Expr.ExprOf<Dynamic->Dynamic>)
	{
		var t = haxe.macro.Context.typeof(decoder);
		var field = null;
		switch(haxe.macro.Context.follow(t))
		{
			case TFun([str],ret):
				var name = function() return mweb.internal.Build.registerDecoder(ret,decoder.pos);
				switch(haxe.macro.Context.follow(str.t))
				{
					case TAbstract(a,_):
						var aname = a.toString();
						if (aname == 'Int')
							return macro @:pos(decoder.pos) @:privateAccess mweb.Decoder.current.getData($v{name()}).fromInt = $decoder;
						if (aname == 'Float')
							return macro @:pos(decoder.pos) @:privateAccess mweb.Decoder.current.getData($v{name()}).fromFloat = $decoder;
					case TInst(i,_):
						var iname = i.toString();
						if (iname == 'String')
							return macro @:pos(decoder.pos) @:privateAccess mweb.Decoder.current.getData($v{name()}).fromString = $decoder;
						if (iname == 'Array')
							return macro @:pos(decoder.pos) @:privateAccess mweb.Decoder.current.getData($v{name()}).fromArray = $decoder;
					case _:
						return macro @:pos(decoder.pos) @:privateAccess mweb.Decoder.current.getData($v{name()}).fromDynamic = $decoder;
				}
				throw 'assert';
			default:
				throw new haxe.macro.Expr.Error("Unsupported decoder type :" + haxe.macro.TypeTools.toString(t), decoder.pos);
		}
	}
}

/**
	In order to support custom types, one must provide a custom Decoder implementation
	**/
// typedef Decoder<T> = String->T;

#if !macro
typedef DecoderData = {
	?fromString:String->Dynamic,
	?fromInt:Int->Dynamic,
	?fromFloat:Float->Dynamic,
	?fromArray:Array<Dynamic>->Dynamic,
	?fromDynamic:Dynamic->Dynamic
}
#end
