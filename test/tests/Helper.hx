package tests;
import haxe.macro.Context;

class Helper
{
	macro public static function typeError(expr:haxe.macro.Expr):haxe.macro.Expr
	{
		try
		{
			Context.typeof(expr);
			return macro @:pos(expr.pos) utest.Assert.fail('This expression was supposed to fail at compile-time');
		}
		catch(e:Dynamic)
		{
			return macro @:pos(expr.pos) utest.Assert.isTrue(true);
		}
	}

	macro public static function typeEq(expr:haxe.macro.Expr, eq:haxe.macro.Expr):haxe.macro.Expr
	{
		try
		{
			var t = Context.typeof(expr);
			switch (Context.follow(t))
			{
				case TMono(_):
					return macro @:pos(expr.pos) utest.Assert.fail("This expression has type TMono");
				case t:
					var eq2 = Context.follow(Context.typeof(eq));
					return macro @:pos(expr.pos) utest.Assert.equals($v{t+''},$v{eq2+''});
			}
			return macro @:pos(expr.pos) utest.Assert.equals($eq, $v{t + ''});
		}
		catch(e:Dynamic)
		{
			var val = 'This expression errored with: $e';
			return macro @:pos(expr.pos) utest.Assert.fail($v{val});
		}
	}
}
