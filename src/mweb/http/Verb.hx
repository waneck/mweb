package mweb.http;

/**
	Represents an HTTP verb
 **/
@:enum abstract Verb(String)
{
	var Get = "GET";
	var Post = "POST";
	var Put = "PUT";
	var Delete = "DELETE";
	var Patch = "PATCH";
	var Head = "HEAD";

	@:extern inline private function new(str)
		this = str;

	@:extern inline public function toString():String
		return this;

	@:from @:extern inline public static function fromString(str:String):Verb
		return new Verb(str.toUpperCase());
}

