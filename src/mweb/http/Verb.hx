package mweb.http;

/**
	Represents an HTTP verb
 **/
@:enum abstract Verb(String)
{
	var Get = "get";
	var Post = "post";
	var Put = "put";
	var Delete = "delete";
	var Patch = "patch";
	var Head = "head";

	@:extern inline private function new(str)
		this = str;

	@:extern inline public function toString():String
		return this;

	@:from @:extern inline public static function fromString(str:String):Verb
		return new Verb(str.toLowerCase());
}

