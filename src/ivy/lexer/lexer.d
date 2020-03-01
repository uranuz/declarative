module ivy.lexer.lexer;

import trifle.location: LocationConfig;

import ivy.lexer.lexeme_info: LexemeInfo;
import ivy.lexer.lexeme: Lexeme;
import ivy.lexer.consts;

import std.range: empty, front, popFront, back, popBack;
import std.exception: enforce;
import ivy.lexer.exception: IvyLexerException;

alias enf = enforce!IvyLexerException;

// If IvyTotalDebug is defined then enable parser debug
version(IvyTotalDebug) version = IvyLexerDebug;

struct Lexer(S, LocationConfig c = LocationConfig.init)
{
	import trifle.text_forward_range: TextForwardRange;

	import ivy.lexer.rule: LexicalRule;
	import ivy.loger: LogInfo, LogerProxyImpl, LogInfoType;

	import ivy.lexer.lexeme_info: LexemeInfo;
	import ivy.lexer.lexeme: Lexeme;

	import std.typecons: BitFlags;

	enum LocationConfig config = c;
	alias SourceRange = TextForwardRange!(String, c);
	alias LexRule = LexicalRule!(SourceRange);
	alias LexemeT = Lexeme!(config);
	alias Char = SourceRange.Char;
	alias String = S;
	alias LogerMethod = void delegate(LogInfo);
	alias LexerT = Lexer!(String, config);

	static auto staticRule(Flags...)(String str, LexemeType lexType, Flags extraFlags)
	{
		BitFlags!LexemeFlag newFlags;
		int pairTypeIndex;

		foreach(flag; extraFlags)
		{
			static if( is( typeof(flag) == LexemeFlag ) )
			{
				newFlags |= flag;
			}
			else static if( is( typeof(flag) == LexemeType ) || is( typeof(flag) == int ) )
			{
				enf(pairTypeIndex == 0, "Pair type index is not 0, so seems that it's attempt to set multiple pairs for lexeme");
				pairTypeIndex = flag;
			}
			else
			{
				static assert( false, "Expected lexeme flags or pair lexeme index" );
			}
		}

		newFlags &= ~LexemeFlag.Dynamic;
		enf(
			!( cast(bool)(newFlags & LexemeFlag.Paren) && pairTypeIndex == 0 ),
			"Lexeme with LexemeFlag.Paren expected to have pair lexeme");

		return LexRule( str, &parseStaticLexeme!(SourceRange, LexRule), LexemeInfo( lexType, newFlags, pairTypeIndex ) );
	}

	static auto dynamicRule(Flags...)(LexRule.ParseMethodType method, LexemeType lexType, Flags extraFlags)
	{
		BitFlags!LexemeFlag newFlags;
		int pairTypeIndex;

		foreach(flag; extraFlags)
		{
			static if( is( typeof(flag) == LexemeFlag ) )
			{
				newFlags |= flag;
			}
			else static if( is( typeof(flag) == LexemeType ) || is( typeof(flag) == int ) )
			{
				enf(
					pairTypeIndex == 0,
					"Pair type index is not 0, so seems that it's attempt to set multiple pairs for lexeme");
				pairTypeIndex = flag;
			}
			else
			{
				static assert( false, "Expected lexeme flags or pair lexeme index" );
			}
		}

		newFlags |= LexemeFlag.Dynamic;
		enf(
			!( cast(bool)(newFlags & LexemeFlag.Paren) && pairTypeIndex == 0 ),
			"Lexeme with LexemeFlag.Paren expected to have pair lexeme");

		return LexRule( null, method, LexemeInfo( lexType, newFlags ) );
	}

public:
	__gshared LexRule[] mixedContextRules = [
		staticRule( exprBlockBegin, LexemeType.ExprBlockBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.ExprBlockEnd ),
		staticRule( codeBlockBegin, LexemeType.CodeBlockBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.CodeBlockEnd ),
		staticRule( codeListBegin, LexemeType.CodeListBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.CodeListEnd ),
		staticRule( mixedBlockBegin, LexemeType.MixedBlockBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.MixedBlockEnd ),
		staticRule( mixedBlockEnd, LexemeType.MixedBlockEnd, LexemeFlag.Paren, LexemeFlag.Right, LexemeType.MixedBlockBegin ),
		dynamicRule( &parseData, LexemeType.Data, LexemeFlag.Literal )
	];

	__gshared LexRule[] codeContextRules = [
		dynamicRule( &parseDataBlock, LexemeType.DataBlock, LexemeFlag.Literal ),

		staticRule( exprBlockBegin, LexemeType.ExprBlockBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.ExprBlockEnd ),
		staticRule( codeBlockBegin, LexemeType.CodeBlockBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.CodeBlockEnd ),
		staticRule( codeListBegin, LexemeType.CodeListBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.CodeListEnd ),
		staticRule( mixedBlockBegin, LexemeType.MixedBlockBegin, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.MixedBlockEnd ),
		staticRule( exprBlockEnd, LexemeType.ExprBlockEnd, LexemeFlag.Paren, LexemeFlag.Right, LexemeType.ExprBlockBegin ),

		staticRule( "{", LexemeType.LBrace, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.RBrace ),
		staticRule( "[", LexemeType.LBracket, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.RBracket ),
		staticRule( "(", LexemeType.LParen, LexemeFlag.Paren, LexemeFlag.Left, LexemeType.RParen ),
		staticRule( "}", LexemeType.RBrace, LexemeFlag.Paren, LexemeFlag.Right, LexemeType.LBrace ),
		staticRule( "]", LexemeType.RBracket, LexemeFlag.Paren, LexemeFlag.Right, LexemeType.LBracket ),
		staticRule( ")", LexemeType.RParen, LexemeFlag.Paren, LexemeFlag.Right, LexemeType.LParen ),
		staticRule( "+", LexemeType.Add, LexemeFlag.Operator, LexemeFlag.Arithmetic ),
		staticRule( "==", LexemeType.Equal, LexemeFlag.Operator, LexemeFlag.Compare ),
		staticRule( ":", LexemeType.Colon, LexemeFlag.Operator ),
		staticRule( ",", LexemeType.Comma, LexemeFlag.Operator ),
		staticRule( "/", LexemeType.Div, LexemeFlag.Operator, LexemeFlag.Arithmetic ),
		staticRule( ".", LexemeType.Dot, LexemeFlag.Operator ),
		staticRule( ">=", LexemeType.GTEqual, LexemeFlag.Operator, LexemeFlag.Compare ),
		staticRule( ">", LexemeType.GT, LexemeFlag.Operator, LexemeFlag.Compare ),
		staticRule( "<=", LexemeType.LTEqual, LexemeFlag.Operator, LexemeFlag.Compare ),
		staticRule( "<", LexemeType.LT, LexemeFlag.Operator, LexemeFlag.Compare ),
		staticRule( "%", LexemeType.Mod, LexemeFlag.Operator, LexemeFlag.Arithmetic ),
		staticRule( "**", LexemeType.Pow, LexemeFlag.Operator, LexemeFlag.Compare ),
		staticRule( "*", LexemeType.Mul, LexemeFlag.Operator, LexemeFlag.Arithmetic ),
		staticRule( "!=", LexemeType.NotEqual, LexemeFlag.Operator, LexemeFlag.Compare ),

		staticRule( ";", LexemeType.Semicolon, LexemeFlag.Separator),
		staticRule( "-", LexemeType.Sub, LexemeFlag.Operator, LexemeFlag.Arithmetic ),
		staticRule( "~", LexemeType.Tilde, LexemeFlag.Operator ),

		dynamicRule( &parseFloat, LexemeType.Float, LexemeFlag.Literal ),
		dynamicRule( &parseInteger, LexemeType.Integer, LexemeFlag.Literal ),
		dynamicRule( &parseName, LexemeType.Name ),
		dynamicRule( &parseString, LexemeType.String, LexemeFlag.Literal )
	];

	static struct LexerContext
	{
		ContextState[] statesStack;
		LexemeInfo[] parenStack;

		this(this)
		{
			parenStack = parenStack.dup;
		}

		ref LexerContext opAssign(ref LexerContext rhs)
		{
			statesStack = rhs.statesStack.dup;
			parenStack = rhs.parenStack.dup;
			return this;
		}

		@property ContextState state()
		{
			return statesStack.empty ? ContextState.CodeContext : statesStack.back;
		}

	}

	SourceRange sourceRange; //Source range. Don't modify it!
	SourceRange currentRange;
	LexerContext _ctx;
	LogerMethod logerMethod;

	/+private+/ LexemeT _front;

	@disable this(this);

	version(IvyLexerDebug)
		enum isDebugMode = true;
	else
		enum isDebugMode = false;

	static struct LogerProxy
	{
		mixin LogerProxyImpl!(IvyLexerException, isDebugMode);
		LexerT lexer;

		string sendLogInfo(LogInfoType logInfoType, string msg)
		{
			import ivy.loger: getShortFuncName;

			import std.array: array;
			import std.conv: to;

			if( lexer.logerMethod !is null ) {
				lexer.logerMethod(LogInfo(
					msg,
					logInfoType,
					getShortFuncName(func),
					file,
					line,
					(!lexer.empty? lexer.front.loc.fileName: null),
					(!lexer.empty? lexer.front.loc.lineIndex: 0),
					(!lexer.empty? lexer.frontValue.array.to!string: null)
				));
			}
			return msg;	
		}
	}

	LogerProxy loger(string func = __FUNCTION__, string file = __FILE__, int line = __LINE__)	{
		return LogerProxy(func, file, line, this.save);
	}

	this(String src, LogerMethod logMeth = null)
	{
		auto newRange = SourceRange(src);
		this(newRange, logMeth);
	}

	this(ref const(SourceRange) srcRange, LogerMethod logMeth = null)
	{
		sourceRange = srcRange.save;
		currentRange = sourceRange.save;
		logerMethod = logMeth;

		// In order to make lexer initialized at startup - we parse first lexeme
		if( !this.empty )
			this.popFront();
	}

	this(ref return scope inout(LexerT) src) inout
	{
		this.sourceRange = src.sourceRange.save;
		this.currentRange = src.currentRange.save;
		this.logerMethod = src.logerMethod;
		this._ctx = src._ctx;
		this._front = src._front;
	}

	void parse()
	{
		while( !currentRange.empty )
		{
			popFront();
		}
	}

	static LexemeT parseFront(ref SourceRange source, ref LexerContext ctx)
	{
		import std.conv: to;
		import std.range: empty;

		if( ctx.state == ContextState.CodeContext )
			skipWhiteSpaces(source);

		if( source.empty )
		{
			if( !ctx.parenStack.empty )
				enf(
					false,
					"Expected matching parenthesis for "
					~ (cast(LexemeType) ctx.parenStack.back.typeIndex).to!string
					~ ", but unexpected end of input found!!!");

			return createLexemeAt(source, LexemeType.EndOfFile);
		}

		LexRule[] rules;

		if( ctx.state == ContextState.CodeContext ) {
			rules = codeContextRules;
		} else if( ctx.state == ContextState.MixedContext ) {
			rules = mixedContextRules;
		} else {
			enf(false, "No lexer context detected!");
		}


		LexemeT lex;
		SourceRange currentRange;
		foreach( rule; rules )
		{
			currentRange = source.save;
			if( rule.apply(currentRange) )
			{
				lex = extractLexeme( source, currentRange, rule.lexemeInfo );
				break;
			}
		}

		enf(lex.info.isValidType, "Expected valid token!");

		return lex;
	}

	void popFront()
	{
		import std.array: array;
		import std.conv: to;

		loger.write("Running lexer popFront");

		_front = parseFront(currentRange, _ctx);

		// Checking paren balance
		if( _front.info.isRightParen )
		{
			if( !_ctx.parenStack.empty ) {
				enf(
					_ctx.parenStack.back.pairTypeIndex == _front.typeIndex,
					`Expected pair lexeme "` ~ (cast(LexemeType) _ctx.parenStack.back.pairTypeIndex).to!string
					~ `" for lexeme "` ~ (cast(LexemeType) _ctx.parenStack.back.typeIndex).to!string
					~ `", but got "` ~ (cast(LexemeType) _front.typeIndex).to!string ~ `"!`);
			} else {
				enf(false, `Right paren "` ~ _front.typeIndex.to!string ~ `" found, but paren stack is empty!`);
			}
		}

		// Determining context state
		switch( _front.info.typeIndex ) with( LexemeType )
		{
			case ExprBlockBegin, CodeBlockBegin, CodeListBegin:
			{
				if( _ctx.state == ContextState.CodeContext || _ctx.state == ContextState.MixedContext )
				{
					_ctx.statesStack ~= ContextState.CodeContext;
				}
				break;
			}
			case ExprBlockEnd, CodeBlockEnd /*, CodeListEnd*/:
			{
				if( _ctx.state == ContextState.CodeContext )
				{
					if( !_ctx.parenStack.empty && !_ctx.statesStack.empty )
					{
						// Single brace only "closing" code context if there is block begin on the top of paren stack
						if( _front.info.typeIndex == ExprBlockEnd && _ctx.parenStack.back.typeIndex == ExprBlockBegin
							|| _front.info.typeIndex == CodeBlockEnd && _ctx.parenStack.back.typeIndex == CodeBlockBegin
							|| _front.info.typeIndex == CodeListEnd && _ctx.parenStack.back.typeIndex == CodeListBegin )
								_ctx.statesStack.popBack();
					}
				}
				break;
			}
			case MixedBlockBegin:
			{
				if( _ctx.state == ContextState.CodeContext || _ctx.state == ContextState.MixedContext )
				{
					_ctx.statesStack ~= ContextState.MixedContext;
				}
				break;
			}
			case MixedBlockEnd:
			{
				if( _ctx.state == ContextState.MixedContext )
				{
					if( !_ctx.statesStack.empty )
						_ctx.statesStack.popBack();
				}
				break;
			}
			default:
				break;
		}

		// Put parens in paren stack in order to control balance
		if( _front.info.isRightParen )
		{
			if( !_ctx.parenStack.empty && _ctx.parenStack.back.pairTypeIndex == _front.typeIndex )
			{
				_ctx.parenStack.popBack();
			}
		}
		else if( _front.info.isLeftParen )
		{
			_ctx.parenStack ~= _front.info;
		}
	}

	bool empty() @property {
		return currentRange.empty || _front.info.isEndOfFile;
	}

	LexemeT front() @property
	{
		return _front;
	}

	auto frontValue() @property
	{
		return front.getSlice(sourceRange);
	}

	@property auto save() {
		return LexerT(this);
	}

	void fail_expectation(LexemeType lexType, String value, String msg, string func, string file, int line)
	{
		import std.conv: to;
		import std.array: array;

		String whatExpected = (msg.empty? null: msg ~ `. `) ~ `Lexeme of type "` ~ lexType.to!String ~ `"`;
		if( !value.empty )
			whatExpected ~= ` with value "` ~ value ~ `"`;
		loger(func, file, line).error(!this.empty, whatExpected, ` expected, but got end of input!!!`);

		String whatGot = `, but got lexeme of type "` ~ (cast(LexemeType) front.info.typeIndex).to!String ~ `"`;
		if( !front.getSlice(sourceRange).empty )
			whatGot ~= ` with value "` ~ front.getSlice(sourceRange).array ~ `"`;

		loger(func, file, line).error(whatExpected, ` expected`, whatGot, `!!!`);
	}

	LexemeT expect(LexemeType lexType, String msg = null, string func = __FUNCTION__, string file = __FILE__, int line = __LINE__) {
		return expectVal(lexType, null, msg, func, file, line);
	}

	LexemeT expectVal(LexemeType lexType, String value = null, String msg = null, string func = __FUNCTION__, string file = __FILE__, int line = __LINE__)
	{
		import std.algorithm: equal;

		if( this.empty )
			fail_expectation(lexType, value, msg, func, file, line);

		LexemeT lex = this.front;
		if( lex.info.typeIndex == lexType && (value.empty || lex.getSlice(sourceRange).equal(value)) ) {
			return lex;
		}

		fail_expectation(lexType, value, msg, func, file, line);
		assert(false);
	}

	LexemeT consume(LexemeType lexType, String msg = null, string func = __FUNCTION__, string file = __FILE__, int line = __LINE__) {
		return consumeVal(lexType, null, msg, func, file, line);
	}

	LexemeT consumeVal(LexemeType lexType, String value = null, String msg = null, string func = __FUNCTION__, string file = __FILE__, int line = __LINE__)
	{
		LexemeT lex = expect(lexType, value, func, file, line);
		this.popFront();
		return lex;
	}

	// TODO: Unused method - consider to remove
	bool skipIf(LexemeType lexType)
	{
		if( this.empty )
			return false;

		auto lex = this.front;
		if( lex.info.typeIndex == lexType )
		{
			this.popFront();
			return true;
		}
		return false;
	}

	// TODO: Unused method - consider to remove
	bool skipIf(LexemeType typeIndex, String value)
	{
		import std.algorithm: equal;

		if( this.empty )
			return false;

		auto lex = this.front;
		if( lex.info.typeIndex == typeIndex && lex.getSlice(sourceRange).equal(value) )
		{
			this.popFront();
			return true;
		}
		return false;
	}

	LexemeT next() @property
	{
		//Creates copy of currentRange in order to not modify original one
		SourceRange parsedRange = currentRange.save;
		if( this.empty )
			loger.error("Cannot peek lexeme, because currentRange is empty!!!");

		return parseFront(parsedRange, _ctx);
	}

	static immutable whitespaceChars = " \n\t\r";

	static void skipWhiteSpaces(ref SourceRange source)
	{
		import std.algorithm: canFind;

		Char ch;
		while( !source.empty )
		{
			ch = source.front;
			if( !whitespaceChars.canFind(ch) )
				return;
			source.popFront();
		}
	}

	static immutable String stringQuotes = `"'`;

	static bool parseString(ref SourceRange source, ref const(LexRule) rule)
	{
		import trifle.quoted_string_range: QuotedStringRange;
		import std.algorithm: canFind;

		alias QuotRange = QuotedStringRange!(SourceRange, stringQuotes);
		if( source.empty || !stringQuotes.canFind(source.front) ) {
			return false;
		}

		auto qRange = QuotRange(source);
		while( !qRange.empty ) {
			qRange.popFront();
		}
		source = qRange.source; // Get processed range back

		enf(!source.empty, `Expected quoted string's end quote, but unexpected end`);
		enf(stringQuotes.canFind(source.front), `Expected quoted string's end quote`);
		source.popFront(); // Skip end quote

		return true;
	}

	static bool parseInteger(ref SourceRange source, ref const(LexRule) rule)
	{
		Char ch;

		if( source.empty )
			return false;

		ch = source.front;
		if( !('0' <= ch && ch <= '9') )
			return false;
		source.popFront();

		while( !source.empty )
		{
			ch = source.front;
			if( !('0' <= ch && ch <= '9') )
				break;
			source.popFront();
		}

		return true;
	}

	static bool parseFloat(ref SourceRange source, ref const(LexRule) rule)
	{
		Char ch;

		if( source.empty )
			return false;

		ch = source.front;
		if( !('0' <= ch && ch <= '9') )
			return false;
		source.popFront();

		while( !source.empty )
		{
			ch = source.front;
			if( !('0' <= ch && ch <= '9') )
				break;
			source.popFront();
		}

		if( source.empty )
			return false;

		ch = source.front;
		if( ch != '.' )
			return false;
		source.popFront();

		enf(!source.empty, `Expected decimal part of float!!!`);

		ch = source.front;

		enf('0' <= ch && ch <= '9', `Expected decimal part of float!!!`);
		source.popFront();

		while( !source.empty )
		{
			ch = source.front;
			if( !('0' <= ch && ch <= '9') )
				break;
			source.popFront();
		}

		return true;
	}

	static immutable notTextLexemes = [
		exprBlockBegin,
		codeBlockBegin,
		codeListBegin,
		mixedBlockBegin,
		mixedBlockEnd
	];

	static bool parseData(ref SourceRange source, ref const(LexRule) rule)
	{
		while( !source.empty )
		{
			foreach( ref notText; notTextLexemes )
			{
				if( source.save.match(notText) ) // Test only, but not consume
				{
					return true;
				}
			}
			source.popFront();
		}

		return true;
	}

	static bool parseDataBlock(ref SourceRange source, ref const(LexRule) rule)
	{
		if( source.empty )
			return false;

		if( !source.match(dataBlockBegin) )
			return false;

		while( !source.empty )
		{
			if( source.match(dataBlockEnd) )
				return true;

			source.popFront();
		}

		return true;
	}

	static bool parseName(ref SourceRange source, ref const(LexRule) rule)
	{
		import trifle.parse_utils: decodeFront, frontUnitLength, isStartCodeUnit;

		Char ch;
		dchar dch;
		ubyte len;

		if( source.empty )
			return false;

		ch = source.front;

		if( !isStartCodeUnit(ch) )
			return false;

		dch = source.decodeFront();
		len = source.frontUnitLength();
		if( !isNameChar(dch) || isNumberChar(dch) )
			return false;

		source.popFrontN(len);

		while( !source.empty )
		{
			len = source.frontUnitLength();
			dch = source.decodeFront();

			if( !isNameChar(dch) )
				break;

			source.popFrontN(len);
		}

		return true;
	}
}

bool isNameChar(dchar ch)
{
	import std.uni: isAlpha;

	return isAlpha(ch) || ('0' <= ch && ch <= '9') || ch == '_';
}

bool isNumberChar(dchar ch)
{
	return ('0' <= ch && ch <= '9');
}

// Just creates empty lexeme at specified position and of certain type (Unknown type by default)
template createLexemeAt(SourceRange)
{
	import trifle.text_forward_range: GetSourceRangeConfig;

	alias config = GetSourceRangeConfig!SourceRange;
	alias LexemeT = Lexeme!(config);

	LexemeT createLexemeAt(ref SourceRange source, LexemeType lexType = LexemeType.Unknown)
	{
		LexemeT lex;
		lex.info = LexemeInfo(lexType);
		lex.loc.index = source.index;
		lex.loc.length = 0;

		static if( config.withGraphemeIndex )
		{
			lex.loc.graphemeIndex = source.graphemeIndex;
			lex.loc.graphemeLength = 0;
		}

		static if( config.withLineIndex )
		{
			lex.loc.lineIndex = source.lineIndex;
			lex.loc.lineCount = 0;

			static if( config.withColumnIndex )
				lex.loc.columnIndex = source.columnIndex;

			static if( config.withGraphemeColumnIndex )
				lex.loc.graphemeColumnIndex = source.graphemeColumnIndex;
		}

		return lex;
	}
}

// Universal super-duper extractor of lexemes by it's begin, end ranges and info about type of lexeme
auto extractLexeme(SourceRange)(ref SourceRange beginRange, ref const(SourceRange) endRange, ref const(LexemeInfo) lexemeInfo)
{
	import trifle.text_forward_range: GetSourceRangeConfig;
	import trifle.location: IndentStyle;

	import std.algorithm: canFind, min;

	enum LocationConfig config = GetSourceRangeConfig!SourceRange;

	Lexeme!(config) lex;
	lex.info = lexemeInfo;

	// TODO: Maybe we should just add Location field for Lexeme
	lex.loc.index = beginRange.index;

	enf(
		endRange.index >= beginRange.index,
		"Index for end range must not be less than for begin range!");
	// Not idiomatic range maybe approach, but effective
	lex.loc.length = endRange.index - beginRange.index;

	static if( config.withGraphemeIndex )
	{
		lex.loc.graphemeIndex = beginRange.graphemeIndex;

		enf(
			endRange.graphemeIndex >= beginRange.graphemeIndex,
			"Grapheme index for end range must not be less than for begin range!");
		lex.loc.graphemeLength = endRange.graphemeIndex - beginRange.graphemeIndex;
	}

	static if( config.withLineIndex )
	{
		lex.loc.lineIndex = beginRange.lineIndex;

		enf(
			endRange.lineIndex >= beginRange.lineIndex,
			"Line index for end range must not be less than for begin range!");
		lex.loc.lineCount = endRange.lineIndex - beginRange.lineIndex;

		static if( config.withColumnIndex )
			lex.loc.columnIndex = beginRange.columnIndex;

		static if( config.withGraphemeColumnIndex )
			lex.loc.graphemeColumnIndex = beginRange.graphemeColumnIndex;
	}

	// Getting slice of this lexeme in order to parse indents
	auto parsedRange = beginRange[0..lex.loc.length];

	IndentStyle indentStyle;
	size_t minIndentCount = size_t.max;

	by_line_loop:
	while( !parsedRange.empty )
	{
		size_t lineIndentCount;
		IndentStyle lineIndentStyle;
		parsedRange.parseLineIndent( lineIndentCount, lineIndentStyle );

		bool isEmptyLine = true;
		// Inner loop check if line contains meaningful characters
		while( !parsedRange.empty )
		{
			auto ch = parsedRange.popChar();
			if( !" \t\r\n".canFind(ch) )
			{
				isEmptyLine = false;
			}

			if( ch == ' ' && ch == '\t' )
			{
				continue; //Just skip rest empty spaces
			}
			else if( parsedRange.isNewLine || parsedRange.empty )
			{
				if( !isEmptyLine )
				{
					minIndentCount = min(minIndentCount, lineIndentCount);
					indentStyle = lineIndentStyle;
				}

				continue by_line_loop;
			}
		}
	}
	lex.loc.indentCount = minIndentCount;
	lex.loc.indentStyle = indentStyle;

	beginRange = endRange.save; //Move start currentRange to point of end currentRange
	return lex;
}

// Simple function for parsing static lexemes
bool parseStaticLexeme(SourceRange, LexRule)(ref SourceRange source, ref const(LexRule) rule) {
	return source.match(rule.val);
}