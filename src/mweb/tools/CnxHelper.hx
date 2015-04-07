package mweb.tools;

class CnxHelper
{
	public static function setParameters(http:haxe.Http, args:Dynamic, prefix:String):Void
	{
		for (field in Reflect.fields(args))
		{
			var data = Reflect.field(args, field);
			switch(Type.typeof(data))
			{
				case TNull | TUnknown:
					// do nothing
				case TInt | TFloat | TBool | TEnum(_):
					http.addParameter(prefix + field, Std.string(data));
				case TObject:
					setParameters(http, data, '${prefix}${field}_');
				case TClass(c):
					if (c == Array)
					{
						var arr:Array<Dynamic> = data;
						for (a in arr)
						{
							http.addParameter(prefix + field, Std.string(a));
						}
					} else {
						http.addParameter(prefix + field, Std.string(data));
					}
				case TFunction:
			}
		}
	}
}
