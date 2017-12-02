module ivy.interpreter.data_node_render;

import ivy.interpreter.data_node: DataNodeType;

/// Варианты типов отрисовки узла данных в буфер:
/// Text - для вывода пользователю в виде текста (не включает отображение значений внутренних типов данных)
/// TextDebug - для вывода данных в виде текста в отладочном режиме (выводятся некоторые данные для узлов внутренних типов)
/// JSON - вывод узлов, которые соответствуют типам в JSON в формате собственно JSON (остальные типы узлов выводим как null)
/// JSONFull - выводим всё максимально в JSON, сериализуя узлы внутренних типов в JSON
enum DataRenderType { Text, TextDebug, HTML, JSON, JSONFull };
/// Думаю, нужен ещё флаг isPrettyPrint

private void _writeEscapedString(DataRenderType renderType, OutRange)(auto ref OutRange outRange, string str)
{
	import std.range: put;
	import std.algorithm: canFind;
	enum bool isQuoted = ![DataRenderType.Text, DataRenderType.HTML].canFind(renderType);
	static if( isQuoted ) {
		outRange.put("\"");
	}
	static if( renderType == DataRenderType.Text ) {
		outRange.put(str); // There is no escaping for plain text render
	}
	else
	{
		foreach( char symb; str )
		{
			static if( renderType == DataRenderType.HTML )
			{
				switch( symb )
				{
					case '&': outRange.put("&amp;"); break;
					case '\'': outRange.put("&apos;"); break;
					case '"': outRange.put("&quot;"); break;
					case '<': outRange.put("&lt;"); break;
					case '>': outRange.put("&gt;"); break;
					default:	outRange.put(symb);
				}
			}
			else
			{
				switch( symb )
				{
					case '\"': outRange.put("\\\""); break;
					case '\\': outRange.put("\\\\"); break;
					case '/': outRange.put("\\/"); break;
					case '\b': outRange.put("\\b"); break;
					case '\f': outRange.put("\\f"); break;
					case '\n': outRange.put("\\n"); break;
					case '\r': outRange.put("\\r"); break;
					case '\t': outRange.put("\\t"); break;
					default:	outRange.put(symb);
				}
			}
		}
	}
	static if( isQuoted ) {
		outRange.put("\"");
	}
}

import std.traits: isInstanceOf;
import ivy.interpreter.data_node: DataNode, NodeEscapeState;
private void _writeEscapedString(DataRenderType renderType, OutRange, TDataNode)(auto ref OutRange outRange, TDataNode strNode)
	if( isInstanceOf!(DataNode, TDataNode) )
{
	assert(strNode.type == DataNodeType.String);
	if( strNode.escapeState == NodeEscapeState.Safe && renderType == DataRenderType.HTML ) {
		outRange._writeEscapedString!(DataRenderType.Text)(strNode.str);
	} else {
		outRange._writeEscapedString!(renderType)(strNode.str);
	}
	static if( renderType == DataRenderType.TextDebug ) {
		import std.conv: text;
		outRange.put(` <[` ~ strNode.escapeState.text ~ `]>`);
	}
}

void renderDataNode(DataRenderType renderType, TDataNode, OutRange)(
	auto ref TDataNode node, auto ref OutRange outRange, size_t maxRecursion = size_t.max)
{
	import std.range: put;
	import std.conv: to;
	import std.algorithm: canFind;

	assert( maxRecursion, "Recursion is too deep!" );

	final switch(node.type) with(DataNodeType)
	{
		case Undef:
			static if( [DataRenderType.Text, DataRenderType.HTML].canFind(renderType) ) {
				outRange.put("");
			} else static if( renderType == DataRenderType.TextDebug ) {
				outRange.put("undef");
			} else {
				outRange.put("null");
			}
			break;
		case Null:
			static if( [DataRenderType.Text, DataRenderType.HTML].canFind(renderType) ) {
				outRange.put("");
			} else {
				outRange.put("null");
			}
			break;
		case Boolean:
			outRange.put(node.boolean ? "true" : "false");
			break;
		case Integer:
			outRange.put(node.integer.to!string);
			break;
		case Floating:
			outRange.put(node.floating.to!string);
			break;
		case String:
			outRange._writeEscapedString!renderType(node);
			break;
		case DateTime:
			outRange._writeEscapedString!renderType(node.dateTime.toISOExtString());
			break;
		case Array:
			enum bool asArray = ![DataRenderType.Text, DataRenderType.HTML].canFind(renderType);
			static if( asArray ) outRange.put("[");
			foreach( i, ref el; node.array )
			{
				static if( asArray )	if( i != 0 ) {
					outRange.put(", ");
				}

				renderDataNode!(renderType)(el, outRange, maxRecursion - 1);
			}
			static if( asArray ) outRange.put("]");
			break;
		case AssocArray:
			outRange.put("{");
			size_t i = 0;
			foreach( ref key, ref val; node.assocArray )
			{
				if( i != 0 )
					outRange.put(", ");

				outRange._writeEscapedString!renderType(key);
				outRange.put(": ");

				renderDataNode!(renderType)(val, outRange, maxRecursion - 1);
				++i;
			}
			outRange.put("}");
			break;
		case ClassNode:
			import std.conv: text;
			if( node.classNode )
			{
				TDataNode serialized = node.classNode.__serialize__();
				if( serialized.isUndef ) {
					outRange._writeEscapedString!renderType("<class node>");
				} else {
					renderDataNode!(renderType)(serialized, outRange, maxRecursion - 1);
				}
			} else {
				outRange._writeEscapedString!renderType("<class node (null)>");
			}
			break;
		case CodeObject:
			import std.conv: text;
			outRange._writeEscapedString!renderType(
				node.codeObject?
				"<code object, size: " ~ node.codeObject._instrs.length.text ~ ">":
				"<code object (null)>"
			);
			break;
		case Callable:
			outRange._writeEscapedString!renderType(
				node.callable?
				"<callable object, " ~ node.callable._kind.to!string ~ ", " ~ node.callable._name ~ ">":
				"<callable object (null)>"
			);
			break;
		case ExecutionFrame:
			outRange._writeEscapedString!renderType("<execution frame>");
			break;
		case DataNodeRange:
			outRange._writeEscapedString!renderType("<data node range>");
			break;
	}
}