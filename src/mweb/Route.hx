package mweb;
import mweb.internal.*;
import mweb.internal.Data;

@:autoBuild(mweb.internal.Build.build())
@:allow(mweb.Dispatcher)
class Route<T>
{
#if !macro
	public function new()
	{
	}

	private function _getDispatchData():DispatchData
	{
		return throw 'Not Implemented';
	}

	private function _getSubject():{}
	{
		return this;
	}

	// WARNING: Do not override unless you know what you're doing
	private function _getMapFunction():Null<Dynamic->T>
	{
		return null;
	}

	inline public function map<A>(fn:T->A):Route<A>
	{
		return new MappedRoute(this,fn);
	}

	private static function _dispatchDataFromMeta(cl:Class<Dynamic>):DispatchData
	{
		var val = Reflect.field(haxe.rtti.Meta.getType(cl), 'routeRtti');
		if (val == null) throw '(internal mweb error) Expecting route rtti data for ${Type.getClassName(cl)}. Please report this bug';
		var data:String = val[0];
		if (data == null) throw '(internal mweb error) Expecting route rtti data for ${Type.getClassName(cl)}. Please report this bug';
		return haxe.Unserializer.run(data);
	}
#end

	macro public static function route(anon:haxe.macro.Expr.ExprOf<Dynamic>, isDynamic:Bool=false) : haxe.macro.Expr.ExprOf<Route<Dynamic>>
	{
		var pos = anon.pos;
		var mainType = if (isDynamic)
		{
			haxe.macro.Context.typeof(macro (null : Dynamic));
		} else {
			var exp = haxe.macro.Context.getExpectedType();
			if (exp == null)
				null;
			else switch( haxe.macro.Context.follow(exp) )
			{
				case TMono(_):
					null;
				case t = TDynamic(_):
					t;
				case _:
					mweb.internal.Build.routeTypeFromType(exp);
			}
		};
		var t = mweb.internal.Build.dispatchData(anon, mainType);
		var expr = haxe.macro.Context.makeExpr( t.data, pos );
		switch( haxe.macro.Context.follow(t.routeType) )
		{
			case TMono(_):
				return macro new mweb.internal.AnonRoute($anon, $expr);
			case t:
				var complex = haxe.macro.TypeTools.toComplexType(t);
				return macro new mweb.internal.AnonRoute<$complex>($anon, $expr);
		}
	}
}
