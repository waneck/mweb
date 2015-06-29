package mweb;

/**
	Thrown while dispatching to a route
 **/
enum DispatcherErrorType
{
	/**
		Thrown when the URI provided doesn't satisfy all non-optional address arguments
	 **/
	MissingAddrArguments(argName:String);

	/**
		Thrown when the argument with `contents` cannot be decoded to `type`
	 **/
	InvalidArgumentType(contents:String, type:String);

	/**
		Thrown when there's more than one parameter with name `parameterName`,
		and the `args` interface isn't typed as an Array
	 **/
	MultipleParamValues(parameterName:String,values:Array<String>);

	/**
		Thrown when the parameters with names `parameterNames` is missing
	 **/
	MissingArgument(parameterNames:Array<String>);

	/**
		Thrown when there are extra URI parameters than consumed by the Dispatcher
	 **/
	TooManyValues(extra:Array<String>);

	/**
		Thrown when a route is not found
	 **/
	NoRouteFound(uriPart:String);

	/**
		Errors not related to the user arguments
	 **/
	Internal(err:InternalError);
}

/**
	Internal mweb errors that really shouldn't happen. If any of these are seen,
	either there was some tinkering with the `Route`'s internal structure, or they
	should be reported as a bug
 **/
enum InternalError
{
	/**
		Thrown when a route object was expected, and either null or not a real route type was sent
	 **/
	InvalidRoute(value:Dynamic);

	/**
		Thrown when a function object was expected, and either null or not a real function type was sent
	 **/
	InvalidFunction(value:Dynamic);
}

/**
	Errors thrown by the dispather will always be of this type. They include extra information
	about where exactly the error happened
 **/
class DispatcherError
{
	public var uriPart(default,null):String;
	public var fields(default,null):Array<String>;
	public var error(default,null):DispatcherErrorType;

	public function new(uriPart,fields,error)
	{
		this.uriPart = uriPart;
		this.fields = fields;
		this.error = error;
	}

	public function withError(e:DispatcherErrorType)
	{
		return new DispatcherError(uriPart,fields,e);
	}

	public function toString()
	{
		return 'Dispatcher error $error while processing $uriPart (${fields.join('->')})';
	}
}

enum DecoderError
{
	TypeNotFound(type:String);
	DecoderNotFound(type:String);
}

enum RequestError
{
	InvalidRequest(message:String);
	InvalidUri(uri:String,message:String);
	PostSizeTooBig(maxSize:Int);
}

/**
	Errors thrown by the body parser
 **/
enum ParseError
{
	/**
		Thrown by FormEncoded when
	 **/
	ObjectArrayMismatch(key1:String, key2:String);

	CustomParseError(msg:String);
}
