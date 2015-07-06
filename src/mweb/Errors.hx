package mweb;

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

/**
	Thrown while dispatching to a route
	@see `DispatcherError`
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
	MultipleParamValues(parameterName:String,values:Array<Dynamic>);

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
	Thrown by the type decoder
 **/
enum DecoderError
{
	/**
		A type was referenced on the code and no decoder was added to handle it.
	 **/
	TypeNotFound(type:String);
	DecoderNotFound(type:String);
}

/**
	Thrown when a new request is processed
 **/
enum RequestError
{
	InvalidRequest(message:String);
	InvalidUri(uri:String,message:String);
	PostSizeTooBig(maxSize:Int, ?curSize:Int);
}

/**
	Errors thrown by the body parser
 **/
enum ParseError
{
	/**
		Thrown by FormEncoded when a key is both referenced as an array and as an object.

		Example (in the POST body):
			a[b] = "somestring"
			a[] = "otherstring"

		In this case `a` is both referenced as an object (`a[b]`) and as an array(`a[]`) -
		which leads to this error
	 **/
	ObjectArrayMismatch(key1:String, key2:String);

	/**
		Thrown when an invalid content-type is set
	 **/
	InvalidMimeType(contentType:String);

	/**
		Custom Body Parser error
	 **/
	CustomParseError(kind:String, msg:String);
}
