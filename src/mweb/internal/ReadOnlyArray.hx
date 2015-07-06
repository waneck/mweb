package mweb.internal;

@:forward(iterator,copy,length) abstract ReadOnlyArray<T>(Array<T>) from Array<T>
{
	@:extern inline public function new(arr)
	{
		this = arr;
	}

	@:arrayAccess @:extern inline public function get(index:Int):T
		return this[index];
}
