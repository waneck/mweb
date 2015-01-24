package mweb.internal;
import mweb.internal.Data;

@:skip @:final class MappedRoute<From,To> extends mweb.Route<To>
{
	private var proxy:Route<From>;
	private var mapFunction:From->To;

	public function new(proxy,mapFunction)
	{
		super();
		if (mapFunction == null) throw 'Cannot create a MappedRoute with a null mapping function!';
		if (proxy == null) throw 'Cannot map a null route object!';

		this.proxy = proxy;
		this.mapFunction = mapFunction;
	}

	override private function _getMapFunction():Null<Dynamic->To>
	{
		return mapFunction;
	}

	override private function _getDispatchData():DispatchData
	{
		return proxy._getDispatchData();
	}

	override private function _getSubject():{}
	{
		return proxy._getSubject();
	}
}
