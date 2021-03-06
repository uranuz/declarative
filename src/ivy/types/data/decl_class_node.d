module ivy.types.data.decl_class_node;

import ivy.types.data.base_class_node: BaseClassNode;

class DeclClassNode: BaseClassNode
{
	import ivy.types.data: IvyData, IvyDataType;
	import ivy.types.data.decl_class: DeclClass;
	import ivy.types.callable_object: CallableObject;

	import std.exception: enforce;

protected:
	DeclClass _type;

	// Non-static members of class
	IvyData[string] _dataDict;

public:
	this(DeclClass type) {
		enforce(type !is null, "Expected instance of DeclClass");

		this._type = type;

		// Bind all class callables to class instance
		foreach (it; this._type._getMethods())
			this._dataDict[it.name] = new CallableObject(it.callable, IvyData(this));
	}

override {
	IvyData __getAttr__(string field) {
		if( auto valPtr = field in this._dataDict ) {
			return *valPtr;
		}
		// Find field in a class if there is no such field in the class instance
		return this._type.__getAttr__(field);
	}

	void __setAttr__(IvyData val, string field) {
		this._dataDict[field] = val;
	}
}

}