package mweb.internal.macro;

class Delay
{
	macro public static function delayTyping()
	{
		mweb.internal.macro.Build.delayed();
		return macro null;
	}
}
