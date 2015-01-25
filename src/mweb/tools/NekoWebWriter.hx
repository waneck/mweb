package mweb.tools;
#if neko
import neko.Web;
#elseif php
import php.Web;
#elseif (croxit_1)
import croxit.Web;
#end
import mweb.tools.HttpWriter;

#if (neko || php || croxit_1)
class NekoWebWriter implements IHttpWriter
{
	public function new()
	{
	}

	public function setHeader(key:String, value:String):Void
	{
		Web.setHeader(key,value);
	}

	public function setStatus(status:HttpStatus):Void
	{
		Web.setReturnCode(cast status);
	}

	public function write(str:String):Void
	{
#if croxit_1
		croxit.Output.print(str);
#else
		Sys.print(str);
#end
	}

	public function redirect(to:String):Void
	{
		Web.redirect(to);
	}
}
#end
