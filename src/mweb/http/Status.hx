package mweb.http;

@:enum abstract Status(Int) from Int
{
	var Continue = 100;
	var SwitchingProtocols = 101;
	var OK = 200;
	var Created = 201;
	var Accepted = 202;
	var NonAuthoritativeInformation = 203;
	var NoContent = 204;
	var ResetContent = 205;
	var PartialContent = 206;
	var MultipleChoices = 300;
	var MovedPermanently = 301;
	var Found = 302;
	var SeeOther = 303;
	var NotModified = 304;
	var UseProxy = 305;
	var TemporaryRedirect = 307;
	var BadRequest = 400;
	var Unauthorized = 401;
	var PaymentRequired = 402;
	var Forbidden = 403;
	var NotFound = 404;
	var MethodNotAllowed = 405;
	var NotAcceptable = 406;
	var ProxyAuthenticationRequired = 407;
	var RequestTimeout = 408;
	var Conflict = 409;
	var Gone = 410;
	var LengthRequired = 411;
	var PreconditionFailed = 412;
	var RequestEntityTooLarge = 413;
	var RequestURITooLong = 414;
	var UnsupportedMediaType = 415;
	var RequestedRangeNotSatisfiable = 416;
	var ExpectationFailed = 417;
	var InternalServerError = 500;
	var NotImplemented = 501;
	var BadGateway = 502;
	var ServiceUnavailable = 503;
	var GatewayTimeout = 504;
	var HTTPVersionNotSupported = 505;

	public function getName():String
	{
		return switch(this)
		{
			case 100: "Continue";
			case 101: "Switching Protocols";
			case 200: "OK";
			case 201: "Created";
			case 202: "Accepted";
			case 203: "Non-Authoritative Information";
			case 204: "No Content";
			case 205: "Reset Content";
			case 206: "Partial Content";
			case 300: "Multiple Choices";
			case 301: "Moved Permanently";
			case 302: "Found";
			case 303: "See Other";
			case 304: "Not Modified";
			case 305: "Use Proxy";
			case 307: "Temporary Redirect";
			case 400: "Bad Request";
			case 401: "Unauthorized";
			case 402: "Payment Required";
			case 403: "Forbidden";
			case 404: "Not Found";
			case 405: "Method Not Allowed";
			case 406: "Not Acceptable";
			case 407: "Proxy Authentication Required";
			case 408: "Request Timeout";
			case 409: "Conflict";
			case 410: "Gone";
			case 411: "Length Required";
			case 412: "Precondition Failed";
			case 413: "Request Entity Too Large";
			case 414: "Request-URI Too Long";
			case 415: "Unsupported Media Type";
			case 416: "Requested Range Not Satisfiable";
			case 417: "Expectation Failed";
			case 500: "Internal Server Error";
			case 501: "Not Implemented";
			case 502: "Bad Gateway";
			case 503: "Service Unavailable";
			case 504: "Gateway Timeout";
			case 505: "HTTP Version Not Supported";
			case _: "Custom";
		}
	}

	public function toString()
	{
		return this + " " + getName();
	}
}

