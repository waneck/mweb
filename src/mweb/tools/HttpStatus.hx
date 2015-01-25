package mweb.tools;

@:enum abstract HttpStatus(Int) from Int
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
	var NoAcceptable = 406;
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
}
