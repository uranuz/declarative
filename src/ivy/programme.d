module ivy.programme;


// Representation of programme ready for execution
class ExecutableProgramme
{
	import ivy.types.module_object: ModuleObject;

	import ivy.types.data: IvyData, IvyDataType;
	import ivy.types.data.async_result: AsyncResult, AsyncResultState;

	import ivy.interpreter.directive.iface: IDirectiveInterpreter;
	import ivy.interpreter.directive.factory: InterpreterDirectiveFactory;
	import ivy.interpreter.interpreter: Interpreter;
	import ivy.interpreter.module_objects_cache: ModuleObjectsCache;

	import ivy.engine: IvyEngine;

	import ivy.log.info: LogInfo;

	alias LogerMethod = void delegate(LogInfo);
private:
	static struct SaveStateResult
	{
		Interpreter interp;
		AsyncResult asyncResult;
	}

	string _mainModuleName;
	ModuleObjectsCache _moduleObjCache;
	InterpreterDirectiveFactory _directiveFactory;
	LogerMethod _logerMethod;

public:
	this(
		string mainModuleName,
		ModuleObjectsCache moduleObjCache,
		InterpreterDirectiveFactory directiveFactory,
		LogerMethod logerMethod = null
	) {
		import std.exception: enforce;

		enforce(mainModuleName.length, `Expected programme main module name`);
		enforce(moduleObjCache !is null, `Expected module objects cache`);
		enforce(directiveFactory !is null, `Expected directive factory`);

		this._mainModuleName = mainModuleName;
		this._moduleObjCache = moduleObjCache;
		this._directiveFactory = directiveFactory;
		this._logerMethod = logerMethod;
	}

	/// Run programme main module
	AsyncResult run(IvyData[string] extraGlobals = null) {
		return runSaveState(extraGlobals).asyncResult;
	}

	IvyData runSync(IvyData[string] extraGlobals = null)
	{
		IvyData ivyRes = runSaveStateSync(extraGlobals)._stack.back();
		if( ivyRes.type == IvyDataType.AsyncResult ) {
			ivyRes.asyncResult.then(
				(IvyData methodRes) => ivyRes = methodRes
			);
		}
		return ivyRes;
	}

	SaveStateResult runSaveState(IvyData[string] extraGlobals = null)
	{
		import ivy.interpreter.interpreter: Interpreter;

		Interpreter interp = new Interpreter(
			_mainModuleName,
			_moduleObjCache,
			_directiveFactory,
			_logerMethod
		);
		interp.addExtraGlobals(extraGlobals);
		return SaveStateResult(interp, interp.execLoop());
	}

	Interpreter runSaveStateSync(IvyData[string] extraGlobals = null)
	{
		import std.exception: enforce;
		SaveStateResult moduleExecRes = runSaveState(extraGlobals);
		enforce(
			moduleExecRes.asyncResult.state == AsyncResultState.resolved,
			`Expected module execution async result resolved state`);
		return moduleExecRes.interp;
	}

	AsyncResult runMethod(
		string methodName,
		IvyData methodParams = IvyData(),
		IvyData[string] extraGlobals = null
	) {
		AsyncResult fResult = new AsyncResult();
		SaveStateResult moduleExecRes = runSaveState(extraGlobals);
		
		moduleExecRes.asyncResult.then(
			(IvyData modRes) {
				// Module executed successfuly, then call method
				moduleExecRes.interp.runModuleDirective(methodName, methodParams).then(fResult);
			},
			&fResult.reject);
		return fResult;
	}

	IvyData runMethodSync(
		string methodName,
		IvyData methodParams = IvyData(),
		IvyData[string] extraGlobals = null
	) {
		import std.exception: enforce;
		AsyncResult asyncRes =
			runSaveStateSync(extraGlobals)
			.runModuleDirective(methodName, methodParams);
		enforce(
			asyncRes.state == AsyncResultState.resolved,
			`Expected method execution async result resolved state`);
		IvyData ivyRes;
		asyncRes.then((IvyData methodRes) => ivyRes = methodRes);
		return ivyRes;
	}

	void logerMethod(LogerMethod method) @property {
		_logerMethod = method;
	}

	import std.json: JSONValue;
	JSONValue toStdJSON()
	{
		import ivy.types.data.conv.ivy_to_std_json: toStdJSON2;
		import ivy.types.data.conv.consts: IvySrlField;

		JSONValue[string] moduleObjects;
		foreach( string modName, ModuleObject modObj; _moduleObjCache.moduleObjects )
		{
			JSONValue[] jConsts;
			foreach( ref IvyData con; modObj._consts ) {
				jConsts ~= toStdJSON2(con);
			}
			moduleObjects[modName] = [
				"consts": JSONValue(jConsts),
				"fileName": JSONValue(modObj.symbol.location.fileName),
				IvySrlField.type: JSONValue(IvyDataType.ModuleObject)
			];
		}
		JSONValue jProg = [
			`mainModuleName`: JSONValue(this._mainModuleName),
			`moduleObjects`: JSONValue(moduleObjects)
		];
		return jProg;
	}
}




