module ivy.engine.module_object_cache;

class ModuleObjectCache
{
	import core.sync.mutex: Mutex;

	import ivy.types.module_object: ModuleObject;

private:
	// Dictionary with module objects that compiler produces
	ModuleObject[string] _moduleObjects;

	Mutex _mutex;

public:
	this() {
		this._mutex = new Mutex();
	}

	ModuleObject get(string moduleName) {
		return this._moduleObjects.get(moduleName, null);
	}

	void add(ModuleObject moduleObject)
	{
		synchronized(this._mutex) {
			this._moduleObjects[moduleObject.symbol.name] = moduleObject;
		}
	}

	void clearCache()
	{
		synchronized(this._mutex) {
			this._moduleObjects.clear();
		}
	}

	ModuleObject[string] moduleObjects() @property {
		return this._moduleObjects;
	}

	string toPrettyStr()
	{
		import ivy.types.data: IvyDataType;
		import ivy.bytecode: OpCode;

		import std.conv: text;
		import std.range: empty, back, take;
		import std.algorithm: canFind;

		string result;
		static immutable OpCode[] instrsWhereArgRefsConst = [
			OpCode.LoadConst,
			OpCode.StoreGlobalName,
			OpCode.StoreName,
			OpCode.LoadName
		];

		foreach( modName, modObj; this._moduleObjects )
		{
			result ~= "\r\nMODULE " ~ modName ~ "\r\n";
			result ~= "\r\nCONSTANTS\r\n";
			foreach( i, con; modObj._consts ) {
				result ~= i.text ~ "  " ~ con.toDebugString() ~ "\r\n";
			}

			result ~= "\r\nCODE\r\n";
			foreach( i, con; modObj._consts )
			{
				if( con.type != IvyDataType.CodeObject ) {
					continue;
				}
				result ~= "\r\nCode object " ~ i.text ~ " (" ~ con.codeObject.symbol.name ~ ")" ~ "\r\n";
				foreach( k, instr; con.codeObject.instrs )
				{
					string val;
					if(
						instr.arg < modObj._consts.length 
						&& instrsWhereArgRefsConst.canFind(instr.opcode)
					) {
						enum limit = 50;
						val = modObj._consts[instr.arg].toDebugString();
						if( val.length >= limit ) {
							val = val.take(limit).text ~ "...";
						}
						val = " (" ~ val ~ ")";
					}
					result ~= k.text ~ "  " ~ instr.opcode.text ~ "  " ~ instr.arg.text ~ val ~ "\r\n";
				}
				result ~= "\r\nCode object source map(line, startAddr)\r\n";
				foreach( mapItem; con.codeObject.sourceMap ) {
					result ~= mapItem.line.text ~ "\t\t" ~ mapItem.startInstr.text ~ "\r\n";
				}
			}

			result ~= "\r\nEND OF MODULE " ~ modName ~ "\r\n";
		}

		return result;
	}
}
