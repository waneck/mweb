package mweb.internal;

typedef RouteObjData =
{
	routes: ArrayMap<{ key:String, verb:String, name:String, data:DispatchData }>,
}

typedef RoutesDef =
{
	metas: Array<String>,
	addrArgs: Array<{ name:String, type:TypeName, many:Bool, opt:Bool }>,
	args: Null<{ opt:Bool, data:ArrayMap<{ key:String, opt:Bool, type:CType }> }>,
}

enum CType
{
	TypeName(name:TypeName, many:Bool);
	AnonType(names:ArrayMap<{ key:String, opt:Bool, type:CType }>);
}

typedef TypeName = String;

enum DispatchData
{
	RouteObj(data:RouteObjData);
	RouteFunc(def:RoutesDef);
	RouteCall;
}
