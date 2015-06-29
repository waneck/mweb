package mweb.internal.parsers;
using StringTools;

/**
	Parses `application/x-www-form-urlencoded` data.

	Even though this was implemented from scratch, it loosely follows the node.js module `qs` in features and API.
	See more at https://github.com/hapijs/qs
 **/
class FormEncoded extends BodyParser
{
	private static inline var MAGIC_EMPTY_INDEX = 0x7FFFFFFF;

	/**
		The maximum object depth that may be created. Use `null` to disable
	 **/
	public var depth:Null<Int> = 5;

	/**
		Automatically cast numbers into `Float/Int`, and `true/false` into `Bool`
	 **/
	public var castTypes:Bool = true;

	/**
		When disabled, keys that don't contain an `=` sign will be interpreted as an empty string
		instead of `null`
	 **/
	public var strictNullHandling:Bool = true;

	/**
		When disabled, will not handle dots in keys as object definitions
	 **/
	public var allowDots:Bool = true;

	/**
		The limit of parameters that can be parsed. Use `null` to disable
	 **/
	public var parameterLimit:Null<Int> = 1000;

	override public function parseRequest(req:mweb.http.Request, ?maxByteSize:Int):{ }
	{
		return switch(req.method())
		{
			case Get | Head:
				parseForm(req.uriParams());
			case _:
				parseForm( req.body(maxByteSize).toString() );
		}
	}

	public function parseForm(data:String):{ }
	{
		if (data == null || data.length == 0)
			return {};

		var prop = this.allowDots ? ~/\[([^\[\]]*)\]|\.([^\.\[]*)/ : ~/\[([^\[\]]*)\]|(\B\b)/,
		    tmpSort:Array<SortObject> = []; // the object used to sort the output

		var count = 0;
		for ( part in data.split("&") )
		{
			if (parameterLimit != null && count >= parameterLimit)
				break;

			count++;
			var i = part.lastIndexOf("=");
			var k, v = null;
			if (i < 0)
			{
				k = part.urlDecode();
				if (k.length == 0) continue;
				if (!strictNullHandling)
					v = '';
			} else {
				k = part.substr(0, i).urlDecode();
				v = part.substr(i + 1).urlDecode();
			}

			var keys:Array<IntOrString> = [];
			if (depth == 0)
			{
				keys.push(k);
			} else {
				var cdepth = 0;
				// check for [] and .
				var rest = k, first = true;
				while( (depth == null || cdepth++ < depth) && prop.match(rest))
				{
					if (first)
					{
						first = false;
						keys.push(prop.matchedLeft());
					}
					var data = prop.matched(1);
					if (data == null || data.length == 0)
						data = prop.matched(2);
					var iOrS:IntOrString =
						if (data == null || data == '')
						{
							MAGIC_EMPTY_INDEX; //MAX_INT
						} else {
							var asInt = Std.parseInt(data);
							if (asInt != null && Std.string(asInt) == data)
								asInt;
							else
								data;
						};
					keys.push(iOrS);
					rest = prop.matchedRight();
				}
				if (first)
					keys.push(k);
				else if (rest.length > 0)
					keys.push(rest);
			}

			var value:Dynamic = v;
			if (castTypes)
			{
				value = switch(v) {
					case 'true':
						true;
					case 'false':
						false;
					case _:
						var f = Std.parseFloat(v);
						if (Math.isNaN(f))
							value;
						else if (Std.is(f, Int))
							Std.int(f);
						else
							f;
				};
			}

			tmpSort.push({ keys:keys, value:value, index:count });
		}

		// sort them so we can use the same object for the same path
		tmpSort.sort(function(v1,v2) return IntOrString.compare(v1,v2));

		// check for cases where a[] and a are used interchangeably and add [] when this happens
		// and then sort again if needed
		var needsSort = false;
		var i = tmpSort.length;
		while (i --> 1)
		{
			var prev = tmpSort[i-1],
			    cur = tmpSort[i];
			if (prev.keys.length == cur.keys.length - 1 && Std.is(cur.keys[cur.keys.length-1], Int))
			{
				var isSame = true;
				for (j in 0...prev.keys.length)
				{
					if (prev.keys[j] != cur.keys[j])
					{
						isSame = false;
						break;
					}
				}
				if (isSame)
				{
					prev.keys.push(MAGIC_EMPTY_INDEX);
					needsSort = true;
				}
			}
		}
		if (needsSort)
			tmpSort.sort(function(v1,v2) return IntOrString.compare(v1,v2));

		var obj = {};

		// merge them all into an object:
		var lastTmpSortVal:Array<IntOrString> = null; //holds the last iterated object, so we can maybe reuse it
		var objStack:Array<Dynamic> = [obj];
		for (val in tmpSort)
		{
			var cur:Dynamic = obj;
			var keys = val.keys;
			// get lowest denominator between last sort value and current
			var i = 0;
			if (lastTmpSortVal != null)
			{
				while(true)
				{
					var v = lastTmpSortVal[i];
					// EMPTY_INDEX means it's a new array, so stop right there
					if (v == MAGIC_EMPTY_INDEX)
						break;
					if (v == null || v != keys[i])
						break;
					i++;
				}
				if (i > 0)
					cur = objStack[i];
				if (cur == null) //special case when all fields are equal - this means this needs to be an array
				{
					if (
						(i == keys.length || (i == keys.length - 1 && Std.is(keys[keys.length-1],Int))) &&
						(i == lastTmpSortVal.length || (i == lastTmpSortVal.length - 1 && Std.is(lastTmpSortVal[lastTmpSortVal.length-1], Int)))
					) {
						cur = objStack[i-1];
						var field = keys[i-1];
						if (Std.is(field,String) && Reflect.hasField(cur,field))
						{
							var last = [Reflect.field(cur,field)];
							Reflect.setField(cur,field,last);
							cur = last;
						}
						if (i == keys.length)
							keys.push(MAGIC_EMPTY_INDEX);
					} else {
						throw mweb.Errors.ParseError.ObjectArrayMismatch(
							'[' + keys.join('][') + ']',
							'[' + lastTmpSortVal.join('][') + ']');
					}

				}
			}
			while(objStack.length > (i + 1)) objStack.pop();

			var len = val.keys.length;
			var field = keys[i];
			for (i in (i+1)...len)
			{
				var next = keys[i];

				var o:Dynamic =
					if (Std.is(next,String))
						{};
					else
						[];
				if (Std.is(field, String))
				{
					Reflect.setField(cur,field,o);
				} else {
					cur.push(o);
				}

				field = next;
				cur = o;
				objStack.push(cur);
			}

			// last part: actually set the value
			if (Std.is(field, String))
			{
				Reflect.setField(cur,field,val.value);
			} else {
				cur.push(val.value);
			}

			lastTmpSortVal = val.keys;
		}

		return obj;
	}
}

private abstract IntOrString(Dynamic) from Int from String to Int to String
{
	public static function compare(v1:SortObject, v2:SortObject)
	{
		var keys = v1.keys, keys2 = v2.keys;
		var i = -1, len = keys.length < keys2.length ? keys.length : keys2.length;
		while (++i < len)
		{
			var val = keys[i], val2 = keys2[i];
			var isInt1 = Std.is(val, Int), isInt2 = Std.is(val2, Int);
			if (isInt1 != isInt2)
				throw mweb.Errors.ParseError.ObjectArrayMismatch(
					'[' + keys.join('][') + ']',
					'[' + keys2.join('][') + ']');

			if (isInt1)
			{
				var i1:Int = val, i2:Int = val2;
				if (i1 != i2)
					return i1 < i2 ? -1 : 1;
			} else {
				var str1:String = val, str2:String = val2;
				if (str1 != str2)
					return str1 < str2 ? -1 : 1;
			}
		}

		if (keys.length > len)
			return 1;
		else if (keys2.length > len)
			return -1;
		else
			return v1.index - v2.index;
	}
}

private typedef SortObject = { keys:Array<IntOrString>, value:Dynamic, index:Int };
