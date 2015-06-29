package tests;
import utest.Assert;
import utest.Assert.*;
import mweb.internal.parsers.FormEncoded;

// some tests were adapted from https://github.com/hapijs/qs/blob/master/test/parse.js
class TestFormParse
{
	public function new()
	{
	}

	public function testOrder()
	{
		var parser = new FormEncoded();

		same( parser.parseForm('a[]=1&a[0]=2&a[100]=3&a[2]=4'),{ a: [2,4,3,1] } );
	}

	public function testBasic()
	{
		var parser = new FormEncoded();
		parser.depth = null;

		same( parser.parseForm('a=1'), { a: 1 } );
		same( parser.parseForm('a=1&a=2'), { a: [1,2] } );
		same( parser.parseForm('a[b]=1&a[b]=2'), { a: { b: [1,2] } } );
		same( parser.parseForm('a[b][]=1&a[b][]=2'), { a: { b: [1,2] } } );
		same( parser.parseForm('a[b]=1&a[b][]=2'), { a: { b: [1,2] } } );
		same( parser.parseForm('a[b][]=1&a[b]=2'), { a: { b: [1,2] } } );
		same( parser.parseForm('a[]=1&a[]=2'), { a: [1,2] } );
		same( parser.parseForm('a=1&a[]=2'), { a: [1,2] } );
		same( parser.parseForm('a[]=1&a=2'), { a: [1,2] } );

		same( parser.parseForm('a.someVal=b'), { a: { someVal: "b" } });

		same( parser.parseForm('a[b][0][a][x]=v1&a[b][0][b]=v2'), { a: { b: [{ a: { x: "v1" }, b: "v2" }] } });
		same( parser.parseForm('a[b][0][b]=v2&a[b][0][a][x]=v1'), { a: { b: [{ a: { x: "v1" }, b: "v2" }] } });

		same( parser.parseForm('a[b][][a][x]=v1&a[b][][b]=v2'), untyped { a: { b: [{ a: { x: "v1" } }, { b: "v2" }] } });
		same( parser.parseForm('a[b][][b]=v2&a[b][][a][x]=v1'), untyped { a: { b: [{ a: { x: "v1" } }, { b: "v2" }] } });
	}

	public function testSimpleString()
	{
		var parser = new FormEncoded();
		parser.castTypes = false;

		parser.strictNullHandling = false;
		same( parser.parseForm('foo' ), { foo: '' } );
		same( parser.parseForm('foo=bar&baz'), { foo: 'bar', baz: '' } );

		parser.strictNullHandling = true;
		same( parser.parseForm('0=foo'), { '0': 'foo' } );
		same( parser.parseForm('a[>=]=23'), { a: { '>=': '23' } } );
		same( parser.parseForm('a[==]=23'), { a: { '==': '23' } } );
		same( parser.parseForm('foo'), { foo: null } );
		same( parser.parseForm('foo='), { foo: '' } );
		same( parser.parseForm('foo=bar'), { foo: 'bar' } );
		same( parser.parseForm('foo=bar&bar=baz'), { foo: 'bar', bar: 'baz' } );
		same( parser.parseForm('foo2=bar2&baz2='), { foo2: 'bar2', baz2: '' } );
		same( parser.parseForm('foo=bar&baz'), { foo: 'bar', baz: null } );
		same( parser.parseForm('cht=p3&chd=t:60,40&chs=250x100&chl=Hello|World'), {
			cht: 'p3',
			chd: 't:60,40',
			chs: '250x100',
			chl: 'Hello|World'
		} );
	}

	public function testQsTests()
	{
		var parser = new FormEncoded();
		parser.castTypes = false;
		// it('allows disabling dot notation', function (done) {
			same( parser.parseForm('a.b=c'), { a: { b: 'c' } } );
			parser.allowDots = false;
			same( parser.parseForm('a.b=c'), { 'a.b': 'c' } );
			parser.allowDots = true;
		// });
		// it('parses a single nested string', function (done) {
			same( parser.parseForm('a[b]=c'), { a: { b: 'c' } } );
		// });
		// it('parses a double nested string', function (done) {
			same( parser.parseForm('a[b][c]=d'), { a: { b: { c: 'd' } } } );
		// });
		// it('defaults to a depth of 5', function (done) {
			same( parser.parseForm('a[b][c][d][e][f][g][h]=i'), { a: { b: { c: { d: { e: { f: { '[g][h]': 'i' } } } } } } } );
		// });
		// it('only parses one level when depth = 1', function (done) {
			parser.depth = 1;
			same( parser.parseForm('a[b][c]=d'), { a: { b: { '[c]': 'd' } } } );
			same( parser.parseForm('a[b][c][d]=e'), { a: { b: { '[c][d]': 'e' } } } );
			parser.depth = 5;
		// });
		// it('parses a simple array', function (done) {
			same( parser.parseForm('a=b&a=c'), { a: ['b', 'c'] } );
		// });
		// it('parses an explicit array', function (done) {
			same( parser.parseForm('a[]=b'), { a: ['b'] } );
			same( parser.parseForm('a[]=b&a[]=c'), { a: ['b', 'c'] } );
			same( parser.parseForm('a[]=b&a[]=c&a[]=d'), { a: ['b', 'c', 'd'] } );
		// });
		// it('parses a mix of simple and explicit arrays', function (done) {
			same( parser.parseForm('a=b&a[]=c'), { a: ['b', 'c'] } );
			same( parser.parseForm('a[]=b&a=c'), { a: ['b', 'c'] } );
			same( parser.parseForm('a[0]=b&a=c'), { a: ['b', 'c'] } );
			// the below test was changed so that parameters without indices have always less priority
			same( parser.parseForm('a=b&a[0]=c'), { a: ['c', 'b'] } );
			same( parser.parseForm('a[1]=b&a=c'), { a: ['b', 'c'] } );
			// the below test was changed so that parameters without indices have always less priority
			same( parser.parseForm('a=b&a[1]=c'), { a: ['c', 'b'] } );
		// });
		// it('parses a nested array', function (done) {
			same( parser.parseForm('a[b][]=c&a[b][]=d'), { a: { b: ['c', 'd'] } } );
			same( parser.parseForm('a[>=]=25'), { a: { '>=': '25' } } );
		// });
		// it('allows to specify array indices', function (done) {
			same( parser.parseForm('a[1]=c&a[0]=b&a[2]=d'), { a: ['b', 'c', 'd'] } );
			same( parser.parseForm('a[1]=c&a[0]=b'), { a: ['b', 'c'] } );
			same( parser.parseForm('a[1]=c'), { a: ['c'] } );
		// });
		// it('limits specific array indices to 20', function (done) {
			same( parser.parseForm('a[20]=a'), { a: ['a'] } );
			// we won't do that also since there is no performance penalty in big array indices
			// same( parser.parseForm('a[21]=a'), { a: { '21': 'a' } } );
		// });
		// it('supports keys that begin with a number', function (done) {
			same( parser.parseForm('a[12b]=c'), { a: { '12b': 'c' } } );
		// });
		// it('supports encoded = signs', function (done) {
			same( parser.parseForm('he%3Dllo=th%3Dere'), { 'he=llo': 'th=ere' } );
		// });
		// it('is ok with url encoded strings', function (done) {
			same( parser.parseForm('a[b%20c]=d'), { a: { 'b c': 'd' } } );
			same( parser.parseForm('a[b]=c%20d'), { a: { b: 'c d' } } );
		// });
		// it('allows brackets in the value', function (done) {
			same( parser.parseForm('pets=["tobi"]'), { pets: '["tobi"]' } );
			// this test makes little sense, since all input should be already escaped
			// same( parser.parseForm('operators=[">=", "<="]'), { operators: '[">=", "<="]' } );
		// });
		// it('allows empty values', function (done) {
			same( parser.parseForm(''), {} );
		// });
		// it('transforms arrays to objects', function (done) {
		// actually on mweb, all of these will throw, as it looks like an error from a developer persepective,
		// and from a strict library perspective
			raises( function() parser.parseForm('foo[0]=bar&foo[bad]=baz'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo[bad]=baz&foo[0]=bar'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo[bad]=baz&foo[]=bar'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo[]=bar&foo[bad]=baz'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo[bad]=baz&foo[]=bar&foo[]=foo'), mweb.Errors.ParseError );
			same( parser.parseForm('foo[0][a]=a&foo[0][b]=b&foo[1][a]=aa&foo[1][b]=bb'), {foo: [ {a: 'a', b: 'b'}, {a: 'aa', b: 'bb'} ]} );
			raises( function() parser.parseForm('a[]=b&a[t]=u&a[hasOwnProperty]=c'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('a[]=b&a[hasOwnProperty]=c&a[x]=y'), mweb.Errors.ParseError );
		// });
		// it('transforms arrays to objects (dot notation)', function (done) {
			same( parser.parseForm('foo[0].baz=bar&fool.bad=baz'), { foo: [ { baz: 'bar'} ], fool: { bad: 'baz' } } );
			same( parser.parseForm('foo[0].baz=bar&fool.bad.boo=baz'), { foo: [ { baz: 'bar'} ], fool: { bad: { boo: 'baz' } } } );
			same( parser.parseForm('foo[0][0].baz=bar&fool.bad=baz'), { foo: [[ { baz: 'bar'} ]], fool: { bad: 'baz' } } );
			same( parser.parseForm('foo[0].baz[0]=15&foo[0].bar=2'), { foo: [{ baz: ['15'], bar: '2' }] } );
			same( parser.parseForm('foo[0].baz[0]=15&foo[0].baz[1]=16&foo[0].bar=2'), { foo: [{ baz: ['15', '16'], bar: '2' }] } );
			raises( function() parser.parseForm('foo.bad=baz&foo[0]=bar'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo.bad=baz&foo[]=bar'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo[]=bar&foo.bad=baz'), mweb.Errors.ParseError );
			raises( function() parser.parseForm('foo.bad=baz&foo[]=bar&foo[]=foo'), mweb.Errors.ParseError );
			same( parser.parseForm('foo[0].a=a&foo[0].b=b&foo[1].a=aa&foo[1].b=bb'), {foo: [ {a: 'a', b: 'b'}, {a: 'aa', b: 'bb'} ]} );
		// });
		// it('can add keys to objects', function (done) {
			raises( function() parser.parseForm('a[b]=c&a=d'), mweb.Errors.ParseError );
		// });
		// it('correctly prunes undefined values when converting an array to an object', function (done) {
			// this was the original:
			// same( parser.parseForm('a[2]=b&a[99999999]=c'), { a: { '2': 'b', '99999999': 'c' } } );
			// however all that maximum array index doesn't make much sense if we're only using the indices for sorting
			// so this restriction is lifted:
			same( parser.parseForm('a[2]=b&a[99999999]=c'), { a: ['b','c'] } );
		// });
		// it('supports malformed uri characters', function (done) {
			// parser.strictNullHandling = true;
			// same( parser.parseForm('{%:%}'), { '{%:%}': null } );
			// parser.strictNullHandling = false;
			// same( parser.parseForm('{%:%}='), { '{%:%}': '' } );
			// same( parser.parseForm('foo=%:%}'), { foo: '%:%}' } );
		// });
		// it('doesn\'t produce empty keys', function (done) {
			same( parser.parseForm('_r=1&'), { '_r': '1' } );
		// });
		// it('cannot access Object prototype', function (done) {
			// FIXME
			// Qs.parse('constructor[prototype][bad]=bad');
			// Qs.parse('bad[constructor][prototype][bad]=bad');
			// expect(typeof Object.prototype.bad).to.equal('undefined');
		// });
		// it('parses arrays of objects', function (done) {
			same( parser.parseForm('a[][b]=c'), { a: [{ b: 'c' }] } );
			same( parser.parseForm('a[0][b]=c'), { a: [{ b: 'c' }] } );
		// });
		// it('allows for empty strings in arrays', function (done) {
			same( parser.parseForm('a[]=b&a[]=&a[]=c'), { a: ['b', '', 'c'] } );
			parser.strictNullHandling = true;
			same( parser.parseForm('a[0]=b&a[1]&a[2]=c&a[19]='), { a: ['b', null, 'c', ''] } );
			same( parser.parseForm('a[0]=b&a[1]=&a[2]=c&a[19]'), { a: ['b', '', 'c', null] } );
			parser.strictNullHandling = false;
			same( parser.parseForm('a[]=&a[]=b&a[]=c'), { a: ['', 'b', 'c'] } );
		// });
		// it('compacts sparse arrays', function (done) {
			same( parser.parseForm('a[10]=1&a[2]=2'), { a: ['2', '1'] } );
		// });
		// it('parses semi-parsed strings', function (done) {
			// we won't support that
			// same( parser.parseForm({ 'a[b]': 'c' }), { a: { b: 'c' } } );
			// same( parser.parseForm({ 'a[b]': 'c', 'a[d]': 'e' }), { a: { b: 'c', d: 'e' } } );
		// });
		// it('continues parsing when no parent is found', function (done) {
			// TODO?
			// same( parser.parseForm('[]=&a=b'), { '0': '', a: 'b' } );
			// parser.strictNullHandling = true;
			// same( parser.parseForm('[]&a=b'), { '0': null, a: 'b' } );
			// parser.strictNullHandling = false;
			// same( parser.parseForm('[foo]=bar'), { foo: 'bar' } );
		// });
		// it('does not error when parsing a very long array', function (done) {
			// TODO re-enable after debugging
			// var str = 'a[]=a';
			// while (str.length < 128 * 1024) {
			// 	str += '&' + str;
			// }
			// parser.parseForm(str); // shouldn't throw
		// });
		// it('should not throw when a native prototype has an enumerable property', { parallel: false }, function (done) {
			same( parser.parseForm('a=b'), { a: 'b' } );
			same( parser.parseForm('a[][b]=c'), { a: [{ b: 'c' }] } );
		// });
		// it('parses a string with an alternative string delimiter', function (done) {
			// parsing semicolons is a slippery slope; see http://stackoverflow.com/questions/3481664/semicolon-as-url-query-separator
			// same( parser.parseForm('a=b;c=d', { delimiter: ';' }), { a: 'b', c: 'd' } );
		// });
		// it('parses a string with an alternative RegExp delimiter', function (done) {
			// see above
			// same( parser.parseForm('a=b; c=d', { delimiter: /[;,] */ }), { a: 'b', c: 'd' } );
		// });
		// it('does not use non-splittable objects as delimiters', function (done) {
			// see above
			// same( parser.parseForm('a=b&c=d', { delimiter: true }), { a: 'b', c: 'd' } );
		// });
		// it('allows overriding parameter limit', function (done) {
			parser.parameterLimit = 1;
			same( parser.parseForm('a=b&c=d'), { a: 'b' } );
		// });
		// it('allows setting the parameter limit to Infinity', function (done) {
			parser.parameterLimit = null;
			same( parser.parseForm('a=b&c=d'), { a: 'b', c: 'd' } );
		// });
		// it('allows overriding array limit', function (done) {
			// no reason why mimick that behaviour
			// expect(Qs.parse('a[0]=b', { arrayLimit: -1 })).to.deep.equal({ a: { '0': 'b' } }, { prototype: false });
			// expect(Qs.parse('a[-1]=b', { arrayLimit: -1 })).to.deep.equal({ a: { '-1': 'b' } }, { prototype: false });
			// expect(Qs.parse('a[0]=b&a[1]=c', { arrayLimit: 0 })).to.deep.equal({ a: { '0': 'b', '1': 'c' } }, { prototype: false });
		// });
		// it('allows disabling array parsing', function (done) {
			// TODO
			// expect(Qs.parse('a[0]=b&a[1]=c', { parseArrays: false })).to.deep.equal({ a: { '0': 'b', '1': 'c' } }, { prototype: false });
		// });
	}

	private static function raises(fn:Void->Void, type:Dynamic, ?pos:haxe.PosInfos)
	{
		var didThrow = false;
		try
		{
			fn();
		}
		catch(e:Dynamic)
		{
			if (!Std.is(e,type))
				Assert.fail('Type of exception $e mismatch: Expected $type', pos);
			didThrow = true;
		}
		Assert.isTrue(didThrow,pos);
	}
}
