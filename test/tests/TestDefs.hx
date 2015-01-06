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
			data: RouteFunc({ metas:[], addrArgs:cast [], args: null })
		}] }), r._getDispatchData() );

		r = route({ something: @:verb(get) function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'something',
			verb: 'get',
			name: 'something',
			data: RouteFunc({ metas:[], addrArgs:cast [], args: null })
		}] }), r._getDispatchData() );

		r = route({ anyTest: function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:cast [], args: null })
		}] }), r._getDispatchData() );

		r = route({ anyTest: function() {}, getOther: function() {} });
		Assert.same( RouteObj({ routes: cast [{
			key: 'other',
			verb: 'get',
			name: 'getOther',
			data: RouteFunc({ metas:[], addrArgs:cast [], args: null })
		}, {
			key: 'test',
			verb: 'any',
			name: 'anyTest',
			data: RouteFunc({ metas:[], addrArgs:cast [], args: null })
		}] }), r._getDispatchData() );

		typeError( route({ getSomething: @:verb(delete) function() {} }) );
	}
}

