///Module consists of declarations related to Ivy bytecode
module ivy.bytecode;

enum OpCode: ubyte {
	InvalidCode, // Used to check if code of operation was not properly set

	Nop,

	// Load constant data from code
	LoadConst,

	// Arithmetic binary operations opcodes
	Add,
	Sub,
	Mul,
	Div,
	Mod,

	// Arrays or strings concatenation
	Concat,
	Append,
	Insert,
	InsertMass,

	// General unary operations opcodes
	UnaryMin,
	UnaryPlus,
	UnaryNot,

	// Comparision operations opcodes
	LT,
	GT,
	Equal,
	NotEqual,
	LTEqual,
	GTEqual,

	// Array or assoc array operations
	LoadSubscr,
	StoreSubscr,
	LoadSlice,

	// Frame data load/ store
	StoreName,
	StoreLocalName,
	StoreNameWithParents,
	LoadName,

	// Preparing and calling directives
	LoadDirective,
	RunCallable,
	Call,
	Await,

	// Import another module
	ImportModule,
	FromImport,

	// Flow control opcodes
	JumpIfTrue,
	JumpIfFalse,
	JumpIfFalseOrPop, // Used in "and"
	JumpIfTrueOrPop, // Used in "or"
	Jump,
	Return,

	// Stack operations
	PopTop,
	SwapTwo,
	DubTop,

	// Loop initialization and execution
	GetDataRange,
	RunLoop,

	// Data construction opcodes
	MakeArray,
	MakeAssocArray,

	MarkForEscape
}

// Minimal element of bytecode is instruction opcode with optional arg
struct Instruction
{
	OpCode opcode; // So... it's instruction opcode
	size_t arg; // One arg for now
}
