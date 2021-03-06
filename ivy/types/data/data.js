define('ivy/types/data/data', [
	'exports',
	'ivy/types/data/consts',
	'ivy/types/data/render',
	'ivy/interpreter/execution_frame',
	'ivy/types/code_object',
	'ivy/types/callable_object',
	'ivy/types/data/iface/range',
	'ivy/types/data/iface/class_node',
	'ivy/types/data/async_result'
], function(
	idat,
	Consts,
	DataRender,
	ExecutionFrame,
	CodeObject,
	CallableObject,
	DataNodeRange,
	IClassNode,
	AsyncResult
) {
var IvyDataType = Consts.IvyDataType;

Object.assign(idat, {
	// Value accessors with type check
	boolean: function(val) {
		return idat._getTyped(val, IvyDataType.Boolean);
	},

	integer: function(val) {
		return idat._getTyped(val, IvyDataType.Integer);
	},

	floating: function(val) {
		return idat._getTyped(val, IvyDataType.Floating);
	},

	str: function(val) {
		return idat._getTyped(val, IvyDataType.String);
	},

	array: function(val) {
		return idat._getTyped(val, IvyDataType.Array);
	},

	assocArray: function(val) {
		return idat._getTyped(val, IvyDataType.AssocArray);
	},

	assocArray: function(val) {
		return idat._getTyped(val, IvyDataType.AssocArray);
	},

	classNode: function(val) {
		return idat._getTyped(val, IvyDataType.ClassNode);
	},

	codeObject: function(val) {
		return idat._getTyped(val, IvyDataType.CodeObject);
	},

	callable: function(val) {
		return idat._getTyped(val, IvyDataType.Callable);
	},

	execFrame: function(val) {
		return idat._getTyped(val, IvyDataType.ExecutionFrame);
	},

	dataRange: function(val) {
		return idat._getTyped(val, IvyDataType.DataNodeRange);
	},

	asyncResult: function(val) {
		return idat._getTyped(val, IvyDataType.AsyncResult);
	},

	moduleObject: function(val) {
		return idat._getTyped(val, IvyDataType.ModuleObject);
	},

	_getTyped: function(val, type) {
		if( idat.type(val) !== type ) {
			throw new Error('Value is not of type: ' + type);
		}
		return val;
	},

	type: function(val) {
		if( val === undefined ) {
			return IvyDataType.Undef;
		} else if( val === null) {
			return IvyDataType.Null;
		} else if( val === true || val === false || val instanceof Boolean ) {
			return IvyDataType.Boolean;
		} else if( typeof(val) === 'string' || val instanceof String ) {
			return IvyDataType.String;
		} else if( typeof(val) === 'number' || val instanceof Number ) {
			return Number.isInteger(val)? IvyDataType.Integer: IvyDataType.Floating;
		} else if( val instanceof Array ) {
			return IvyDataType.Array;
		} else if( val instanceof CodeObject ) {
			return IvyDataType.CodeObject;
		} else if( val instanceof AsyncResult ) {
			return IvyDataType.AsyncResult;
		} else if( val instanceof CallableObject ) {
			return IvyDataType.Callable;
		} else if( val instanceof ExecutionFrame ) {
			return IvyDataType.ExecutionFrame;
		} else if( val instanceof DataNodeRange ) {
			return IvyDataType.DataNodeRange;
		} else if( val instanceof IClassNode ) {
			return IvyDataType.ClassNode;
		} else if( val instanceof Object ) {
			return IvyDataType.AssocArray;
		} else {
			throw new Error('Unrecognized node type!');
		}
	},
	empty: function(val)
	{
		switch( idat.type(val) )
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
				return !val.length;
			case IvyDataType.Array:
				return !val.length;
			case IvyDataType.AssocArray:
				return !Object.keys(val).length;
			case IvyDataType.ClassNode:
				return val.empty;
			case IvyDataType.DataNodeRange:
				return val.empty;
			case IvyDataType.CodeObject:
				return !val.getInstrCount();
			case IvyDataType.Callable:
			case IvyDataType.ExecutionFrame:
			case IvyDataType.AsyncResult:
			case IvyDataType.ModuleObject:
				return false;
		}
		throw new Error('Cannot test value for emptyness');
	},

	toBoolean: function(val) {
		return idat.type(val) === IvyDataType.Boolean? val: !idat.empty(val);
	},

	length: function(val) {
		switch( idat.type(val) )
		{
			case IvyDataType.Undef:
			case IvyDataType.Null:
				return 0; // Return 0, but not error for convenience
			case IvyDataType.Integer:
			case IvyDataType.Floating:
			case IvyDataType.Boolean:
				break; // Error. Has no length
			case IvyDataType.String:
				return val.length;
			case IvyDataType.Array:
				return val.length;
			case IvyDataType.AssocArray:
				return Object.keys(val).length;
			case IvyDataType.ClassNode:
				return val.length;
			case IvyDataType.CodeObject:
				return val.getInstrCount();
			case IvyDataType.Callable:
			case IvyDataType.ExecutionFrame:
			case IvyDataType.DataNodeRange:
			case IvyDataType.AsyncResult:
			case IvyDataType.ModuleObject:
				break; // Error. Has no length
		}
		throw new Error("No \"length\" property for type: " + this.type);
	},

	toFloating: function(val) {
		switch( idat.type(val) ) {
			case IvyDataType.Boolean: return val? 1.0: 0.0;
			case IvyDataType.Integer:
			case IvyDataType.Floating:
				return val;
			case IvyDataType.String: {
				var parsed = parseFloat(val, 10);
				if( isNaN(parsed) || String(parsed) !== val ) {
					throw new Error('Unable to parse value as Floating');
				}
				return parsed;
			}
			default:
				break;
		}
		throw new Error('Cannot convert value to Floating');
	},

	toInteger: function(val) {
		switch( idat.type(val) ) {
			case IvyDataType.Boolean: return val? 1: 0;
			case IvyDataType.Integer: return val;
			case IvyDataType.String: {
				var parsed = parseInt(val, 10);
				if( isNaN(parsed) || String(parsed) !== val ) {
					throw new Error('Unable to parse value as Integer');
				}
				return parsed;
			}
			default:
				break;
		}
		throw new Error('Cannot convert value to Integer');
	},

	opEquals: function(val, rhs) {
		if( idat.type(rhs) != idat.type(val) ) {
			return false;
		}
		switch( idat.type(val) )
		{
			case IvyDataType.Undef:
			case IvyDataType.Null:
				return true; // Undef and Null values are equal to each other
			case IvyDataType.Boolean: return val.boolean == rhs.boolean;
			case IvyDataType.Integer: return val.integer == rhs.integer;
			case IvyDataType.Floating: return val.floating == rhs.floating;
			case IvyDataType.String: return val.str == rhs.str;
			case IvyDataType.Array:
			{
				if( val.length != rhs.length ) {
					return false;
				}
				for( var i = 0; i < val.length; i++ )
				{
					if( !idat.opEquals(val[i], rhs[i]) ) {
						return false;
					}
				}
				return true; // All equal - fantastic!
			}
			case IvyDataType.AssocArray:
			{
				if( Object.keys(val).length != Object.keys(rhs).length ) {
					return false;
				}
				for( var key in val )
				{
					if( !val.hasOwnProperty(key) ) {
						continue;
					}
					if( !rhs.hasOwnProperty(key) ) {
						return false;
					}
					// Compare values
					if( !idat.opEquals(val[key], rhs[key]) ) {
						return false;
					}
				}
				return true; // All keys exist and values are equal - fantastic!
			}
			case IvyDataType.CodeObject:
				return val.codeObject.opEquals(rhs);
			default:
				throw new Exception("Cannot compare data nodes of type: " + idat.type(val));
		}
	},
	toString: function(val) {
		return DataRender.renderDataNode2(val)
	}
});
});