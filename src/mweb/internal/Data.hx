package mweb.internal;

typedef RouteObjData =
{
	routes: ArrayMap<{ key:String, verb:String, name:String, data:DispatchData }>,
}

typedef RoutesDef =
{
	metas: Array<String>,
	addrArgs: ArrayMap<{ key:String, type:TypeName }>,
	args: Null<{ opt:Bool, data:ArrayMap<{ key:String, type:CType }> }>,
}

enum CType
{
	TypeName(name:TypeName);
	AnonType(names:ArrayMap<{ key:String, type: CType }>);
}

typedef TypeName = String;

enum DispatchData
{
	RouteObj(data:RouteObjData);
	RouteFunc(def:RoutesDef);
	RouteCall;
}
