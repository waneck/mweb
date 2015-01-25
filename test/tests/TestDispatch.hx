package tests;
import utest.Assert;
import utest.Assert.*;
import tests.Helper.*;

import mweb.*;
import mweb.Errors;
import mweb.Route.*;
import mweb.internal.Data;

class TestDispatch
{
	public function new()
	{
	}

	inline function dispatch<T>(method,uri,map,r:Route<T>)
	{
		var d = new Dispatcher(HttpRequest.fromData(method,uri,map));
		return d.dispatch(r);
	}

	public function testSimple()
	{
		var r = route({
			getTest: function() return 'getTest',
			postDefault: function(s:Int) { if(!Std.is(s,Int)) throw 'Invalid'; return 'postDefault (' + s + ')'; },
			anyDefault: function() return 'anyDefault',
			anyTest: function() return 'anyTest'
		});
		var val = dispatch('GET','/test/',new Map(),r);
		equals('getTest',val);
		var val = dispatch('POST','/test',new Map(),r);
		equals('anyTest',val);
		var val = dispatch('POST','/12',new Map(),r);
		equals('postDefault (12)',val);
		var val = dispatch('GET','/',new Map(),r);
		equals('anyDefault',val);

		Assert.raises(function() dispatch('GET','/12',new Map(),r), DispatcherError);
		var val = dispatch('GET','/',new Map(),r);
		equals('anyDefault',val);

		Assert.raises(function() dispatch('POST','/',new Map(),r), DispatcherError);

		//map
		var r2 = route({
			anyDefault: r.map(function(s) return '1-$s').map(function(s) return '2-$s').map(function(s) return '3-$s')
		}).map(function(s) return 'end-$s');

		var val = dispatch('GET','/test/',new Map(),r2);
		equals('end-3-2-1-getTest',val);
	}

	public function testAddrArgs()
	{
		var r = route({
			anySimple: function(s:String) return 'anySimple $s',
			anyWithMany: function(f:Float, last:Array<Int>) {
				if (!Std.is(f,Float)) throw 'assert';
				for (a in last) if (!Std.is(a,Int)) throw 'assert';
				return 'anyWithMany $f $last';
			},
			anyWithMany2: function(f:Float, ?last:Array<Int>) {
				if (!Std.is(f,Float)) throw 'assert';
				for (a in last) if (!Std.is(a,Int)) throw 'assert';
				return 'anyWithMany2 $f $last';
			}
		});

		equals('anySimple hello', dispatch('GET','/simple/hello/',new Map(),r));
		raises(function() dispatch('GET','/with-many/10.1/',new Map(),r), DispatcherError);
		equals('anyWithMany 10.1 [1]', dispatch('GET','/with-many/10.1/1',new Map(),r));
		equals('anyWithMany 10.1 [1,30,4]', dispatch('GET','/with-many/10.1/1/30/4',new Map(),r));
		raises(function() dispatch('GET','/with-many/10.1/hello',new Map(),r), DispatcherError);
		equals('anyWithMany2 11.1 []', dispatch('GET','/with-many2/11.1',new Map(),r));
	}

	public function testArgs()
	{
		var r = route({
			anyArgs1: function(s:String, args:{ i:Int, o: { f:Float } })
				return '1: $s ${args.i} ${args.o.f}',
			anyArgs2: function(s:String, args:{ i:Int, ?o: { f:Float, s:String } })
				return '2: $s ${args.i} ${args.o == null ? null : args.o.f} ${args.o == null ? null : args.o.s}',
			anyArgs3: function(s:String, args:{ i:Int, ?o: { f:Float, ?s:String } })
				return '3: $s ${args.i} ${args.o == null ? null : args.o.f} ${args.o == null ? null : args.o.s}',
			anyArgs4: function(s:String, args:{ i:Int, ?o: { f:Float, s:Array<String> } })
				return '4: $s ${args.i} ${args.o == null ? null : args.o.f} ${args.o == null ? null : args.o.s}',
			anyArgs5: function(s:String, args:{ i:Int, ?o: Obj })
				return '5: $s ${args.i} ${args.o == null ? null : args.o.f} ${args.o == null ? null : args.o.s}',
		});

		equals('1: hello 3 4.4', dispatch('GET','/args1/hello',[ "i" => ["3"], "o_f" => ["4.4"] ], r));
		// missing non-optional o_s:
		raises(function() dispatch('GET','/args2/hello',[ "i" => ["3"], "o_f" => ["4.4"] ], r), DispatcherError);
		equals('2: hello 3 4.4 hi', dispatch('GET','/args2/hello',[ "i" => ["3"], "o_f" => ["4.4"], "o_s" => ["hi"] ], r));
		equals('2: hello 3 null null', dispatch('GET','/args2/hello',[ "i" => ["3"] ], r));
		equals('3: hello 3 4.4 null', dispatch('GET','/args3/hello',[ "i" => ["3"], "o_f" => ["4.4"] ], r));
		equals('4: hello 3 4.4 [hi]', dispatch('GET','/args4/hello',[ "i" => ["3"], "o_f" => ["4.4"], "o_s" => ["hi"] ], r));
		equals('5: hello 3 4.4 []', dispatch('GET','/args5/hello',[ "i" => ["3"], "o_f" => ["4.4"] ], r));
		raises(function() dispatch('GET','/args4/hello',[ "i" => ["3"], "o_f" => ["4.4"] ], r), DispatcherError);
	}

	public function testDispatcherArgument()
	{
		typeError( route({ any: function(d:mweb.Dispatcher<Int>) return 'hi' }) );
		var r = route({ any: function(d:mweb.Dispatcher<Int>) { Assert.notNull(d); if (!Std.is(d,mweb.Dispatcher)) Assert.fail(); return 10; } });
		dispatch('GET','/',new Map(),r);
	}

	public function testGetRoute()
	{
		var r = route({
			root: new R1()
		});
		dispatch('GET','/root/test',new Map(),r);
		dispatch('GET','/root/testing/r2/test',new Map(),r);
		dispatch('GET','/root/testing/r2/r3/test',new Map(),r);
	}
}

private class R1 extends Route<String>
{
	public var testing:{ r2:R2 };
	public var r4 = new R4();

	public function new()
	{
		super();
		this.testing = { r2: new R2() };
	}

	public function anyTest(d:Dispatcher<String>)
	{
		Assert.notNull(d.getRoute(R1));
		Assert.notNull(d.getRoute(R2));
		Assert.notNull(d.getRoute(R4));

		return 'hi';
	}
}

private class R2 extends Route<String>
{
	public var r3 = new R3();

	public function anyTest(d:Dispatcher<String>)
	{
		Assert.notNull(d.getRoute(R1));
		Assert.notNull(d.getRoute(R3));
		Assert.notNull(d.getRoute(R4));

		return 'hi';
	}
}

private class R3 extends Route<String>
{
	public function anyTest(d:Dispatcher<String>)
	{
		Assert.notNull(d.getRoute(R1));
		Assert.notNull(d.getRoute(R2));
		Assert.notNull(d.getRoute(R4));

		return 'hi';
	}
}

private class R4 extends Route<String>
{
}

typedef Obj = { f:Float, ?s:Array<String> }
