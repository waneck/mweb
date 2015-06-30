package mweb.http.webstd;
import haxe.io.*;

#if neko
import neko.Web;
#elseif php
import php.Web;
#elseif croxit
import croxit.Web;
#end

class Request extends mweb.http.Request
{
	public function new()
	{
	}

	override private function methodImpl():String
	{
		return Web.getMethod();
	}

	override public function uri():String
	{
		return Web.getURI();
	}

	override public function uriParams():String
	{
		return Web.getParamsString();
	}

	override public function body(?maxByteSize:Int):haxe.io.Bytes
	{
		var ret = Web.getPostData();
		if (maxByteSize != null && ret.length > maxByteSize) throw mweb.Errors.RequestError.PostSizeTooBig(maxByteSize, ret.length);
		return haxe.io.Bytes.ofString(ret);
	}

	override public function header(name:String):Null<String>
	{
		return Web.getClientHeader(name);
	}

	override public function headers():Map<String,Array<String>>
	{
		var ret = new Map();
		for (header in Web.getClientHeaders())
		{
			var k = header.header;
			var r = ret[k];
			if (r == null)
				ret[k] = r = [header.value];
			else
				r.push(header.value);
		}
		return ret;
	}

	override public function ip():String
	{
		return Web.getClientIP();
	}

	override public function parseMultipart(onPart:String->String->Void, onData:Bytes->Int->Int->Void, ?onComplete:Void->Void):Void
	{
		Web.parseMultipart(onPart,onData);
		if (onComplete != null) onComplete();
	}
}
