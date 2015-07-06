package mweb;
import mweb.internal.BodyParser;
import mweb.internal.ReadOnlyArray;
using StringTools;

/**
	Allows one to customize
 **/
class Config
{
	/**
		On any case that an optional config is passed, if it's null,
		this `defaultConfig` object will be used instead
	 **/
	public static var defaultConfig(default,set):Config = new Config();

	private static function set_defaultConfig(v:Config):Config
	{
		if (v == null) throw 'Cannot set a null default config';
		return defaultConfig = v;
	}

	public function new()
	{
		this.bodyParsers = this.bodyParsers;
	}

	/**
		Represents the maximum body size in bytes that can be uploaded on
		a non-multipart request. If it is null, no limit will be set (unsafe)

		@default 100kb
	 **/
	public var maxBodyByteSize(default,set):Null<Int> = 100 * 1024;

	/**
		Represents all Body Parsers that are being used at the moment.
		This can be used to retrieve and change any property inside each body parser

		@default Array with `FormBody` and `JsonBody`
	 **/
	public var bodyParsers(default,set):ReadOnlyArray<BodyParser> = [new mweb.internal.parsers.FormBody(), new mweb.internal.parsers.JsonBody()];

	private function set_maxBodyByteSize(v:Int):Int
		return this.maxBodyByteSize = v;

	private var mimeToBody:Map<String,BodyParser>;

	private function set_bodyParsers(v:ReadOnlyArray<BodyParser>):ReadOnlyArray<BodyParser>
	{
		if (v == null) throw 'Cannot set a null Body Parser array';
		this.mimeToBody = [ for (p in v) p.mimeType().toLowerCase() => p ];
		return this.bodyParsers = v;
	}

	public function parserFromMime(mime:String):Null<BodyParser>
	{
		if (mime == null) //GET parameter
			mime = 'application/x-www-form-urlencoded';

		var idx = mime.indexOf(';');
		if (idx >= 0)
			mime = mime.substr(0,idx).trim();
		mime = mime.toLowerCase();

		return mimeToBody[mime];
	}
}
