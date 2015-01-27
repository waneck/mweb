mweb
====

Mini web: Simple function dispatcher for web applications.

On web applications, we normally have a single entry point which has to handle many different requests
to different URIs, with different GET/POST/etc parameters

mweb - which was inspired by `haxe.web.Dispatch` class - presents a way to deal with this problem in
a declarative and composable manner. It uses the concept of `Routes` to define which function should
be executed for each route.
The routes are created declaratively - either by creating a class that extends `mweb.Route`, or by
using an anonymous object.

## Features

* Web API-agnostic
* Expressive
* Easily create REST APIs
* Adaptable to your workflow
* Share route definitions between many projects
* Easily work 

## Learn by Example

### Example 1: Hello, World!

```haxe
#if neko
import neko.Web;
#else
import php.Web;
#end

/**
	This is the first sample route.
	It has two route locations:
		/      - shows a form for the user to enter his name
		/hello - says hello to the user who posted his name
 **/
class Main extends mweb.Route<String>
{
	public static function main()
	{
		var d = new mweb.Dispatcher(Web);
		var ret = d.dispatch(new Main());
		Sys.print(ret);
	}

	public function any():String
	{
		return 
			'<h1>Please enter your name</h1>' +
			'<form action="/hello" method="POST">' +
				'<input type="text" name="theName" />' +
				'<input type="submit" />' +
			'</form>';
	}

	public function postHello(args:{ theName:String }):String
	{
		return '<h1>Hello, ${args.theName}</h1>';
	}
}
```

The first thing to note here is that a Route takes a type parameter. That type parameter represents what
type each of its routes should return. Return-type covariance is accepted.
About naming, we have some special prefixes that filter the accepted function methods allowed:
`get`,`post`,`delete`,`patch`,`put`. Each of these prefixes represents an HTTP verb.
If you want that the function take any verb, you can use `any`

So by these definitions, we have two routes at Main:

* `<root>`       : takes any verbs: shows a form asking the user to enter his name
* `<root>/hello` : takes only the POST verb, and there must be on the body of the message a String parameter called `theName`
