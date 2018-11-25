module ivy.interpreter.module_objects_cache;

import ivy.code_object: ModuleObject;
import ivy.interpreter.data_node: IvyDataType;
import ivy.bytecode: OpCode;

class ModuleObjectsCache
{
private:
	// Dictionary with module objects that compiler produces
	ModuleObject[string] _moduleObjects;

public:
	ModuleObject get(string moduleName) {
		return _moduleObjects.get(moduleName, null);
	}

	void add(ModuleObject moduleObj) {
		_moduleObjects[moduleObj.name] = moduleObj;
	}

	void clearCache() {
		_moduleObjects.clear();
	}

	ModuleObject[string] moduleObjects() @property {
		return _moduleObjects;
	}

	string toPrettyStr()
	{
		import std.conv;
		import std.range: empty, back, take;
		import std.algorithm: canFind;

		string result;
		static immutable OpCode[] instrsWhereArgRefsConst = [
			OpCode.LoadConst,
			OpCode.StoreName,
			OpCode.StoreLocalName,
			OpCode.StoreNameWithParents,
			OpCode.LoadName
		];

		foreach( modName, modObj; _moduleObjects )
		{
			result ~= "\r\nMODULE " ~ modName ~ "\r\n";
			result ~= "\r\nCONSTANTS\r\n";
			foreach( i, con; modObj._consts ) {
				result ~= i.text ~ "  " ~ con.toDebugString() ~ "\r\n";
			}

			result ~= "\r\nCODE\r\n";
			foreach( i, con; modObj._consts )
			{
				if( con.type == IvyDataType.CodeObject )
				{
					if( !con.codeObject ) {
						result ~= "\r\nCode object " ~ i.text ~ " is null\r\n";
					}
					else
					{
						result ~= "\r\nCode object " ~ i.text ~ "\r\n";
						foreach( k, instr; con.codeObject._instrs )
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
						foreach( mapItem; con.codeObject._sourceMap )
						{
							result ~= mapItem.line.text ~ "\t\t" ~ mapItem.startInstr.text ~ "\r\n";
						}
					}
				}
			}


			result ~= "\r\nEND OF MODULE " ~ modName ~ "\r\n";
		}

		return result;
	}
}