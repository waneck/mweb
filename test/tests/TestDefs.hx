package tests;
import utest.Assert;
import utest.Assert.*;
import tests.Helper.*;

import mweb.Route;
import mweb.Route.*;
import mweb.internal.Data;
import mweb.internal.*;

@:access(mweb.Route) class TestDefs
{
	public function new()
	{
	}

	public function testBasicAnon()
	{
		var r = route({});
		Assert.same( RouteObj({ routes:[] }), r._getDispatchData() );

		// skip
		var r = route({ a: @:skip 'test' });
		Assert.same( RouteObj({ routes:[] }), r._getDispatchData() );

		var r = route({ any: function() {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		var r = route({ any: @someMeta function() {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:['someMeta'], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		// var r = route({ something: @:verb(get) function() {} });
		// Assert.same( RouteObj({ routes: [{
		// 	key: 'something',
		// 	verb: 'get',
		// 	name: 'something',
		// 	data: RouteFunc({ metas:[], addrArgs:[], args: null })
		// }] }), r._getDispatchData() );

		var r = route({ anyTest: function() {} });
		Assert.same( RouteObj({ routes: [{
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		var r = route({ anyTest: function() {}, getOther: function() {} });
		Assert.same( RouteObj({ routes: [{
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

		var r = route({ anyTest: function() {}, getOther: function() {}, something: {} });
		Assert.same( RouteObj({ routes: [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'something',
			verb: 'any',
			name: 'something',
			data: RouteObj({ routes: [] })
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );
		var r = route({ anyTest: function() {}, something: {}, getOther: function() {} });
		Assert.same( RouteObj({ routes: [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}, {
			key: 'something',
			verb: 'any',
			name: 'something',
			data: RouteObj({ routes: [] })
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		var r = route({ anyTest: function() {}, getOther: function() {}, something: new RouteDef1() });
		Assert.same( RouteObj({ routes: [{
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

	public function testAddrArgs()
	{
		var r = route({ any: function(i1:Int) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', opt:false, many:false }], args: null })
		}] }), r._getDispatchData() );

		//inferred
		var r = route({ any: function(i1) { i1 += 10; } });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', opt:false, many:false }], args: null })
		}] }), r._getDispatchData() );

		//optional
		var r = route({ any: function(?i1) { i1 += 10; } });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', opt:true, many:false }], args: null })
		}] }), r._getDispatchData() );
		var r = route({ any: function(i1=10) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', opt:true, many:false }], args: null })
		}] }), r._getDispatchData() );

		var r = route({ any: function(i1:Int, a1:String) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', opt:false, many:false }, { name:'a1', type:'String', opt:false, many:false }], args: null })
		}] }), r._getDispatchData() );
		var r = route({ any: function(i1:Int, a1:SomeAbstract, z1:String) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[
				{ name:'i1', type:'Int', opt:false, many:false },
				{ name:'a1', type:'tests.SomeAbstract', opt:false, many:false },
				{ name:'z1', type:'String', opt:false, many:false }
			], args: null })
		}] }), r._getDispatchData() );

		var r = route({ any: function(a1:Int, a2:String, a3:Int, a4:Array<String>) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[
				{ name:'a1', type:'Int', opt:false, many:false },
				{ name:'a2', type:'String', opt:false, many:false },
				{ name:'a3', type:'Int', opt:false, many:false },
				{ name:'a4', type:'String', opt:false, many:true }
			], args: null })
		}] }), r._getDispatchData() );

		var r = route({ any: function(a1:Int, a2:String, a3:Int, a4:Array<String>, ?args:{}) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[
				{ name:'a1', type:'Int', opt:false, many:false },
				{ name:'a2', type:'String', opt:false, many:false },
				{ name:'a3', type:'Int', opt:false, many:false },
				{ name:'a4', type:'String', opt:false, many:true }
			], args: { opt: true, data:[] } })
		}] }), r._getDispatchData() );

		// not supported
		typeError( route({ any: function(a:{ something:Int }) {} }) );
	}

	public function testArgs()
	{
		var r = route({ post: function(args:{ v1:Int, a1:String }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: false,
				data:[{
					key: 'a1',
					opt: false,
					type: TypeName('String',false)
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int',false)
				}]
			} })
		}] }), r._getDispatchData() );

		var r = route({ post: function(?args:{ a1:String }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: true,
				data:[{
					key: 'a1',
					opt: false,
					type: TypeName('String',false)
				}]
			} })
		}] }), r._getDispatchData() );
		var r = route({ post: function(args:{ v1:Int, ?a1:String }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: false,
				data:[{
					key: 'a1',
					opt: true,
					type: TypeName('String',false)
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int',false)
				}]
			} })
		}] }), r._getDispatchData() );

		var r = route({ post: function(args:{ v1:Int, ?a1:{ otherField: Float, a1:Int } }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: false,
				data:[{
					key: 'a1',
					opt: true,
					type: AnonType([{
						key: 'a1',
						opt: false,
						type: TypeName('Int',false)
					}, {
						key: 'otherField',
						opt: false,
						type: TypeName('Float',false)
					}])
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int',false)
				}]
			} })
		}] }), r._getDispatchData() );

		var r = route({ post: function(args:{ v1:Int, a1:{ ?otherField: Float, a1:Int } }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: false,
				data:[{
					key: 'a1',
					opt: false,
					type: AnonType([{
						key: 'a1',
						opt: false,
						type: TypeName('Int',false)
					}, {
						key: 'otherField',
						opt: true,
						type: TypeName('Float',false)
					}])
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int',false)
				}]
			} })
		}] }), r._getDispatchData() );

		//inferred
	}

	public function testBasicClass()
	{
		var r = new RouteDef1();
		Assert.same( RouteObj({ routes: [{
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

	public function testInferenceClass()
	{
		var r = new RouteDefInference();
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{
				name:'a',
				type:'Float',
				opt:false, many:false
			}, {
				name:'c',
				type:'String',
				opt:false, many:false
			}, {
				name:'b',
				type:'Int',
				opt:false, many:false
			}], args: null })
		}, {
			key: 'something',
			verb: 'post',
			name: 'postSomething',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: true,
				data:[{
					key: 'i',
					opt: false,
					type: TypeName('Int',false)
				}, {
					key: 'str',
					opt: false,
					type: TypeName('String',false)
				}]
			} })
		}] }), r._getDispatchData() );
	}

	public function testExpectedFailures()
	{
		typeError(route( { any: function(a:Int->Void) {} } ));
		typeError(route( { any: function(a:{}) {} } ));
		typeError(route( { any: function(args:Int->Void) {} } ));
		typeError(route( { any: function(args:{ arg1:Int->Void }) {} } ));
		typeError(route( { any: function(a:Dynamic) {} } ));
		typeError(route( { any: function(a:InexistantType) {} } ));
		typeError(route( { any: function(a:{ > Something, x: Int }) {} } ));
	}

	public function testRouteType()
	{
		typeEq( route({ any: function() return "ohai" }), ( null : AnonRoute<String> ) );
		typeEq( route({ any: function() return "ohai", anyTest:function() return "hello" }), ( null : AnonRoute<String> ) );
		typeEq( route({ any: function() return 1 }), ( null : AnonRoute<Int> ) );
		typeEq( route({ any: function() return 1, anyTest: function() return 10 }), ( null : AnonRoute<Int> ) );
		typeError( route({ any: function() return 1, anySomething: function() return "ohai" }) );
		typeEq( route({ any: function() return "ohai", something: new StrRoute()  }), ( null : AnonRoute<String> ) );
		typeError( route({ any: function() return 1, something: new StrRoute() }) );
		typeEq( route({ any: function() return "ohai", something: {}  }), ( null : AnonRoute<String> ) );

		//map
		typeEq( route({ any: function() return 10, something: (new StrRoute()).map(function(str) return Std.parseInt(str)) }), ( null : AnonRoute<Int> ) );
		typeError( route({ any: function() return 10, something: (new StrRoute()).map(function(str) return str) }) );

		typeEq( route({ any: function() return 1, anySomething: function() return "ohai" }, true), ( null : AnonRoute<Dynamic> ) );
		typeEq( ( route( { any: function() return 1, anySomething: function() return "ohai" } ) : Route<Dynamic> ), ( null : Route<Dynamic> ) );
		typeEq( ( route( { any: function() return 1, anySomething: function() return "ohai" } ) : Dynamic ), ( null : Dynamic ) );
	}
}

typedef Something = { i:Int };

abstract SomeAbstract(String)
{
}

private class RouteDefInference extends mweb.Route<Void>
{
	public function postSomething(?args)
	{
		var str = args.str;
		var str2 = str + ' should be inferred as a String';
		var i = args.i;
		var i2 = i += 3;
	}

	public function any(a,c,b)
	{
		a += 10.1;
		b += 10;
		c += 'hello';
	}
}

private class RouteDef1 extends mweb.Route<Void>
{
	public function any()
	{
	}

	public function getOther()
	{
	}
}

private class StrRoute extends mweb.Route<String>
{
	public function any()
		return "any route";

	@:skip public function anyTest()
		return 1;
}
