package mweb;

typedef HttpRequest = {
	/**
		Should return the method (verb) used by the request - values like GET/POST
	 **/
	function getMethod():String;

	/**
		Should return the URI queried by the HTTP request
	 **/
	function getURI():String;

	/**
		Should return a String containing the GET parameters.
	 **/
	function getParamsString():String;

	/**
		Should return a String containing the body of the HTTP request.

		If the request was a GET request, it must return an empty String, otherwise
		an `InvalidRequest` error will be thrown
	 **/
	function getPostData():String;
}
