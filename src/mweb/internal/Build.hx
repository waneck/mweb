package mweb.internal;
import haxe.macro.Context;
import haxe.macro.Context.*;
import haxe.macro.Expr;
import haxe.macro.Type;
import mweb.internal.Data;

using Lambda;

class Build
{
	public static var firstCompilation = false;
	public static var addedRtti = false;

	public static function build():Array<Field>
	{
		var fields = getBuildFields();
		if (fields.exists(function(f) return f.name == '_getDispatchData'))
		{
			if (!getLocalClass().get().meta.has(':skip'))
				warning('This class already has a _getDispatchData definition; It is however not marked with the @:skip metadata',currentPos());
			return null;
		}

		var pos = currentPos();
		var clname = Context.getLocalClass().get().name;

		fields.push({
			name: '_dispatchDataCache',
			access: [AStatic],
			kind: FProp('default','null', macro : mweb.internal.Data.DispatchData, macro mweb.Route._dispatchDataFromMeta($i{clname})),
			pos: pos
		});
		fields.push({
			name: '_getDispatchData',
			access: [AOverride],
			kind: FFun({
				args: [],
				ret: macro : mweb.internal.Data.DispatchData,
				expr: macro return _dispatchDataCache
			}),
			pos: pos,
		});

		if( addedRtti ) return fields;
		addedRtti = true;
		if( firstCompilation ) {
			firstCompilation = false;
			Context.onMacroContextReused(function() {
				addedRtti = false;
				// GLOBAL = null;
				return true;
			});
		}

		Context.getModule("mweb.internal.Data");
		var route = Context.getType('mweb.Route');

		Context.onGenerate(function(types) {
			for( t in types )
				switch( t ) {
				case TInst(c, _) if (unify(route, t) && c.toString() != 'mweb.Route'):
					trace('here',c);
					var c = c.get();
					if (!c.meta.has(':skip') && !c.meta.has('routeRtti'))
					{
						var s = new haxe.Serializer();
						s.useEnumIndex = true;
						s.useCache = true;
						var data = dispatchDataType(t,c.meta.get(),c.pos);
						s.serialize(data);
						c.meta.add("routeRtti", [ { expr : EConst(CString(s.toString())), pos : c.pos } ], c.pos);
					}
				default:
				}
		});
		Context.registerModuleReuseCall("mweb.Route", "mweb.internal.Build.build()");
		return fields;
	}

	private static function dispatchDataType(atype:Type, metas:Array<MetadataEntry>, pos:Position):DispatchData
	{
		var fields = null;
		switch (follow(atype))
		{
			case TAnonymous(anon):
				fields = anon.get().fields;
			case TInst(inst,_):
				fields = inst.get().fields.get();
			case t = TFun(args,ret):
				return RouteFunc(getRoutesDef(t,metas,pos));
			case _:
				throw new Error('The type $atype cannot be transformed into a Route', pos);
		}

		var routes = [];
		for (field in fields)
		{
			var metas = field.meta.get();
			if (!field.isPublic || metas.exists(function(m) return m.name == ':skip'))
				continue;

			var type = dispatchDataType(field.type,metas,field.pos);
			var nameverb = splitVerb(field.name,metas,type,field.pos);

			routes.push({ key:nameverb.name, verb:nameverb.verb, data:type, name:field.name });
		}

		return RouteObj({ routes: ArrayMap.fromArray(routes) });
	}

	public static function dispatchData(anon:Expr):DispatchData
	{
		var metas = null;
		inline function updMetas(expr:Expr)
		{
			metas = [];
			while (true)
			{
				switch(expr.expr)
				{
					case EMeta(m,e):
						metas.push(m);
						expr = e;
					case EParenthesis(e):
						expr = e;
					case _:
						break;
				}
			}
			return expr;
		}

		anon = updMetas(anon);
		var anonMetas = metas;

		switch(anon.expr)
		{
			case EObjectDecl(fields):
				var routes = [];
				for (field in fields)
				{
					updMetas(field.expr);
					if (metas.exists(function(m) return m.name == ':skip'))
						continue;
					var type = dispatchData(field.expr);
					var nameverb = splitVerb(field.field,metas,type,field.expr.pos);

					routes.push({ key:nameverb.name, verb:nameverb.verb, data:type, name:field.field });
				}
				return RouteObj({ routes: ArrayMap.fromArray(routes) });
			case _:
				var t = typeof(anon);
				return dispatchDataType(t,anonMetas,anon.pos);
		}
	}

	private static function getRoutesDef(t:Type, metas:Array<MetadataEntry>, pos:Position):RoutesDef
	{
		switch(follow(t))
		{
			case TFun(args,_):
				var i = 0,
				    addr = [],
						argdef = null;
				for (arg in args)
				{
					i++;
					switch(arg.name)
					{
						case 'args':
							if (i != args.length)
								throw new Error('The special argument with name "args" must be the last argument of the function',pos);
							switch(follow(arg.t))
							{
								case TAnonymous(anon):
									var map = [];
									for (field in anon.get().fields)
									{
										map.push({ key:field.name, type:ctype(field.type, pos, field.name) });
									}
									argdef = { opt: arg.opt, data: ArrayMap.fromArray(map) };
								case _:
									throw new Error('The type of the special argument "args" must be an anonymous type',pos);
							}
						case _:
							addr.push({ key:arg.name, type: typeName(arg.t, pos) });
					}
				}
				return { metas: [ for (m in metas) if (!isInternalMeta(m.name)) m.name ], addrArgs: ArrayMap.fromArray(addr), args: argdef };
			case _:
				throw new Error('(internal assert) The type $t is not a function', pos);
		}
		return null;
	}

	private static function ctype(t:Type, pos:Position, ?argName:String):CType
	{
		return switch(follow(t))
		{
			case TAnonymous(anon):
				AnonType(ArrayMap.fromArray([ for (field in anon.get().fields) { key:field.name, type:ctype(field.type, pos, field.name) }]));
			case t = TInst(_,_), t = TEnum(_,_), t = TAbstract(_,_):
				TypeName(typeName(t,pos));
			case _:
				if (argName != null)
					throw new Error('Invalid type $t for argument $argName', pos);
				else
					throw new Error('Invalid type $t as argument', pos);
		}
	}

	private static function typeName(t:Type, pos:Position):TypeName
	{
		return switch(follow(t))
		{
			case TInst(c,_): c.toString();
			case TEnum(e,_): e.toString();
			case TAbstract(a,_): a.toString();
			case _:
				throw new Error('Type ${follow(t)} is not supported as an address argument',pos);
		}
	}

	private static function splitVerb(str:String, meta:Array<MetadataEntry>, type:DispatchData, pos:Position):{ name:String, verb:String }
	{
		var name = null,
		    verb = null;

		for (meta in meta)
		{
			switch [meta.name, meta.params]
			{
				case [ (':route' | 'route'), [{ expr:EConst(CString(s)) } | { expr: EConst(CIdent(s)) }] ]:
					name = s;
				case [ (':verb' | 'verb'), [{ expr:EConst(CString(s)) } | { expr: EConst(CIdent(s)) }] ]:
					verb = s;
				case _:
			}
		}

		switch(type)
		{
			case RouteFunc(_):
				for (i in 1...str.length)
				{
					var code = str.charCodeAt(i);
					if (code >= 'A'.code && code <= 'Z'.code || i == (str.length - 1))
					{
						var isLast = !(code >= 'A'.code && code <= 'Z'.code);
						var v = isLast ? str : str.substr(0,i);
						switch(v)
						{
							case 'get' | 'post' | 'delete' | 'patch' | 'put' | 'any':
								// valid verb
							case _:
								if (name == null) name = str;
								break;
						}
						if (isLast)
							name = '';
						else if (name == null)
							name = str.charAt(i).toLowerCase() + str.substr(i+1);
						if (verb != null && verb != v && v != 'any')
							throw new Error('An explicit verb "$verb" was defined for field "$str", but its field already suggests the use of the incompatible verb "$v"', pos);
						verb = v;
					}
				}
			case _:
				if (verb == null) verb = 'any';
				name = str;
		}

		if (name == null || verb == null)
			throw new Error('The route name "$str" doesn\'t start with the verb filter or the special "any" name. If it is not a route, use the metadata @:skip or make the function private to avoid this error.', pos);
		return { name:name, verb:verb };
	}

	private static function isInternalMeta(name:String)
	{
		return switch(name)
		{
			case 'verb' | ':verb' | 'route' | ':route' | ':skip':
				true;
			case _:
				false;
		}
	}
}
