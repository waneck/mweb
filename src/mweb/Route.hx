package mweb;
import mweb.internal.*;
import mweb.internal.Data;

/**
	A Route is a declarative definition of URI path parts.
	Each public field associated with it will be considered an URI part. All fields' names will be converted
	from `camelCase` to `camel-case` (dash separated).

	## Methods
	Methods are expected to include the HTTP request method (GET,POST,DELETE,...) filtered as part of their name:
	`getPage` will filter only the method GET for the URI part `page`; `postPage` will filter only the method POST;
	To execute no matter what the request method, use `any`: `anyPage` will call the URI part if no specific
	function for the executing HTTP request method is defined.

	You can add arguments to the methods. Each argument will consume another URI part, unless it is a special
	argument. The types will be decoded using either the builtin decoder (for basic types), or by using a `fromString`
	static function inside the type itself, or by using the @:from String field if the type is an abstract. If
	none of these decoders are available, the user must define the decoder by running the function `Dispatcher.addDecoder`.
	Arrays for rest arguments are allowed only if they are the last argument that consumes an URI part (e.g. excluding `args`).
	All the remaining URI parts will be decoded through that.

	If the type `mweb.Dispatcher` is used as any argument, no URI part will be consumed, and the dispatcher will always set
	itself as the argument. This can be used to sub-dispatch or to use the `Dispatcher`'s `getRoute` function

	The special `args` argument, when added as the last argument, will use the GET or POST arguments to decode that type;
	no URI part will be consumed.

	## Fields
	When you include a public field, an URI part will be consumed if it represents the same name as the field. If the
	type of the field represents a Route, a sub-dispatch will happen automatically. Otherwise, if the type is anonymous,
	the Route will continue through that type as well - as if the route itself was defined by `Route.anon`.

	## Metadata
	The special metadatas `@:skip` and `@:skipRoute` may be applied to any field, and will result in the field being ignored
	on the route contruction.
	Any other metadata applied to a method will
 **/
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

	/**
		Creates a route from an anonymous type definition.
		Anything that is done by extending `mweb.Route` can also be done on an anonymous type definition.

		Any field metadata should be applied to the expression inside the anonymous declaration.

		Example:
		```
		Route.anon({
			login: new LoginRoute(ctx),
			getDefault: @:logged function() return sys.io.File.getContents('index.html'),
		});
		```
	 **/
	macro public static function anon(anon:haxe.macro.Expr.ExprOf<Dynamic>, forceDynamic:Bool=false) : haxe.macro.Expr.ExprOf<Route<Dynamic>>
	{
		var pos = anon.pos;
		var mainType = if (forceDynamic)
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
