package mweb.tools;

abstract Template<T>(TemplateData<T>) from TemplateData<T>
{
	@:extern inline public function new(d)
	{
		this = d;
	}

#if erazor
	@:from inline public static function fromErazor<T>(t:erazor.Template):Template<T>
		return t.execute;

	@:from public static function fromErazorSimpleMacro<T>(t:erazor.macro.SimpleTemplate<T>):Template<T>
		return function(data:T) { t.setData(data); return t.execute(); };
#end

	@:extern inline public function execute(val:T):String
	{
		return this(val);
	}
}

typedef TemplateData<T> = T->String;
