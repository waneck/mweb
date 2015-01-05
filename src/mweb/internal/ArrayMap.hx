package mweb.internal;

private typedef K = String

@:forward(iterator,length) abstract ArrayMap<T : { key:K }>(Array<T>)
{
	inline private function new(arr)
	{
		this = arr;
	}

	@:noUsing @:from public static function fromArray<T : { key:K }>(arr:Array<T>):ArrayMap<T>
	{
		arr.sort(function(v1,v2) return Reflect.compare(v1.key, v2.key));
		return new ArrayMap(arr);
	}

	@:arrayAccess public function get(key:K):T
	{
		var ids = this;
		var min = 0;
		var max = ids.length;

		while (min < max)
		{
			var mid = min + ((max - min) >> 1);
			var imid = ids[mid].key;
			if (key < imid)
			{
				max = mid;
			} else if (key > imid) {
				min = mid + 1;
			} else {
				return ids[mid];
			}
		}
		return null;
	}

	public function firstIndex(key:K):Int
	{
		var ids = this;
		var min = 0;
		var max = ids.length;

		while (min < max)
		{
			var mid = min + ((max - min) >> 1);
			var imid = ids[mid].key;
			if (key < imid)
			{
				max = mid;
			} else if (key > imid) {
				min = mid + 1;
			} else {
				while(mid > 0 && ids[mid-1].key == key)
				{
					mid--;
				}

				return mid;
			}
		}
		return -1;
	}

	@:extern inline public function forEachKey(key:K, fn:T->Void)
	{
		var idx = firstIndex(key),
		    len = this.length;
		for(i in idx...len)
		{
			var val = this[i];
			if (val.key != key)
				break;
			fn(val);
		}
	}

	inline public function index(i:Int)
		return this[i];
}
