package mweb;
import mweb.internal.Def;

@:autoBuild(mweb.internal.Build.build()) class Route extends Def
{
	public function new()
	{
	}

	macro public static function route(anon:haxe.macro.Expr.ExprOf<Dynamic>) : haxe.macro.Expr.ExprOf<Def>
	{
		var pos = anon.pos;
		var expr = haxe.macro.Context.makeExpr( mweb.internal.Build.dispatchData(anon), pos );
		return macro new mweb.internal.AnonDef($anon, $expr);
	}
}
