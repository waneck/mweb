package mweb.http.webstd;
#if neko
import neko.Web;
#elseif php
import php.Web;
#elseif (croxit || croxit_1)
import croxit.Web;
#end

class Writer extends mweb.http.Writer
{
	public function new(?config:mweb.Config)
	{
		super(config);
	}

	override public function setHeader(key:String, value:String):Void
	{
		Web.setHeader(key,value);
	}

	override public function setStatus(status:Status):Void
	{
		Web.setReturnCode(cast status);
	}

	override public function write(str:String):Void
	{
#if (croxit || croxit_1)
		croxit.Output.print(str);
#else
		Sys.print(str);
#end
	}

	override public function redirect(to:String):Void
	{
		Web.redirect(to);
	}
}
