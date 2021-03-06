package mweb.internal;
import mweb.internal.Data;

@:skip @:final class AnonRoute<T> extends mweb.Route<T>
{
	var subject:{};
	var route:DispatchData;

	public function new(subject:{}, route:DispatchData)
	{
		super();
		this.subject = subject;
		this.route = route;
	}

	override private function _getDispatchData():DispatchData
	{
		return route;
	}

	override private function _getSubject():{}
	{
		return subject;
	}
}
