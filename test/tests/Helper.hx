package tests;

class Helper
{
	macro public static function typeError(expr:haxe.macro.Expr):haxe.macro.Expr
	{
		try
		{
			haxe.macro.Context.typeof(expr);
			return macro @:pos(expr.pos) utest.Assert.fail('This expression was supposed to fail at compile-time');
		}
		catch(e:Dynamic)
		{
			return macro @:pos(expr.pos) utest.Assert.isTrue(true);
		}
	}
}
