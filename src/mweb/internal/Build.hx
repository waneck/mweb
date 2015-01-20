package mweb.internal;
import haxe.macro.Context;
import haxe.macro.Context.*;
import haxe.macro.Expr;
import haxe.macro.Type;
import mweb.internal.Data;

using Lambda;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

class Build
{
	public static var firstCompilation = false;
	public static var addedRtti = false;

	private static var typesWithDecoders:Map<String,Bool> = new Map();
	private static var typesToCheck:Map<String,Array<Position>> = new Map();
	private static var usedAbstracts:Map<String,Bool> = new Map();

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
				typesToCheck = new Map();
				// GLOBAL = null;
				return true;
			});
		}

		Context.getModule("mweb.internal.Data");
		var route = typeof( macro (null : mweb.Route<Dynamic>) );

		Context.onGenerate(function(types) {
			for( t in types )
				switch( t )
				{
				case TInst(c, _) if (unify(t, route) && c.toString() != 'mweb.Route'):
					var c = c.get();
					if (!c.meta.has(':skip') && !c.meta.has('routeRtti'))
					{
						var s = new haxe.Serializer();
						s.useEnumIndex = true;
						// s.useCache = true;
						var data = dispatchDataType(t,c.meta.get(),c.pos,true).data;
						s.serialize(data);
						c.meta.add("routeRtti", [ { expr : EConst(CString(s.toString())), pos : c.pos } ], c.pos);
					}
				default:
				}

			postProcessAbstracts(types);
		});
		Context.registerModuleReuseCall("mweb.Route", "mweb.internal.Build.build()");
		return fields;
	}

	private static function postProcessAbstracts(types:Array<Type>):Void
	{
		var defs = [];
		var str = getType('String');
		for (t in types)
		{
			switch(follow(t))
			{
				case TAbstract(a,_) if (usedAbstracts[a.toString()] && !a.get().isPrivate):
					var name = a.toString();
					var a = a.get();
					var fnName = null,
							found = true;
					if (a.impl != null)
					{
						var impl = a.impl.get();
						for (field in impl.statics.get())
						{
							if (field.name == 'fromString')
							{
								fnName = field.name;
								found = true;
								break;
							}
						}
					}
					if (fnName == null && a.from != null)
					{
						for (f in a.from)
						{
							if (unify(f.t,str))
							{
								if (f.field != null)
									fnName = f.field.name;
								found = true;
							}
						}
					}

					// trace('here',name,found,fnName);
					if (found)
					{
						var impl = null;
						if (a.impl != null) impl = a.impl.get();
						var def = {
							type: impl == null ?
								a.pack.join('.') + (a.pack.length == 0 ? '' : '.') + a.name :
								impl.pack.join('.') + '.' + impl.name,
							fnName: fnName,
							name: name
						}
						// expr = macro mweb.Dispatcher.addDecoderRuntime($v{name},@:privateAccess $expr);
						// exprs.push(expr);
						defs.push(def);
					} else {
						var used = typesToCheck[name];
						if (used != null)
						{
							warning('Abstract type $name needs a decoder for mweb.Dispatcher, but no decoder was found',a.pos);
							for (pos in used)
								warning('Type $name was used here',pos);
						}
					}
				case _:
			}
		}

		switch (getType('mweb.Dispatcher'))
		{
			case TInst(cl,_):
				var cl = cl.get();
				if (cl.meta.has('abstractDefs'))
					cl.meta.remove('abstractDefs');
				cl.meta.add('abstractDefs',[ for (d in defs) macro $v{d} ],Context.currentPos());
			case _:
				throw 'assert';
		}
	}

	public static function registerDecoder(type:Type, pos:Position)
	{
		var name = typeName(type, pos);
		switch(name)
		{
			case "Int" | "String" | "Float" | "Bool" | "Single":
				throw new Error('Cannot register decoder for basic type $name',pos);
			case _:
				typesWithDecoders[name] = true;
		}
		return name;
	}

	public static function routeTypeFromType(t:Type)
	{
		if (t == null) return null;
		switch (follow(t))
		{
			case TInst(_.get() => ({ name:"Route", pack:["mweb"] } | { name:"AnonRoute", pack:["mweb","internal"] }), [t]):
				switch(follow(t))
				{
					case TDynamic(_):
						return typeof(macro (null : Dynamic));
					case _:
				}
			case _:
		}
		// find out which Route<T> type it actually is
		// use Haxe's own type inference to do that
		var monoRoute = typeof(macro {
			function getRoute<T>():mweb.Route<T> { return null; }
			getRoute();
		} );
		if (unify(t, monoRoute))
		{
			switch(follow(monoRoute))
			{
				case TInst(_.get() => { name:"Route" }, [t]):
					return t;
				case _:
					throw "assert";
			}
		}
		return null;
	}

	private static function dispatchDataType(atype:Type, metas:Array<MetadataEntry>, pos:Position, toplevel=false):{ data:DispatchData, routeType:Type }
	{
		var fields = null,
		    typeToUnify = null;
		switch (follow(atype))
		{
			case TAnonymous(anon):
				fields = anon.get().fields;
			case t = TInst(inst,_):
				var tuni = routeTypeFromType(t);
				if (tuni != null)
				{
					if (toplevel)
						typeToUnify = tuni;
					else
						return { data:RouteCall, routeType: tuni };
				}
				fields = inst.get().fields.get();
			case t = TFun(args,ret):
				return { data:RouteFunc(getRoutesDef(t,metas,pos)), routeType: ret };
			case _:
				throw new Error('The type $atype cannot be transformed into a Route', pos);
		}

		var routes = [],
		    routeTypes = [];
		for (field in fields)
		{
			var metas = field.meta.get();
			if (!field.isPublic || metas.exists(function(m) return m.name == ':skip'))
				continue;

			var type = dispatchDataType(field.type,metas,field.pos);
			var nameverb = splitVerb(field.name,metas,type.data,field.pos);

			routes.push({ key:nameverb.name, verb:nameverb.verb, data:type.data, name:field.name });
			routeTypes.push(type.routeType);
		}

		var t = unifyTypes(routeTypes, typeToUnify, pos, function() return [
			for (i in 0...routeTypes.length)
			{
				var r = routes[i],
				    t = routeTypes[i];
				var f = fields.find(function(cf) return cf.name == r.name);
				new Error('Field ${r.name}: type $t',f != null ? f.pos : pos);
			} ]);

		return { data:RouteObj({ routes: ArrayMap.fromArray(routes) }), routeType: t };
	}

	private static function unifyTypes(types:Array<Type>, mainType:Null<Type>, pos:Position, warnings:Void->Array<Error>)
	{
		if (types.length == 0)
			if (mainType == null)
				return typeof( macro (null : Dynamic) );
			else
				return mainType;
		try
		{
			var exprs = [ for (t in types) switch(follow(t)) {
				case TDynamic(null) | TMono(_):
					macro null;
				case _:
					var complex = t.toComplexType();
					macro ( cast null : $complex );
			} ];
			var i = 0;
			var sw = { expr: ESwitch(macro 0, [ for (e in exprs) { values:[macro $v{i++}], expr: e } ], macro null), pos:pos };
			if (mainType != null)
			{
				var complex = mainType.toComplexType();
				sw = macro ( $sw : $complex );
			}

			var t = typeof(sw);
			return mainType != null ? mainType : t;
		}
		catch(e:Error)
		{
			if (!Context.defined("mweb_testing"))
			{
				Context.warning('Cannot build route with current types: type mismatch',pos);
				if (mainType != null)
					Context.warning('All routes must return an object that is of type $mainType',pos);
				Context.warning('The following route types were inferred:',pos);
				for (msg in warnings())
					Context.warning(msg.message,msg.pos);
			}
			throw new Error(e.message, pos);
		}
	}

	public static function dispatchData(anon:Expr, mainType:Null<Type>):{ data: DispatchData, routeType: Type }
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
				var routes = [],
				    routeTypes = [],
				    apos = [];
				for (field in fields)
				{
					updMetas(field.expr);
					if (metas.exists(function(m) return m.name == ':skip'))
						continue;
					var type = dispatchData(field.expr, mainType);
					var nameverb = splitVerb(field.field,metas,type.data,field.expr.pos);
					routeTypes.push(type.routeType);
					apos.push(field.expr.pos);

					routes.push({ key:nameverb.name, verb:nameverb.verb, data:type.data, name:field.field });
				}
				var t = unifyTypes(routeTypes, mainType, anon.pos, function()
					return [ for (i in 0...routes.length) new Error('Field ${routes[i].name}: type ${routeTypes[i]}', apos[i]) ]);
				return { data: RouteObj({ routes: ArrayMap.fromArray(routes) }), routeType:t };
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
										map.push({ key:field.name, type:ctype(field.type, pos, field.name), opt:field.meta.has(':optional') });
									}
									argdef = { opt: arg.opt, data: ArrayMap.fromArray(map) };
								case _:
									throw new Error('The type of the special argument "args" must be an anonymous type',pos);
							}
						case _:
							switch (follow(arg.t))
							{
								case TInst(_.get() => { pack:[], name:'Array' }, [t]):
									addr.push({ name:arg.name, type:typeName(t, pos), many:true });
								case t:
									addr.push({ name:arg.name, type: typeName(t, pos), many:false });
							}
					}
				}
				return { metas: [ for (m in metas) if (!isInternalMeta(m.name)) m.name ], addrArgs:addr, args: argdef };
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
				AnonType(ArrayMap.fromArray([ for (field in anon.get().fields) { key:field.name, type:ctype(field.type, pos, field.name), opt:field.meta.has(':optional') }]));
			case t = TInst(_,_), t = TEnum(_,_), t = TAbstract(_,_):
				TypeName(typeName(t,pos));
			case _:
				if (argName != null)
					throw new Error('Invalid type $t for argument $argName', pos);
				else
					throw new Error('Invalid type $t as argument', pos);
		}
	}

	public static function typeName(t:Type, pos:Position, register=true):TypeName
	{
		return switch(follow(t))
		{
			case TInst(c,_): c.toString();
			case TEnum(e,_): e.toString();
			case TAbstract(a,_):
				var a2 = a.get();
				if (a2.isPrivate)
					throw new Error('Private abstract type ${t.toString()} is not supported',pos);
				var ret = a.toString();
				switch(ret)
				{
					case "Int" | "String" | "Float" | "Bool" | "Single":
					case _:
						usedAbstracts[ret] = true;
				}
				ret;
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
					throw new Error('Reserved metadata: "route"', meta.pos);
				case [ (':verb' | 'verb'), [{ expr:EConst(CString(s)) } | { expr: EConst(CIdent(s)) }] ]:
					verb = s;
					throw new Error('Reserved metadata: "verb"', meta.pos);
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
