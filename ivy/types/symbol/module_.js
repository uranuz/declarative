define('ivy/types/symbol/module_', [
	'ivy/types/symbol/iface/callable',
	'ivy/types/symbol/dir_body_attrs',
	'ivy/location',
	'ivy/types/symbol/consts'
], function(
	ICallableSymbol,
	DirBodyAttrs,
	Location,
	SymbolConsts
) {
var
	emptyBodyAttrs = DirBodyAttrs(),
	SymbolKind = SymbolConsts.SymbolKind;
return FirClass(
	function ModuleSymbol(name, loc) {
		this._name = name;
		this._loc = Location();

		if( !this._name.length ) {
			throw new Error('Expected module symbol name');
		}
		if( !(this._loc instanceof Location) ) {
			throw new Error('Expected instance of Location');
		}
	}, ICallableSymbol, {
		name: firProperty(function() {
			return this._name;
		}),

		location: firProperty(function() {
			return this._loc;
		}),

		kind: firProperty(function() {
			return SymbolKind.module_;
		}),

		attrs: firProperty(function() {
			return [];
		}),

		getAttr: function() {
			throw new Error('Module symbol has no attributes');
		},

		bodyAttrs: firProperty(function() {
			return emptyBodyAttrs;
		})
	}
);
});