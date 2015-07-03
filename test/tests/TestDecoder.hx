package tests;
import utest.Assert;
import utest.Assert.*;
import tests.Helper.*;

import mweb.Route;
import mweb.Route.*;
import mweb.Decoder;
import mweb.internal.Data;
import mweb.internal.*;

class TestDecoder
{
	public function new()
	{
	}

	public function testAbstracts()
	{
		// make sure they are used
		var r = anon({ any: function(a:HasFromString,b:FromStringMeta,c:FromStringField,d:FromStringBoth) {} });

		equals('test',Decoder.current.decode('tests.TestDecoder.HasFromString','test'));
		equals(110, Decoder.current.decode('tests.TestDecoder.FromStringMeta','11'));
		equals(101, Decoder.current.decode('tests.TestDecoder.FromStringField','10'));
		equals(10.1, Decoder.current.decode('tests.TestDecoder.FromStringField','1'));
		equals(102, Decoder.current.decode('tests.TestDecoder.FromStringBoth','10'));
		equals(10.2, Decoder.current.decode('tests.TestDecoder.FromStringBoth','1'));

		var route = new RouteThatUsesAbstract();
		var dispatch = new mweb.Dispatcher(Get, '/10');
		equals('103', dispatch.dispatch(route));
	}

	public function testClass()
	{
		var r = anon({ any: function(a:ClsWithFromString, b:ClsWithDecoder) {} });
		Decoder.add(function(str):ClsWithDecoder return new ClsWithDecoder(str+'-dec'));
		same(new ClsWithFromString("testing-from"), Decoder.current.decode('tests.ClsWithFromString', 'testing'));
		same(new ClsWithDecoder("testing-dec"), Decoder.current.decode('tests.ClsWithDecoder','testing'));
	}

	public function testEnum()
	{
		var r = anon({ any: function(a:SimpleEnum) {} });
		equals(One, Decoder.current.decode('tests.SimpleEnum','one'));
		equals(One, Decoder.current.decode('tests.SimpleEnum','OnE'));
		equals(null, Decoder.current.decode('tests.SimpleEnum','something'));
		Decoder.add(function(str) return str == null ? EOne : ETwo(str));
		equals(EOne, Decoder.current.decode('tests.ComplexEnumFromString',null));
		same(ETwo('two'), Decoder.current.decode('tests.ComplexEnumFromString','two'));
	}
}

private class RouteThatUsesAbstract extends mweb.Route<String>
{
	public function any(a:FromStringBothUsedByClass):String
	{
		return Std.string(a);
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

	public static function fromString(s:String):FromStringBoth
	{
		return cast Std.parseInt(s) * 10.2;
	}
}

abstract FromStringBothUsedByClass(Float)
{
	@:from public static function fs(s:String)
	{
		return cast Std.parseFloat(s);
	}

	public static function fromString(s:String):FromStringBothUsedByClass
	{
		return cast Std.parseInt(s) * 10.3;
	}
}
