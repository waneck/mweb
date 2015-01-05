package tests;
import utest.Assert;
import utest.Assert.*;

import mweb.Route.*;
import mweb.internal.Data;

@:access(mweb.Route) class TestDefs
{
	public function new()
	{
	}

	public function testBasicAnon()
	{
		var a1 = route({});
		Assert.same( RouteObj({ routes:cast [] }), a1._getDispatchData() );
		a1 = route({ a: @:skip 'test' });
		Assert.same( RouteObj({ routes:cast [] }), a1._getDispatchData() );
	}
}

