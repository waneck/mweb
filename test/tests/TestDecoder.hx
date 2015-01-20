package tests;
import utest.Assert;
import utest.Assert.*;
import tests.Helper.*;

import mweb.Route;
import mweb.Route.*;
import mweb.Dispatcher;
import mweb.internal.Data;
import mweb.internal.*;

@:access(mweb.Dispatcher) class TestDecoder
{
	public function new()
	{
	}

	public function testAbstracts()
	{
		// make sure they are used
		var r = route({ any: function(a:HasFromString,b:FromStringMeta,c:FromStringField,d:FromStringBoth) {} });

		equals('test',Dispatcher.getDecoderFor('tests.HasFromString')('test'));
		equals(110, Dispatcher.getDecoderFor('tests.FromStringMeta')('11'));
		equals(101, Dispatcher.getDecoderFor('tests.FromStringField')('10'));
		equals(102, Dispatcher.getDecoderFor('tests.FromStringBoth')('10'));
	}
}

abstract HasFromString(String) from String
{
}

abstract FromStringMeta(Int)
{
	@:from public static function fs(s:String):FromStringMeta
	{
		return cast Std.parseInt(s) * 10;
	}
}

abstract FromStringField(Float)
{
	public static function fromString(s:String):FromStringField
	{
		return cast Std.parseInt(s) * 10.1;
	}
}

abstract FromStringBoth(Float)
{
	@:from public static function fs(s:String)
	{
		return cast Std.parseFloat(s);
	}

	public static function fromString(s:String):FromStringField
	{
		return cast Std.parseInt(s) * 10.2;
	}
}

