module ivy.engine.config;

import ivy.compiler.directive.factory: DirectiveCompilerFactory;
import ivy.interpreter.directive.factory: InterpreterDirectiveFactory;
import ivy.log: LogInfo, LogerMethod;

// Structure for configuring Ivy
struct IvyEngineConfig
{
	string[] importPaths; // Paths where to search for templates
	string fileExtension = ".ivy"; // Extension of files that are templates

	// Signature for loging methods, so logs can be forwarded to stdout, file or anywhere else...
	// If you wish debug output you must build with one of these -version specifiers:
	// IvyTotalDebug - maximum debug verbosity
	// IvyCompilerDebug - enable compiler debug output
	// IvyInterpreterDebug - enable interpreter debug output
	// IvyParserDebug - enable parser debug output
	// But errors and warnings will be sent to logs in any case. But you can ignore them...
	LogerMethod interpreterLoger;
	LogerMethod compilerLoger;
	LogerMethod parserLoger;

	DirectiveCompilerFactory compilerFactory; // Factory or storage that produces compilers for certain directives
	InterpreterDirectiveFactory directiveFactory; // Factory or storage that produces interpreters for certain directives
	bool clearCache = false;
}