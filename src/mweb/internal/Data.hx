package mweb.internal;

typedef RouteObjData =
{
	routes: Map<String, RoutesDef>,
}

typedef RoutesDef =
{
	metas: Array<String>,
	addrArgs: Array<{ name:String, type:TypeName }>,
	args: Null<{ opt:Bool, data:Map<String,CType> }>,
}

enum CType
{
	TypeName(name:TypeName);
	AnonType(names:Map<String,CType>);
}

typedef TypeName = String;

enum DispatchData
{
	RouteObj(data:RouteObjData);
	RouteVar(def:RoutesDef);
}
