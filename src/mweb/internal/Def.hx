package mweb.internal;
import mweb.internal.Data;

@:allow(mweb.Dispatcher) class Def
{
	private function _getDispatchData():DispatchData
	{
		return throw 'Not Implemented';
	}

	private function _getSubject():{}
	{
		return this;
	}
}
