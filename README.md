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
	This is an example route
	It has only one route location:
		/             - shows an instructions page
		/hello/{name} - shows a "Hello, {name} message"
 **/
class HelloRoute extends mweb.Route<String>
{
	public static function main()
	{
		var d = new mweb.Dispatcher(Web);
		var ret = d.dispatch(new HelloRoute());
		Sys.print(ret);
	}

	public function anyHello(name:String):String
	{
		return '<h1>Hello, $name!</h1>';
	}
	
	public function any():String
	{
		return '<p>Welcome to the first example of mweb!</p>' +
			'<p>In order to test it, change your browser location to point to <code>/hello/yourname</code> <a href="/hello/user">like this</a></p>';
	}

	/**
		this function will not be route because it's a
		private function
	 **/
	private function willNotBeRoute():Void
	{
	}

	/**
		this function will not be route because it has the
		@:skip metadata
	 **/
	@:skip public function willNotBeRouteEither():Int
	{
		return 1;
	}
}
```

The first thing to note here is that a `mweb.Route` takes a type parameter. That type parameter represents what
type each of its routes should return. Return-type covariance is taken into account.
About naming, we have some special prefixes that filter the accepted function methods allowed:
`get`,`post`,`delete`,`patch`,`put`. Each of these prefixes represents an HTTP verb.
If you want that the function take any verb, you can use `any`

So by these definitions, we have two routes at HelloRoute:

* `<root>`              : takes any verb: shows an instructions page
* `<root>/hello/{name}` : takes any verb, and expects a String argument in the address

There may be more than one route address argument. If we change the `anyHello` function to match the following:
```haxe
public function anyHello(name:String, ?age:Int):String
{
	return '<h1>Hello, $name!' + (age == null ? '' : ' You are $age years old') + '</h1>';
}
```

The route `<root>/hello/{name}` will still work the same, but a `<root>/hello/{name}/{age}` address route is
possible. The `?` marker on `age` denotes the argument as [optional](http://haxe.org/manual/types-function-optional-arguments.html)

Differently from the first (`name`) argument, the `age` argument is an `Int`. This will go through a type check when dispatching the route -
and any address that isn't an Integer will be rejected by the dispatcher. So for example `<root>/hello/myname/not_an_int` will fail with the
`mweb.Errors.DispatcherErrorType.InvalidArgumentType` error

### Example 2: Using forms

We've seen how to use mweb to use address arguments. However address arguments do not play well with form values, which get sent through
GET/POST parameters. In order to use them, a special argument named `args` can be included as the last argument of a route.
The `args` argument must always be an anonymous type definition:

```haxe
#if neko
import neko.Web;
#else
import php.Web;
#end

/**
	This is an example route
	It has two route locations:
		/      - shows a form for the user to enter his name
		/hello - says hello to the user who posted his name
 **/
class HelloRoute extends mweb.Route<String>
{
	public static function main()
	{
		var d = new mweb.Dispatcher(Web);
		var ret = d.dispatch(new HelloRoute());
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

So by these definitions, we have two routes at HelloRoute:

* `<root>`       : takes any verbs: shows a form asking the user to enter his name
* `<root>/hello` : takes only the POST verb, and there must be on the body of the message a String parameter called `theName`

We can further modify this example so we can have only the `<root>` route:

```haxe
#if neko
import neko.Web;
#else
import php.Web;
#end

/**
	This is an example route
	It has two route locations:
		/      - shows a form for the user to enter his name
		/      - [POST method] says hello to the user who posted his name
 **/
class HelloRoute extends mweb.Route<String>
{
	public static function main()
	{
		var d = new mweb.Dispatcher(Web);
		var ret = d.dispatch(new HelloRoute());
		Sys.print(ret);
	}

	public function any():String
	{
		return 
			'<h1>Please enter your name</h1>' +
			'<form action="/" method="POST">' +
				'<input type="text" name="theName" />' +
				'<input type="submit" />' +
			'</form>';
	}

	public function post(args:{ theName:String }):String
	{
		return '<h1>Hello, ${args.theName}</h1>';
	}
}
```

The `post` function will take priority over `any` when a POST method is used. 

Like with address arguments, `args` can be optional - so if no argument is present, the function will still be called.
Knowing that, we can further modify this example:

```haxe
#if neko
import neko.Web;
#else
import php.Web;
#end

/**
	This is the 2nd sample route.
	It has one route location:
		/      - shows either a form for the user to enter his name or a greeting message
 **/
class HelloRoute extends mweb.Route<String>
{
	public static function main()
	{
		var d = new mweb.Dispatcher(Web);
		var ret = d.dispatch(new HelloRoute());
		Sys.print(ret);
	}

	public function any(?args:{ theName:String }):String
	{
		if (args != null)
			return '<h1>Hello, ${args.theName}</h1>';
		else
			return 
				'<h1>Please enter your name</h1>' +
				'<form action="/" method="POST">' +
					'<input type="text" name="theName" />' +
					'<input type="submit" />' +
				'</form>';
	}
}
```

While the example above is possible - it is recommended to filter only the required method when using `args`

Also note that `args` can also have its type inferred from usage:
```haxe
	public function post(args):String
	{
		return '<h1>Hello, ${args.theName}</h1>';
	}
```

### Example 3: Anonymous and array types on `args` arguments
// explain about the expected type's influence
// explain about metadata

### Example 4: Type craze : map without mweb/tools


### Example 5: Using TemplateLink


### Example 6: Reusing our old code


### Example 7: Accessing other routes


### Example 8: Creating a REST Api
