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
		Assert.same( RouteObj({ routes:[] }), r._getDispatchData() );

		// skip
		r = route({ a: @:skip 'test' });
		Assert.same( RouteObj({ routes:[] }), r._getDispatchData() );

		r = route({ any: function() {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		r = route({ any: @someMeta function() {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:['someMeta'], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		// r = route({ something: @:verb(get) function() {} });
		// Assert.same( RouteObj({ routes: [{
		// 	key: 'something',
		// 	verb: 'get',
		// 	name: 'something',
		// 	data: RouteFunc({ metas:[], addrArgs:[], args: null })
		// }] }), r._getDispatchData() );

		r = route({ anyTest: function() {} });
		Assert.same( RouteObj({ routes: [{
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:[], args: null })
		}] }), r._getDispatchData() );

		r = route({ anyTest: function() {}, getOther: function() {} });
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

		r = route({ anyTest: function() {}, getOther: function() {}, something: {} });
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
		r = route({ anyTest: function() {}, something: {}, getOther: function() {} });
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

		r = route({ anyTest: function() {}, getOther: function() {}, something: new RouteDef1() });
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
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', many:false }], args: null })
		}] }), r._getDispatchData() );

		//inferred
		r = route({ any: function(i1) { i1 += 10; } });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', many:false }], args: null })
		}] }), r._getDispatchData() );

		r = route({ any: function(i1:Int, a1:String) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'any',
			name: 'any',
			data: RouteFunc({ metas:[], addrArgs:[{ name:'i1', type:'Int', many:false }, { name:'a1', type:'String', many:false }], args: null })
		}] }), r._getDispatchData() );
		r = route({ any: function(i1:Int, a1:SomeAbstract, z1:String) {} });
		Assert.same( RouteObj({ routes: [{
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
		Assert.same( RouteObj({ routes: [{
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
					type: TypeName('String')
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int')
				}]
			} })
		}] }), r._getDispatchData() );

		r = route({ post: function(?args:{ a1:String }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: true,
				data:[{
					key: 'a1',
					opt: false,
					type: TypeName('String')
				}]
			} })
		}] }), r._getDispatchData() );
		r = route({ post: function(args:{ v1:Int, ?a1:String }) {} });
		Assert.same( RouteObj({ routes: [{
			key: '',
			verb: 'post',
			name: 'post',
			data: RouteFunc({ metas:[], addrArgs:[], args: {
				opt: false,
				data:[{
					key: 'a1',
					opt: true,
					type: TypeName('String')
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int')
				}]
			} })
		}] }), r._getDispatchData() );

		r = route({ post: function(args:{ v1:Int, ?a1:{ otherField: Float, a1:Int } }) {} });
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
						type: TypeName('Int')
					}, {
						key: 'otherField',
						opt: false,
						type: TypeName('Float')
					}])
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int')
				}]
			} })
		}] }), r._getDispatchData() );

		r = route({ post: function(args:{ v1:Int, a1:{ ?otherField: Float, a1:Int } }) {} });
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
						type: TypeName('Int')
					}, {
						key: 'otherField',
						opt: true,
						type: TypeName('Float')
					}])
				}, {
					key: 'v1',
					opt: false,
					type: TypeName('Int')
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
				many:false
			}, {
				name:'c',
				type:'String',
				many:false
			}, {
				name:'b',
				type:'Int',
				many:false
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
					type: TypeName('Int')
				}, {
					key: 'str',
					opt: false,
					type: TypeName('String')
				}]
			} })
		}] }), r._getDispatchData() );
	}
}

abstract SomeAbstract(String)
{
}

private class RouteDefInference extends mweb.Route
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

private class RouteDef1 extends mweb.Route
{
	public function any()
	{
	}

	public function getOther()
	{
	}
}
