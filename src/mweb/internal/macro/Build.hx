package mweb.internal.macro;
import haxe.macro.Context;
import haxe.macro.Context.*;
import haxe.macro.Expr;
import haxe.macro.Type;
import mweb.internal.Data;

using Lambda;
using StringTools;
using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

class Build
{
	public static var firstCompilation = false;
	public static var addedRtti = false;

	private static var typesWithDecoders:Map<String,Bool> = new Map();
	private static var typesToCheck:Map<String,Array<Position>> = new Map();

	private static var definitions:Map<String,HelperClassDefinition> = new Map();

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
		var c = Context.getLocalClass().get();
		var clname = c.name;

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

		// this is a workaround until HaxeFoundation/haxe#4379 isn't solved
		// see commented code at onGenerate
		fields.push({
			name: '__delay_macro_build',
			access: [APrivate,AStatic],
			kind: FFun({
				args: [],
				ret: null,
				expr: macro mweb.internal.macro.Delay.delayTyping()
			}),
			pos: pos
		});

		// make sure this part will only be called once by compilation context
		if( addedRtti ) return fields;
		addedRtti = true;
		if( firstCompilation ) {
			firstCompilation = false;
			Context.onMacroContextReused(function() {
				for (k in definitions.keys())
				{
					var def = definitions[k];
					if (def.mustRebuild())
					{
						definitions.remove(k);
					} else {
						try {
							Context.getType(k); //ensure the type exists
							Context.defineType(def.def);
						}
						catch(e:Dynamic) {
							definitions.remove(k);
						}
					}
				}
				addedRtti = false;
				typesToCheck = new Map();
				// GLOBAL = null;
				return true;
			});
		}

		Context.getModule("mweb.internal.Data");
		var route = typeof( macro (null : mweb.Route<Dynamic>) );

		Context.onGenerate(function(types) {
			// for( t in types )
			// 	switch( t )
			// 	{
			// 	case TInst(c, _) if (unify(t, route) && c.toString() != 'mweb.Route'):
			// 		var c = c.get();
			// 		if (!c.meta.has(':skip') && !c.meta.has('routeRtti'))
			// 		{
			// 			var s = new haxe.Serializer();
			// 			s.useEnumIndex = true;
			// 			// s.useCache = true;
			// 			var data = dispatchDataType(t,c.meta.get(),c.pos,true).data;
			// 			s.serialize(data);
			// 			c.meta.add("routeRtti", [ { expr : EConst(CString(s.toString())), pos : c.pos } ], c.pos);
			// 		}
			// 	default:
			// 	}

			postProcess1(types);
			postProcessAbstracts(types);
			postProcessClasses(types);
		});
		Context.registerModuleReuseCall("mweb.Route", "mweb.internal.Build.build()");
		return fields;
	}

	public static function delayed()
	{
		var c = Context.getLocalClass().get();
		var clname = c.name;

		var t = Context.getLocalType();
		if (t != null && !c.meta.has(':skip') && !c.meta.has('routeRtti'))
		{
			var s = new haxe.Serializer();
			s.useEnumIndex = true;
			// s.useCache = true;
			var data = dispatchDataType(t,c.meta.get(),c.pos,true).data;
			s.serialize(data);
			c.meta.add("routeRtti", [ { expr : EConst(CString(s.toString())), pos : c.pos } ], c.pos);
		}
	}

	private static function postProcess1(types:Array<Type>):Void
	{
		var defs = [];
		for (t in types)
		{
			var t = follow(t);
			switch(t)
			{
				case TInst(_,_) | TEnum(_,_) | TAbstract(_,_):
					switch(t)
					{
						case TAbstract(a, _) if (a.get().isPrivate): continue;
						case _:
					}
					var tn = typeName(t,null,false);
					var t1 = typesToCheck[tn];
					if (t1 != null)
					{
						var dec = typesWithDecoders[tn];
						if (dec != null)
							typesToCheck.remove(tn);
					}
				case _:
			}
		}
	}

	private static function isDynamic(t:Type)
	{
		return switch(follow(t))
		{
			case TDynamic(_): true;
			case _: false;
		}
	}

	private static function createDefFromAbstract(typeName:String, a:AbstractType, type:Type):Void
	{
		var fields = [
			{ name:'String', t:getType('String'), fieldName:null, implict:false },
			{ name:'Int', t:getType('Int'), fieldName:null, implict:false },
			{ name:'Float', t:getType('Float'), fieldName:null, implict:false },
			{ name:'Dynamic', t:getType('Dynamic'), fieldName:null, implict:false },
		];
		// look for @:from types
		for (from in a.from)
		{
			for (field in fields)
			{
				var found = false;
				if (field.name == 'Dynamic')
				{
					if (isDynamic(from.t))
						found = true;
				} else {
					if (unify(from.t,field.t))
						found = true;
				}

				if (found)
				{
					if (from.field == null)
						field.implict = true;
					else
						field.fieldName = from.field.name;
					break;
				}
			}
		}

		// look for fromXXXX types
		var impl = a.impl.get();
		for (field in fields)
		{
			var f = impl.findField('from' + field.name, true);
			if (f != null) switch (follow(f.type)) {
				case TFun([arg],ret) if (unify(arg.t,field.t) && unify(ret,type)):
					field.fieldName = 'from' + field.name;
				case _:
			}
		}

		var objdecl = [],
		    abstrThis = Context.parse(typeName,a.pos);
		trace(abstrThis);
		for (field in fields)
		{
			if (field.fieldName != null)
			{
				var fname = field.fieldName;
				objdecl.push({ field:'from'+field.name, expr:
					macro @:privateAccess $abstrThis.$fname.bind()
				});
			} else if (field.implict) {
				var fname = field.fieldName;
				var type = TPath({ pack:[], name: field.name });
				objdecl.push({ field:'from'+field.name, expr:
					macro function(obj:$type) return obj
				});
			}
		}
		if (objdecl.length > 0)
		{
			var objdecl = { expr: EObjectDecl(objdecl), pos: a.pos };
			var def = macro class {
				@:keep public static var data = $objdecl;
			};
			def.name = typeName.replace('.','_') + '__';
			def.pack = ['mweb','decoders'];
			def.meta = def.fields[0].meta;

			var def = new HelperClassDefinition(typeName,def,getPosInfos(a.pos).file);
			definitions[typeName] = def;
			defineType(def.def);
		}
	}

	private static function postProcessClasses(types:Array<Type>):Void
	{
		inline function warnDecoder(name:String, pos:Position)
		{
			var used = typesToCheck[name];
			if (used != null)
			{
				warning('Abstract type $name needs a decoder for mweb.Dispatcher, but no decoder was found', pos);
				for (pos in used)
					warning('Type $name was used here',pos);
			}
		}
		var defs = [];
		var str = getType('String');
		for (t in types)
		{
			var base:ClassType = null;
			switch(follow(t))
			{
				case TInst(c,_): base = c.get();
				case TEnum(e,_):
					var tn = typeName(t,null,false);
					warnDecoder(tn,e.get().pos);
					continue;
				case TAbstract(a,_) if(!a.get().isPrivate):
					var tn = typeName(t,null,false);
					warnDecoder(tn,a.get().pos);
					continue;
				case _: continue;
			}
			var tn = typeName(t,null,false);
			var t1 = typesToCheck[tn];
			if (t1 != null)
			{
				var dec = typesWithDecoders[tn];
				if (dec == null)
				{
					var fromString = base.statics.get().find(function(cf) return cf.name == "fromString");
					if (fromString == null)
					{
						warnDecoder(tn,base.pos);
					}
				}
			}
		}
	}

	private static function postProcessAbstracts(types:Array<Type>):Void
	{
		var str = getType('String');
		for (t in types)
		{
			switch(follow(t))
			{
				case TAbstract(a,_):
					var a2 = a.get();
					var name = a2.module + '.' + a2.name;
					if (typesToCheck.exists(name) && definitions.exists(name))
						typesToCheck.remove(name);
				case _:
			}
		}

		switch (getType('mweb.Decoder'))
		{
			case TInst(cl,_):
				var cl = cl.get();
				if (cl.meta.has('abstractDefs'))
					cl.meta.remove('abstractDefs');
				var ret = [];
				for (t in definitions)
				{
					ret.push(t.typeName);
					// ret.push(t.def.name);
				}
				cl.meta.add('abstractDefs',[ for (d in ret) macro $v{d} ],Context.currentPos());
			case _:
				throw 'assert';
		}
	}

	public static function registerDecoder(type:Type, pos:Position)
	{
		var name = typeName(type, pos);
		switch(name)
		{
			case "Int" | "String" | "Float" | "Bool" | "mweb.Dispatcher":
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
					fields = inst.get().fields.get();
				} else {
					throw new Error('Invalid field of type ${atype.toString()}. Only fields of anonymous types or other Route types are supported. Use @:skip if you want to skip it.',pos);
				}
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

	private static function takeOffMonos(t:Type):Type
	{
		return switch(follow(t))
		{
			case t = TInst(_,[]) | TEnum(_,[]) | TAbstract(_,[]):
				t;
			case TMono(_):
				TDynamic(null);
			case TInst(cl,tl):
				TInst(cl,[ for (t in tl) takeOffMonos(t) ]);
			case TAbstract(a,tl):
				TAbstract(a,[ for (t in tl) takeOffMonos(t) ]);
			case TEnum(e,tl):
				TEnum(e,[ for (t in tl) takeOffMonos(t) ]);
			case t:
				t;
		}
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
					var complex = takeOffMonos(t).toComplexType();
					macro ( cast null : $complex );
			} ];
			var i = 0;
			var sw = { expr: ESwitch(macro 0, [ for (e in exprs) { values:[macro $v{i++}], expr: e } ], macro null), pos:pos };
			if (mainType != null)
			{
				var complex = mainType.toComplexType();
				if (complex != null)
					sw = macro ( $sw : $complex );
				sw;
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
					var name = StringTools.replace(field.field, "@$__hx__", "");
					var nameverb = splitVerb(name,metas,type.data,field.expr.pos);
					routeTypes.push(type.routeType);
					apos.push(field.expr.pos);

					routes.push({ key:nameverb.name, verb:nameverb.verb, data:type.data, name:name });
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
			case TFun(args,tret):
				var i = 0,
				    addr = [],
						argdef = null;
				for (arg in args)
				{
					i++;
					var opt = arg.opt;
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
							var t = null;
							var many = switch (follow(arg.t))
							{
								case TInst(_.get() => { pack:[], name:'Array' }, [tt]):
									t = tt;
									if (i == args.length || (i == args.length - 1 && args[i].name == 'args'))
										true;
									else
										throw new Error('Array types must be the last parameter before "args" on address arguments', pos);
								case tt:
									t = tt;
									false;
							}
							var type = typeName(t,pos);
							switch [ many, type ]
							{
								case [ false, "mweb.Dispatcher" ]:
									switch(follow(t))
									{
										case TInst(_,[t]):
											if (!unify(t,tret))
												throw new Error("The Dispatcher argument must be of the same generic type as the Route: $t2 should be $t",pos);
										case _: throw 'assert';
									}
								case [ true, "mweb.Dispatcher" ]:
									throw new Error("Cannot use Array<mweb.Dispatcher>", pos);
								case _:
							}
							addr.push({ name:arg.name, type:type, many:many, opt:opt });
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
			case TInst(_.get() => { name:"Array", pack: [] },[t]):
				switch(follow(t))
				{
					case t = TInst(_,_), t = TEnum(_,_), t = TAbstract(_,_):
						TypeName(typeName(t,pos),true);
					case _:
						if (argName != null)
							throw new Error('Unsupported Array type $t for argument $argName', pos);
						else
							throw new Error('Unsupported Array type $t as argument', pos);
				}
			case t = TInst(_,_), t = TEnum(_,_), t = TAbstract(_,_):
				TypeName(typeName(t,pos),false);
			case _:
				if (argName != null)
					throw new Error('Invalid type $t for argument $argName', pos);
				else
					throw new Error('Invalid type $t as argument', pos);
		}
	}

	public static function typeName(t:Type, pos:Position, register=true):TypeName
	{
		inline function reg(ret:String)
		{
			if (register)
			{
				var r = typesToCheck[ret];
				if (r == null)
					typesToCheck[ret] = r = [];
				r.push(pos);
			}
		}
		return switch(follow(t))
		{
			case TInst(c,_):
				var ret = c.toString();
				switch(ret)
				{
					case "String":
					case "mweb.Dispatcher":
					case _:
						reg(ret);
				}
				ret;
			case TEnum(e,_):
				var ret = e.toString();
				var e = e.get();
				var isSimple = true;
				for (field in e.constructs)
				{
					switch(follow(field.type))
					{
						case TEnum(_,_):
						case _:
							isSimple = false;
							break;
					}
				}
				if (!isSimple)
				{
					reg(ret);
				}
				ret;
			case TAbstract(a,_):
				var a2 = a.get();
				if (a2.isPrivate)
					throw new Error('Private abstract type ${t.toString()} is not supported',pos);
				var ret = if (a2.pack.length == 0)
					a.toString()
				else
					a2.module + '.' + a2.name;
				if (register)
				{
					switch(a.toString())
					{
						case "Int" | "Float" | "Bool" | "Single":
						case _ if (a2.impl == null):
							throw new Error('Core type $a is not supported as a mweb Decoder',pos);
						case str:
							if (!definitions.exists(ret)) //already processed
								createDefFromAbstract(ret,a2, t);
							if (!definitions.exists(ret)) //already processed
								reg(str);
					}
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

		var str = toDashSep(str).split('-');
		switch(str[0])
		{
			case 'get' | 'post' | 'delete' | 'patch' | 'put' | 'any':
				// valid verb
				var v = str.shift();
				if (verb != null && verb != v && v != 'any')
					throw new Error('An explicit verb "$verb" was defined for field "$str", but its field already suggests the use of the incompatible verb "$v"', pos);
				verb = v;
			case _:
				if (name == null) name = str.join('-');
		}

		if (name == null)
			name = str.join('-');

		// for (i in 1...str.length)
		// {
		// 	var code = str.charCodeAt(i);
		// 	if (code >= 'A'.code && code <= 'Z'.code || i == (str.length - 1))
		// 	{
		// 		var isLast = !(code >= 'A'.code && code <= 'Z'.code);
		// 		var v = isLast ? str : str.substr(0,i);
		// 		switch(v)
		// 		{
		// 		}
		// 		if (isLast)
		// 			name = '';
		// 		else if (name == null)
		// 			name = str.charAt(i).toLowerCase() + str.substr(i+1);
		// 		if (verb != null && verb != v && v != 'any')
		// 			throw new Error('An explicit verb "$verb" was defined for field "$str", but its field already suggests the use of the incompatible verb "$v"', pos);
		// 		verb = v;
		// 	}
		// }

		switch(type)
		{
			case RouteFunc(_):
			case _:
				if (verb == null) verb = 'any';
		}

		if (name == null || verb == null)
			throw new Error('The route name "$str" doesn\'t start with the verb filter or the special "any" name. If it is not a route, use the metadata @:skip or make the function private to avoid this error.', pos);
		return { name:name, verb:verb };
	}

	public static function toDashSep(s:String):String
	{
		if (s.length <= 1) return s; //allow upper-case aliases
		var buf = new StringBuf();
		var first = true;
		for (i in 0...s.length)
		{
			var chr = s.charCodeAt(i);
			if (chr >= 'A'.code && chr <= 'Z'.code)
			{
				if (!first)
					buf.addChar('-'.code);
				buf.addChar( chr - ('A'.code - 'a'.code) );
				first = true;
			} else {
				buf.addChar(chr);
				first = false;
			}
		}

		return buf.toString();
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

class HelperClassDefinition
{
	public var typeName(default,null):String;
	public var def(default,null):TypeDefinition;
	public var modulePath(default,null):String;
	public var lastChange(default,null):Float;

	public function new(typeName,def,modulePath)
	{
		this.typeName = typeName;
		this.def = def;
		this.modulePath = modulePath;
		this.lastChange = 0;
		mustRebuild();
	}

	public function mustRebuild():Bool
	{
		try
		{
			var change = sys.FileSystem.stat(modulePath).mtime.getTime();
			var last = this.lastChange;
			this.lastChange = change;
			return change > last;
		}
		catch(e:Dynamic)
		{
			return true;
		}
	}
}
