define('ivy/interpreter/directive/base', [
	'ivy/interpreter/directive/iface',
	'ivy/types/symbol/global'
], function(
	IDirectiveInterpreter,
	globalSymbol
) {
return FirClass(
	function DirectiveInterpreter(method, symbol) {
		this._method = method;
		this._symbol = symbol;
	}, IDirectiveInterpreter, {
		interpret: function(interp) {
			this._method(interp);
		},

		symbol: firProperty(function() {
			if( this._symbol == null ) {
				throw new Error("Directive symbol is not set for: " + this.constructor.name);
			}
			return this._symbol;
		}),

		moduleSymbol: firProperty(function() {
			return globalSymbol;
		})
	});
});