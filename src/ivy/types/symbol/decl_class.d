module ivy.types.symbol.decl_class;

import ivy.types.symbol.iface.callable: ICallableSymbol;

class DeclClassSymbol: ICallableSymbol
{
	import std.json: JSONValue;

	import trifle.location: Location;

	import ivy.types.symbol.dir_attr: DirAttr;
	import ivy.types.symbol.dir_body_attrs: DirBodyAttrs;

private:
	string _name;
	Location _loc;
	ICallableSymbol _initSymbol;

public:
	this(string name, Location loc)
	{
		this._name = name;
		this._loc = loc;
	}

override
{
	string name() @property {
		return this._name;
	}

	Location location() @property {
		return _loc;
	}

	DirAttr[] attrs() @property {
		return this.initSymbol.attrs;
	}

	DirAttr getAttr(string attrName) {
		return this.initSymbol.getAttr(attrName);
	}

	DirBodyAttrs bodyAttrs() @property {
		return this.initSymbol.bodyAttrs;
	}

	JSONValue toStdJSON() @property
	{
		JSONValue res = this.initSymbol.toStdJSON();
		res["name"] = this._name;

		return res;
	}
}
	ICallableSymbol initSymbol() @property
	{
		import std.exception: enforce;

		enforce(this._initSymbol !is null, "Init symbol is not set");
		return this._initSymbol;
	}

	void initSymbol(ICallableSymbol symb) @property {
		this._initSymbol = symb;
	}

}
