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
		var r = anon({ any: function(a:HasFromString,b:FromStringMeta,c:FromStringField,d:FromStringBoth) {} });

		equals('test',Dispatcher.getDecoderFor('tests.HasFromString')('test'));
		equals(110, Dispatcher.getDecoderFor('tests.FromStringMeta')('11'));
		equals(101, Dispatcher.getDecoderFor('tests.FromStringField')('10'));
		equals(10.1, Dispatcher.getDecoderFor('tests.FromStringField')('1'));
		equals(102, Dispatcher.getDecoderFor('tests.FromStringBoth')('10'));
		equals(10.2, Dispatcher.getDecoderFor('tests.FromStringBoth')('1'));
	}

	public function testClass()
	{
		var r = anon({ any: function(a:ClsWithFromString, b:ClsWithDecoder) {} });
		Dispatcher.addDecoder(function(str):ClsWithDecoder return new ClsWithDecoder(str+'-dec'));
		same(new ClsWithFromString("testing-from"), Dispatcher.getDecoderFor('tests.ClsWithFromString')('testing'));
		same(new ClsWithDecoder("testing-dec"), Dispatcher.getDecoderFor('tests.ClsWithDecoder')('testing'));
	}

	public function testEnum()
	{
		var r = anon({ any: function(a:SimpleEnum) {} });
		equals(One, Dispatcher.getDecoderFor('tests.SimpleEnum')('one'));
		equals(One, Dispatcher.getDecoderFor('tests.SimpleEnum')('OnE'));
		equals(null, Dispatcher.getDecoderFor('tests.SimpleEnum')('something'));
		Dispatcher.addDecoder(function(str) return str == null ? EOne : ETwo(str));
		equals(EOne, Dispatcher.getDecoderFor('tests.ComplexEnumFromString')(null));
		same(ETwo('two'), Dispatcher.getDecoderFor('tests.ComplexEnumFromString')('two'));
	}
}

enum SimpleEnum
{
	One;
	Two;
	Three;
}

enum ComplexEnumFromString
{
	EOne;
	ETwo(str:String);
}

class ClsWithFromString
{
	public static function fromString(str:String):ClsWithFromString
	{
		return new ClsWithFromString(str + "-from");
	}

	public var name:String;
	public function new(name)
	{
		this.name = name;
	}
}

class ClsWithDecoder
{
	public var name:String;
	public function new(name:String)
	{
		this.name = "prefix-" + name;
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

