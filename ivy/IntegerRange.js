define('ivy/IntegerRange', [
	'ivy/errors',
	'ivy/DataNodeRange'
], function(errors, DataNodeRange) {
	__extends(IntegerRange, DataNodeRange);
	function IntegerRange(begin, end) {
		if( typeof(begin) !== 'number' || typeof(end) !== 'number' ) {
			throw new errors.IvyError('Number range begin and end arguments must be numbers');
		}
		if( begin > end ) {
			throw new errors.IvyError('Begin must not be greater than end');
		}
		this._current = begin;
		this._end = end;
	};
	return __mixinProto(IntegerRange, {
		// Method must return first item of range or raise error if range is empty
		front: function() {
			return this._current;
		},
		// Method must advance range to the next item
		pop: function() {
			if( this.empty() ) {
				throw new errors.IvyError('Cannot advance empty IntegerRange');
			}
			return this._current++;
		},
		// Method is used to check if range is empty
		empty: function() {
			return this._current >= this._end;
		}
	});
});