module declarative.node_visitor;

import declarative.node;


class AbstractNodeVisitor
{
	void visit(IDeclNode node) { assert(0); }
	
	//Expressions
	void visit(IExpression node) { visit( cast(IDeclNode) node ); }
	void visit(ILiteralExpression node) { visit( cast(IExpression) node ); }
	void visit(INameExpression node) { visit( cast(IExpression) node ); }
	void visit(IOperatorExpression node) { visit( cast(IExpression) node ); }
	void visit(IUnaryExpression node) { visit( cast(IExpression) node ); }
	void visit(IBinaryExpression node) { visit( cast(IExpression) node ); }
	
	//Statements
	void visit(IStatement node) { visit( cast(IDeclNode) node ); }
	void visit(IKeyValueAttribute node) { visit( cast(IDeclNode) node ); }
	void visit(IDirectiveStatement node) { visit( cast(IStatement) node ); }
	void visit(ICompoundStatement node) { visit( cast(IStatement) node ); }
}