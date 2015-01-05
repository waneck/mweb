package mweb.internal;
import haxe.macro.Context;
import haxe.macro.Context.*;
import haxe.macro.Expr;
import haxe.macro.Type;
import mweb.internal.Data;

class Build
{
	public static function build():Array<Field>
	{
		var fields = getBuildFields();
		var anonf = [];
		for (f in fields)
		{
			var expr = switch(f.kind)
			{
				case FVar( t, e ) | FProp( _, _, t, e ):
					if (e == null)
						e = macro null;
					if (t != null)
						e = { expr:ECheckType(e,t), pos:f.pos };
					e;
				case FFun( fn ):
					{ expr: EFunction(null,fn), pos: f.pos };
			}

			if (f.meta != null)
			{
				var i = f.meta.length;
				while (i --> 0)
				{
					var meta = f.meta[i];
					expr = { expr: EMeta(meta, expr), pos: f.pos };
				}
			}

			anonf.push({ field: f.name, expr: expr });
		}

		var pos = currentPos(),
		    ret = dispatchData( { expr:EObjectDecl(anonf), pos:pos } );
		fields.push({
			name: '_dispatchDataCache',
			access: [AStatic],
			kind: FProp('default','null', macro : mweb.internal.Data.DispatchData, makeExpr( ret, pos )),
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

		return fields;
	}

	public static function dispatchData(anon:Expr):DispatchData
	{
		var metas = [];
		while (true)
		{
			switch(anon.expr)
			{
				case EMeta(m,e):
					metas.push(m);
					anon = e;
				case EParenthesis(e):
					anon = e;
				case _:
					break;
			}
		}

		var pos = anon.pos,
		    atype = typeof(anon);

		var fields = null;
		switch (follow(atype))
		{
			case TAnonymous(anon):
				fields = anon.get().fields;
			case TInst(inst,_):
				fields = inst.get().fields.get();
			case t = TFun(args,ret):
				return RouteVar(getRoutesDef(t,metas));
			case _:
				throw new Error('The type $atype cannot be transformed into a Route', pos);
		}
		return null;
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
									var map = new Map();
									for (field in anon.get().fields)
									{
										map[field.name] = ctype(field.type, pos, field.name);
									}
									argdef = { opt: arg.opt, data: map };
								case _:
									throw new Error('The type of the special argument "args" must be an anonymous type',pos);
							}
						case _:
							addr.push({ name:arg.name, type: typeName(arg.t, pos) });
					}
				}
		}
		return null;
	}

	private static function ctype(t:Type, pos:Position, ?argName:String):CType
	{
		return switch(follow(t))
		{
			case TAnonymous(anon):
				AnonType([ for (field in anon.get().fields) field.name => ctype(field.type, pos, field.name) ]);
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
}
