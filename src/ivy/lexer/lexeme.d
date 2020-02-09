module ivy.lexer.lexeme;

import ivy.lexer.lexeme_info: LexemeInfo;
import trifle.location: LocationConfig, CustomizedLocation;

///Minumal info about found lexeme
struct Lexeme(LocationConfig c)
{
	enum config = c;
	alias CustLocation = CustomizedLocation!(config);

	CustLocation loc; // Location of this lexeme in source text
	LexemeInfo info; // Field containing information about this lexeme

	bool test(int testType) const
	{
		return this.info.typeIndex == testType;
	}

	bool test(int[] testTypes) const
	{
		import std.algorithm: canFind;
		return testTypes.canFind( this.info.typeIndex );
	}

	int typeIndex() const @property
	{
		return info.typeIndex;
	}

	auto getSlice(SourceRange)(ref SourceRange sourceRange) const
	{
		return sourceRange[loc.index .. loc.index + loc.length];
	}
}