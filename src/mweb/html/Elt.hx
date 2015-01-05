package mweb.html;

class Elt
{
	public var tag(default,null):String;
	var props:Map<String,String>;
	var children:Array<Elt>;

	public function new(tag,?props,?children)
	{
		if (props == null)
			props = new Map();
		if (children == null)
			children = [];

		this.tag = tag;
		this.props = props;
		this.children = children;
	}

	inline public static function elt(tag,?props,?children):Elt
		return new Elt(tag,props,children);

	public function toString()
	{
		var ret = new StringBuf();
		_toString(ret);
		return ret.toString();
	}

	private function _toString(buf:StringBuf)
	{
		var needsClosing = children.length > 0;
		if (!needsClosing)
		{
			switch(tag)
			{
				case 'area' | 'base' | 'br' | 'col' |
				     'command' | 'embed' | 'hr' | 'img' |
				     'input' | 'keygen' | 'link' | 'meta' | 'param' |
				     'source' | 'track' | 'wbr':
					// void elements
				case _:
					needsClosing = true;
			}
		}

		buf.add('<');
		buf.add(tag);
		for (prop in props.keys())
		{
			buf.add(' $prop="');
			buf.add(props[prop].split('"').join('\\"'));
			buf.add('"');
		}
		if (!needsClosing)
			buf.add(' />');
		else
			buf.add('>');

		for (c in children)
			c._toString(buf);

		if (needsClosing)
			buf.add('</$tag>');
	}
}
