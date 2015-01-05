package mweb.internal;
import mweb.internal.Data;

class AnonDef extends Def
{
	var subject:{};
	var route:DispatchData;

	public function new(subject:{}, route:DispatchData)
	{
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
