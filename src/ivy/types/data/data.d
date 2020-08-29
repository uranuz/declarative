module ivy.types.data.data;

public alias IvyData = TIvyData!string;

struct TIvyData(S)
{
	import ivy.types.data.consts: IvyDataType, NodeEscapeState;

	import ivy.types.code_object: CodeObject;
	import ivy.types.callable_object: CallableObject;
	import ivy.types.data.async_result: AsyncResult;
	import ivy.types.data.iface.class_node: IClassNode;
	import ivy.types.data.iface.range: IvyDataRange;
	import ivy.types.data.exception: DataNodeException;

	import ivy.interpreter.execution_frame: ExecutionFrame;

	import std.exception: enforce;
	import std.conv: text;

	alias String = S;
	alias MIvyData = TIvyData!(S);

	struct Storage {
		union {
			bool boolean;
			ptrdiff_t integer;
			double floating;
			// This is workaround of problem that IvyData is value type
			// and array with it's length copied, and length is not shared between instances.
			// So we put array item into another GC array with 1 item, so it becomes fully reference type
			// TODO: think how to implement it better
			String[] str;
			MIvyData[][] array;
			MIvyData[String] assocArray;
			IClassNode classNode;
			CodeObject codeObject;
			CallableObject callable;
			ExecutionFrame execFrame;
			IvyDataRange dataRange;
			AsyncResult asyncResult;
		}
	}

	this(T)(auto ref T value) {
		assign(value);
	}

	private Storage storage;
	private IvyDataType typeTag;
	private NodeEscapeState _escapeState;

	bool boolean() @property
	{
		enforce!DataNodeException(type == IvyDataType.Boolean, "IvyData is not boolean");
		return storage.boolean;
	}

	void boolean(bool val) @property {
		assign(val);
	}

	ptrdiff_t integer() @property
	{
		enforce!DataNodeException(type == IvyDataType.Integer, "IvyData is not integer");
		return storage.integer;
	}

	void integer(ptrdiff_t val) @property {
		assign(val);
	}

	double floating() @property
	{
		enforce!DataNodeException(type == IvyDataType.Floating, "IvyData is not floating");
		return storage.floating;
	}

	void floating(double val) @property {
		assign(val);
	}

	ref String str() @property
	{
		enforce!DataNodeException(type == IvyDataType.String, "IvyData is not string");
		enforce!DataNodeException(storage.str.length == 1, "Expected internal storage length of 1");
		return storage.str[0];
	}

	void str(String val) @property {
		assign(val);
	}

	ref MIvyData[] array() @property
	{
		enforce!DataNodeException(type == IvyDataType.Array, "IvyData is not array");
		enforce!DataNodeException(storage.array.length == 1, "Expected internal storage length of 1");
		return storage.array[0];
	}

	void array(MIvyData[] val) @property {
		assign(val);
	}

	ref MIvyData[String] assocArray() @property
	{
		enforce!DataNodeException(type == IvyDataType.AssocArray, "IvyData is not dict");
		return storage.assocArray;
	}

	void assocArray(MIvyData[String] val) @property {
		assign(val);
	}

	IClassNode classNode() @property
	{
		enforce!DataNodeException(type == IvyDataType.ClassNode, "IvyData is not class node");
		enforce!DataNodeException(storage.classNode !is null, "Detected null class node");
		return storage.classNode;
	}

	void classNode(IClassNode val) @property {
		assign(val);
	}

	CodeObject codeObject() @property
	{
		enforce!DataNodeException(type == IvyDataType.CodeObject, "IvyData is not code object");
		enforce!DataNodeException(storage.codeObject !is null, "Detected null code object");
		return storage.codeObject;
	}

	void codeObject(CodeObject val) @property {
		assign(val);
	}

	CallableObject callable() @property
	{
		enforce!DataNodeException( type == IvyDataType.Callable, "IvyData is not callable object");
		enforce!DataNodeException(storage.callable !is null, "Detected null callable object");
		return storage.callable;
	}

	void callable(CallableObject val) @property {
		assign(val);
	}

	ExecutionFrame execFrame() @property
	{
		enforce!DataNodeException( type == IvyDataType.ExecutionFrame, "IvyData is not a execution frame");
		enforce!DataNodeException(storage.execFrame !is null, "Detected null execution frame");
		return storage.execFrame;
	}

	void execFrame(ExecutionFrame val) @property {
		assign(val);
	}

	IvyDataRange dataRange() @property
	{
		enforce!DataNodeException( type == IvyDataType.DataNodeRange, "IvyData is not a data node range");
		enforce!DataNodeException(storage.dataRange !is null, "Detected null data node range");
		return storage.dataRange;
	}

	void dataRange(IvyDataRange val) @property {
		assign(val);
	}

	AsyncResult asyncResult() @property
	{
		enforce!DataNodeException( type == IvyDataType.AsyncResult, "IvyData is not an async result");
		enforce!DataNodeException(storage.asyncResult !is null, "Detected null async result");
		return storage.asyncResult;
	}

	void asyncResult(AsyncResult val) @property {
		assign(val);
	}

	IvyDataType type() @property {
		return typeTag;
	}

	bool isUndef() @property {
		return type == IvyDataType.Undef;
	}

	bool isNull() @property {
		return type == IvyDataType.Null;
	}

	bool empty() @property
	{
		import std.conv: text;
		final switch(this.type)
		{
			case IvyDataType.Undef:
			case IvyDataType.Null:
				return true;
			case IvyDataType.Integer:
			case IvyDataType.Floating:
			case IvyDataType.Boolean:
				// Considering numbers just non-empty there. Not try to interpret 0 or 0.0 as logical false,
				// because in many cases they could be treated as significant values
				// Boolean is not empty too, because we cannot say what value should be treated as empty
				return false;
			case IvyDataType.String:
				return !this.str.length;
			case IvyDataType.Array:
				return !this.array.length;
			case IvyDataType.AssocArray:
				return !this.assocArray.length;
			case IvyDataType.ClassNode:
				return !this.classNode.length;
			case IvyDataType.DataNodeRange:
				return this.dataRange.empty;
			case IvyDataType.CodeObject:
				return !this.codeObject.getInstrCount();
			case IvyDataType.Callable:
			case IvyDataType.ExecutionFrame:
			case IvyDataType.AsyncResult:
			case IvyDataType.ModuleObject:
				return false;
		}
	}

	bool toBoolean() {
		return this.type == IvyDataType.Boolean? this.boolean: !this.empty;
	}

	size_t length() @property
	{
		import std.conv: text;
		final switch(this.type)
		{
			case IvyDataType.Undef:
			case IvyDataType.Null:
				return 0; // Return 0, but not error for convenience
			case IvyDataType.Integer:
			case IvyDataType.Floating:
			case IvyDataType.Boolean:
				break; // Error. Has no length
			case IvyDataType.String:
				return this.str.length;
			case IvyDataType.Array:
				return this.array.length;
			case IvyDataType.AssocArray:
				return this.assocArray.length;
			case IvyDataType.ClassNode:
				return this.classNode.length;
			case IvyDataType.CodeObject:
				return this.codeObject.getInstrCount();
			case IvyDataType.Callable:
			case IvyDataType.ExecutionFrame:
			case IvyDataType.DataNodeRange:
			case IvyDataType.AsyncResult:
			case IvyDataType.ModuleObject:
				break; // Error. Has no length
		}
		throw new DataNodeException(`No "length" property for type: ` ~ this.type.text);
	}

	private void assign(T)(auto ref T arg)
	{
		import trifle.traits: isUnsafelyNullable;

		import std.traits: isIntegral, isFloatingPoint, isArray;

		static if( isUnsafelyNullable!T )
		{
			// Replace all unsafe null values with null type
			if( arg is null )
			{
				typeTag = IvyDataType.Null;
				return;
			}
		}

		static if( is(T : typeof(null)) )
		{
			typeTag = IvyDataType.Null;
		}
		else static if( is(T : bool) )
		{
			typeTag = IvyDataType.Boolean;
			storage.boolean = arg;
		}
		else static if( isIntegral!T )
		{
			typeTag = IvyDataType.Integer;
			storage.integer = arg;
		}
		else static if( isFloatingPoint!T )
		{
			typeTag = IvyDataType.Floating;
			storage.floating = arg;
		}
		else static if( is(T : string) )
		{
			typeTag = IvyDataType.String;
			storage.str = [arg];
		}
		else static if( isArray!T )
		{
			typeTag = IvyDataType.Array;
			static if( is(ElementEncodingType!T : MIvyData) ) {
				storage.array = [arg];
			}
			else
			{
				MIvyData[] new_arg;
				new_arg.length = arg.length;
				foreach(i, e; arg) {
					new_arg[i] = MIvyData(e);
				}
				storage.array = [new_arg];
			}
		}
		else static if( is(T : Value[Key], Key, Value) )
		{
			static assert(is(Key : String), "AA key must be string");

			if( storage.assocArray is null )
			{
				// Special workaround to make AA allocated somewhere in memory even if it is empty
				storage.assocArray = ["__allocateWorkaround__": MIvyData()];
				storage.assocArray.remove("__allocateWorkaround__");
			}

			if( arg is null ) {
				storage.assocArray.clear(); // Just clear, not set it to null
			}

			typeTag = IvyDataType.AssocArray;
			static if( is(Value : MIvyData) )
			{
				if( storage.assocArray !is null && arg !is null ) {
					storage.assocArray = cast(typeof(storage.assocArray)) arg; // Assign only if it is not null
				}
			}
			else
			{
				storage.assocArray.clear(); // Need to remove old data
				foreach(key, value; arg)
					storage.assocArray[key] = MIvyData(value);
				storage.assocArray.rehash(); // For faster lookups
			}
		}
		else static if( is( T : IClassNode ) )
		{
			typeTag = IvyDataType.ClassNode;
			storage.classNode = arg;
		}
		else static if( is( T : CodeObject ) )
		{
			typeTag = IvyDataType.CodeObject;
			storage.codeObject = arg;
		}
		else static if( is( T : CallableObject ) )
		{
			typeTag = IvyDataType.Callable;
			storage.callable = arg;
		}
		else static if( is( T : ExecutionFrame ) )
		{
			typeTag = IvyDataType.ExecutionFrame;
			storage.execFrame = arg;
		}
		else static if( is( T : IvyDataRange ) )
		{
			typeTag = IvyDataType.DataNodeRange;
			storage.dataRange = arg;
		}
		else static if( is( T : AsyncResult ) )
		{
			typeTag = IvyDataType.AsyncResult;
			storage.asyncResult = arg;
		}
		else static if(is(T : MIvyData))
		{
			typeTag = arg.type;
			_escapeState = arg.escapeState;
			final switch(typeTag)
			{
				case IvyDataType.Undef:
				case IvyDataType.Null:
					break;
				case IvyDataType.Boolean: storage.boolean = arg.boolean; break;
				case IvyDataType.Integer: storage.integer = arg.integer; break;
				case IvyDataType.Floating: storage.floating = arg.floating; break;
				case IvyDataType.String: storage.str = arg.storage.str; break;
				case IvyDataType.Array: storage.array = arg.storage.array; break;
				case IvyDataType.AssocArray: storage.assocArray = arg.assocArray; break;
				case IvyDataType.ClassNode: storage.classNode = arg.classNode; break;
				case IvyDataType.CodeObject: storage.codeObject = arg.codeObject; break;
				case IvyDataType.Callable: storage.callable = arg.callable; break;
				case IvyDataType.ExecutionFrame: storage.execFrame = arg.execFrame; break;
				case IvyDataType.DataNodeRange: storage.dataRange = arg.dataRange; break;
				case IvyDataType.AsyncResult: storage.asyncResult = arg.asyncResult; break;
				case IvyDataType.ModuleObject: break; // It is fake...
			}
		}
		else
			static assert(false, `unable to convert type "` ~ T.stringof ~ `" to parse node`);
	}

	void opAssign(T)(auto ref T value)
	{
		assign(value);
	}

	void opIndexAssign(T)(auto ref T value, size_t index)
	{
		enforce!DataNodeException(type == IvyDataType.Array, "IvyData is not an array");
		enforce!DataNodeException(storage.array.length == 1, "Expected internal storage length of 1");
		enforce!DataNodeException(index < storage.array[0].length , "IvyData array index is out of range");

		storage.array[0][index] = value;
	}

	MIvyData opIndex(size_t index)
	{
		import std.algorithm: canFind;
		enforce!DataNodeException(
			[IvyDataType.Array, IvyDataType.ClassNode].canFind(type),
			"IvyData is not an array or class node, but is: " ~ type.text);
		if( type == IvyDataType.ClassNode ) {
			return storage.classNode[MIvyData(index)];
		}
		enforce!DataNodeException(storage.array.length == 1, "Expected internal storage length of 1");
		enforce!DataNodeException(index < storage.array[0].length, "IvyData array index is out of range");

		return storage.array[0][index];
	}

	void opOpAssign(string op : "~", T)(auto ref T arg)
	{
		import std.algorithm: canFind;
		import std.conv: text, to;
		enforce!DataNodeException(
			[IvyDataType.Array, IvyDataType.String].canFind(type),
			"Cannot append to IvyData that is not array or string, got: " ~ this.type.text);

		if( type != IvyDataType.Array )
			this = (MIvyData[]).init;
		enforce!DataNodeException(storage.array.length == 1, "Expected internal storage length of 1");

		static if( isArray!T )
		{
			static if( is( ElementType!T == MIvyData ) )
			{
				storage.array[0] ~= arg.storage.array[0];
			}
			else
			{
				foreach( ref elem; arg )
					storage.array[0] ~= MIvyData(elem);
			}
		} else static if( is(T == MIvyData) ) {
			storage.array[0] ~= arg;
		} else {
			storage.array[0] ~= MIvyData(arg);
		}
	}

	void opIndexAssign(T)(auto ref T value, String key)
	{
		import std.algorithm: canFind;
		enforce!DataNodeException(
			[IvyDataType.AssocArray, IvyDataType.Null, IvyDataType.Undef].canFind(type),
			"IvyData is not a dict, null or undef");

		if( type != IvyDataType.AssocArray )
			this = (MIvyData[String]).init;

		storage.assocArray[key] = value;
	}

	MIvyData opIndex(String key)
	{
		import std.algorithm: canFind;
		enforce!DataNodeException(
			[IvyDataType.AssocArray, IvyDataType.ClassNode].canFind(type),
			"IvyData is not a dict or class node, but is: " ~ type.text);
		if( type == IvyDataType.ClassNode ) {
			return storage.classNode[MIvyData(key)];
		}
		
		enforce!DataNodeException(key in storage.assocArray, "IvyData dict has no such key");

		return storage.assocArray[key];
	}

	auto opBinaryRight(string op: "in")(String key)
	{
		import std.algorithm: canFind;
		enforce!DataNodeException(
			[IvyDataType.AssocArray, IvyDataType.Null, IvyDataType.Undef].canFind(type),
			"IvyData is not a dict, null or undef");

		if( type == IvyDataType.Undef || type == IvyDataType.Null )
			return null;

		return key in storage.assocArray;
	}

	static MIvyData makeUndef() {
		MIvyData undef;
		undef.typeTag = IvyDataType.Undef;
		return undef;
	}

	bool opEquals(MIvyData rhs)
	{
		import std.range: zip;
		if( rhs.type != this.type ) {
			return false;
		}
		switch( this.type )
		{
			case IvyDataType.Undef:
			case IvyDataType.Null:
				return true; // Undef and Null values are equal to each other
			case IvyDataType.Boolean: return this.boolean == rhs.boolean;
			case IvyDataType.Integer: return this.integer == rhs.integer;
			case IvyDataType.Floating: return this.floating == rhs.floating;
			case IvyDataType.String: return this.str == rhs.str;
			case IvyDataType.Array:
			{
				if( this.array.length != rhs.array.length ) {
					return false;
				}
				foreach( pair; zip(this.array, rhs.array) ) {
					// Use nested opEquals
					if( pair[0] != pair[1] ) {
						return false;
					}
				}
				return true; // All equal - fantastic!
			}
			case IvyDataType.AssocArray:
			{
				if( this.assocArray.length != rhs.assocArray.length ) {
					return false;
				}
				foreach( key, val; this.assocArray )
				{
					if( auto valPtr = key in rhs.assocArray )
					{
						// Compare values
						if( *valPtr != val ) {
							return false;
						}
					} else {
						return false; // There is no suck key so they are not equal
					}
				}
				return true; // All keys exist and values are equal - fantastic!
			}
			case IvyDataType.CodeObject: return this.codeObject == rhs.codeObject;
			default: throw new Exception(`Cannot compare data nodes of type: ` ~ this.type.text);
		}
	}

	void escapeState(NodeEscapeState state) @property
	{
		_escapeState = state;
		switch( this.type )
		{
			case IvyDataType.Array: {
				foreach( ref it; this.array ) {
					it.escapeState = state;
				}
				break;
			}
			case IvyDataType.AssocArray: {
				foreach( it, ref val; this.assocArray ) {
					val.escapeState = state;
				}
				break;
			}
			default: break;
		}
	}

	NodeEscapeState escapeState() @property {
		return _escapeState;
	}

	string toString() {
		return toSomeString!(DataRenderType.Text);
	}

	string toDebugString() {
		return toSomeString!(DataRenderType.TextDebug);
	}

	string toHTMLDebugString() {
		return toSomeString!(DataRenderType.HTMLDebug);
	}

	string toJSONString() {
		return toSomeString!(DataRenderType.JSON);
	}

	import ivy.types.data.render: DataRenderType;
	string toSomeString(DataRenderType kind)()
	{
		import ivy.types.data.render: renderDataNode;
		import std.array: appender;

		auto result = appender!string();
		renderDataNode!kind(result, this);
		return result.data;
	}
}


IvyData deeperCopy(IvyData)(auto ref IvyData node)
{
	final switch( node.type )
	{
		case IvyDataType.Undef:
		case IvyDataType.Null:
		case IvyDataType.Boolean:
		case IvyDataType.Integer:
		case IvyDataType.Floating:
			// These types of nodes are value types, so make plain copy

		case IvyDataType.String:
			// String is not a value type, but they are immutable in D implementation,
			// so we only get new slice of existing string

		case IvyDataType.CodeObject:
		case IvyDataType.Callable:
			// We don't do deeper copy of code object or callable, because it should be used as constant
			return node;
		case IvyDataType.Array:
		{
			IvyData[] newArray;
			newArray.length = node.array.length; // Preallocating
			foreach( i, ref el; node.array ) {
				newArray[i] = deeperCopy(el);
			}
			return IvyData(newArray);
		}
		case IvyDataType.AssocArray:
		{
			IvyData[string] newAA;
			foreach( ref key, ref val; node.assocArray ) {
				newAA[key] = deeperCopy(val);
			}
			return IvyData(newAA);
		}
		case IvyDataType.ClassNode:
		case IvyDataType.ExecutionFrame:
		case IvyDataType.DataNodeRange:
		case IvyDataType.AsyncResult:
		case IvyDataType.ModuleObject:
			// These types of nodes shouldn't appear in module constants table so leave these not implemented for now
			break;
	}
	import std.conv: text;
	throw new DataNodeException(`Getting of deeper copy for "` ~ node.type.text ~ `" is not implemented for now`);
}

IvyData errorToIvyData(Throwable error)
{
	import std.conv: to;
	import std.exception: enforce;
	import trifle.backtrace: getBacktrace;

	IvyData res;
	res[`errorMsg`] = error.msg;
	res[`traceInfo`] = getBacktrace(error);
	res[`errorFile`] = error.file;
	res[`errorLine`] = error.line;
	return res;
}