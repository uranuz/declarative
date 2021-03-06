module ivy.types.data.conv.json_parse;


class IvyJSONException: Exception
{
public:
	@nogc @safe this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null) pure nothrow
	{
		super(msg, file, line, next);
	}
}

/// Interface method to parse JSON string into ivy internal data format
auto parseIvyJSON(S)(S src)
{
	auto parser = JSONParser!(S)(src);
	return parser.parseValue();
}

struct JSONParser(S = string)
{
	import trifle.text_forward_range: TextForwardRange;
	import trifle.quoted_string_range: QuotedStringRange;

	import ivy.types.data.data: TIvyData;

	alias String = S;
	alias SourceRange = TextForwardRange!String;
	alias Char = SourceRange.Char;
	alias IvyData = TIvyData!String;

private:
	SourceRange _source;

public:
	this(SourceRange src)
	{
		_source = src.save;
	}

	this(String src)
	{
		_source = SourceRange(src);
	}

	import std.ascii: isDigit, isWhite;

	void error(string msg, string file = __FILE__, size_t line = __LINE__)
	{
		import std.conv: to;
		throw new IvyJSONException(`Parsing error in: ` ~ _source.str ~ `..: ` ~ msg, file, line);
	}

	String parseString()
	{
		import std.array: appender;
		import std.range: put;

		alias QuotRange = QuotedStringRange!(SourceRange, `"`);

		auto qRange = QuotRange(_source);
		auto buf = appender!String();
		for( ; !qRange.empty; qRange.popFront() ) {
			buf ~= qRange.front;
		}
		_source = qRange.source; // Because range can be copied, we need to take processed range

		return buf.data;
	}

	void skipWhitespace()
	{
		while( !_source.empty )
		{
			if( !isWhite(_source.front) )
				break;
			_source.popFront(); // Skip whitespace character
		}
	}

	Char getChar()
	{
		this.skipWhitespace();
		return _source.front;
	}

	void parseInteger()
	{
		if( _source.empty || !isDigit(_source.front) ) error(`Expected digit`);

		while( !_source.empty )
		{
			if( !isDigit(_source.front) )
				break;
			_source.popFront();
		}
	}

	IvyData parseNumber()
	{
		import std.conv: to;
		assert( isDigit( getChar() ) || getChar() == '-', `Expected number` );

		auto beginRange = _source.save;
		if( getChar() == '-' )
			_source.popFront();

		parseInteger();
		bool isFloat = false;
		if( _source.front == '.' )
		{
			_source.popFront(); // Skip point
			parseInteger();
			isFloat = true;
		}

		String strValue= _source.str[ beginRange.index .. _source.index ];
		if( isFloat )
			return IvyData( strValue.to!double );
		else
			return IvyData( strValue.to!int );
	}

	IvyData parseValue()
	{
		while( !_source.empty )
		{
			Char ch = getChar();
			switch( ch )
			{
				case '{':
				{
					_source.popFront(); // Skip {
					IvyData[String] assocArray;
					while( !_source.empty && getChar() != '}' )
					{
						string key = parseString();

						if( !_source.empty && getChar() != ':' )
							error("Expected :");

						_source.popFront(); // Skip :

						IvyData value = parseValue();
						assocArray[key] = value;

						if( getChar() == '}' )
							break;

						if( _source.empty || getChar() != ',' )
							error(`Expected ,`);
						_source.popFront(); // Skip ,
					}

					if( _source.empty || _source.front != '}' )
						error("Expected }");
					_source.popFront(); // Skip }

					return IvyData(assocArray);
				}
				case '[':
				{
					_source.popFront(); // Skip [
					IvyData[] nodeArray;
					while( !_source.empty && getChar() != ']' )
					{
						nodeArray ~= parseValue();
						if( getChar() == ']' )
							break;

						if( getChar() != ',' )
							error( `Expected ,` );
						_source.popFront(); // Skip ,
					}

					if( _source.empty || _source.front != ']' )
						error("Expected ]");
					_source.popFront(); // Skip ]

					return IvyData(nodeArray);
				}
				case '"':
					return IvyData(parseString());
				case '0': .. case '9':
				case '-':
					return parseNumber();
				case 't':
					if( !_source.match("true") )
						error( "Expected true" );
					return IvyData(true);
				case 'f':
					if( !_source.match("false") )
						error( "Expected false" );
					return IvyData(false);
				case 'n':
					if( !_source.match("null") )
						error( "Expected null" );
					return IvyData(null);
				default:
					error( "Unexpected escaped character" );
			}
		}

		return IvyData();
	}
}
