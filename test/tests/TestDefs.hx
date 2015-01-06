package tests;
import utest.Assert;
import utest.Assert.*;
import tests.Helper.*;

import mweb.Route.*;
import mweb.internal.Data;

@:access(mweb.Route) class TestDefs
{
	public function new()
	{
	}

	public function testBasicAnon()
	{
		var r = route({});
		Assert.same( RouteObj({ routes:cast [] }), r._getDispatchData() );

		// skip
		r = route({ a: @:skip 'test' });
		Assert.same( RouteObj({ routes:cast [] }), r._getDispatchData() );

		r = route({ any: function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		r = route({ any: @someMeta function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:['someMeta'], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		// r = route({ something: @:verb(get) function() {} });
		// Assert.same( RouteObj({ routes: cast [{
		// 	key: 'something',
		// 	verb: 'get',
		// 	name: 'something',
		// 	data: RouteFunc({ metas:[], addrArgs:[], args: null })
		// }] }), r._getDispatchData() );

		r = route({ anyTest: function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		r = route({ anyTest: function() {}, getOther: function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		r = route({ anyTest: function() {}, getOther: function() {}, something: {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'something',
			verb: 'any',
			name: 'something',
			data: RouteObj({ routes: cast [] })
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );
		r = route({ anyTest: function() {}, something: {}, getOther: function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'something',
			verb: 'any',
			name: 'something',
			data: RouteObj({ routes: cast [] })
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		r = route({ anyTest: function() {}, getOther: function() {}, something: new RouteDef1() });
		Assert.same( RouteObj({ routes: cast [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'something',
			verb: 'any',
			name: 'something',
			data: RouteCall
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );


		// for now, reserved metadata
		typeError( route({ getSomething: @:verb(get) function() {} }) );
		// this should fail even if we do allow @:verb in the end
		typeError( route({ getSomething: @:verb(delete) function() {} }) );
	}

	public function testAnonArguments()
	{
		var r = route({ any: function(i1:Int) {} });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', many:false }], args: null })
		}] }), r._getDispatchData() );

		//inferred
		r = route({ any: function(i1) { i1 += 10; } });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', many:false }], args: null })
		}] }), r._getDispatchData() );

		r = route({ any: function(i1:Int, a1:String) {} });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', many:false }, { name:'a1', type:'String', many:false }], args: null })
		}] }), r._getDispatchData() );
		r = route({ any: function(i1:Int, a1:SomeAbstract, z1:String) {} });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[
				{ name:'i1', type:'Int', many:false },
				{ name:'a1', type:'tests.SomeAbstract', many:false },
				{ name:'z1', type:'String', many:false }
			], args: null })
		}] }), r._getDispatchData() );

		r = route({ any: function(a1:Int, a2:Array<String>, a3:Array<Int>, a4:String) {} });
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[
				{ name:'a1', type:'Int', many:false },
				{ name:'a2', type:'String', many:true },
				{ name:'a3', type:'Int', many:true },
				{ name:'a4', type:'String', many:false }
			], args: null })
		}] }), r._getDispatchData() );

	}

	public function testBasicClass()
	{
		var r = new RouteDef1();
		Assert.same( RouteObj({ routes: cast [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );
	}
}

abstract SomeAbstract(String)
{
}

private class RouteDef1 extends mweb.Route
{
	public function any()
	{
	}

	public function getOther()
	{
	}
}
