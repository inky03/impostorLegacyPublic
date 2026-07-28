package extensions.hscript;

import haxe.Constraints.IMap;
import haxe.PosInfos;

import Type.ValueType;

import crowplexus.iris.Iris;
import crowplexus.hscript.*;
import crowplexus.hscript.Expr;
import crowplexus.hscript.Tools;

/**
 * Modified Iris Interp for variety of improvements.
 * 
 * crash fix on for loops in debug
 * 
 * improved error reporting on null functions
 * 
 * parent field to directly access an object
 * 
 * public fields support with `Sharables`
 */
class InterpEx extends crowplexus.hscript.Interp
{
	public var sharedFields:Null<Sharables> = null;
	
	public function new(?parent:Dynamic, ?shareables:Sharables)
	{
		super();
		if (parent != null) this.parent = parent;
		this.sharedFields = shareables;
		showPosOnLog = false;
	}
	
	public var parentFields:haxe.ds.ObjectMap<Dynamic, Array<String>> = new haxe.ds.ObjectMap();
	public var parents:Array<Dynamic> = [];
	public var parent(default, set):Dynamic;
	
	function set_parent(value:Dynamic)
	{
		parents.resize(0);
		parents.push(value);
		
		updateParentFields();
		
		return parent;
	}
	
	function updateParentFields():Void
	{
		for (parent in parents)
		{
			if (!parentFields.exists(parent))
				parentFields.set(parent, Type.getInstanceFields(Type.getClass(parent)));
		}
		
		for (parent in parentFields.keys())
		{
			if (!parents.contains(parent))
				parentFields.remove(parent);
		}
	}
	
	public function addParent(parent:Dynamic):Dynamic
	{
		if (!parents.contains(parent))
		{
			parents.insert(0, parent);
			
			updateParentFields();
		}
		
		return parent;
	}
	
	public function removeParent(parent:Dynamic):Dynamic
	{
		parents.remove(parent);
		
		updateParentFields();
		
		return parent;
	}
	
	override function increment(e:Expr, prefix:Bool, delta:Int):Dynamic
	{
		#if hscriptPos
		curExpr = e;
		#end
		
		switch (e.e)
		{
			case EIdent(id):
				final v:Dynamic = resolve(id);
				
				if (prefix) return setTo(id, v + delta);
				
				setTo(id, v + delta);
				
				return v;
			
			default:
				return super.increment(e, prefix, delta);
		}
	}
	
	function setTo(id:String, v:Dynamic, canDefine:Bool = false):Dynamic
	{
		if (locals.exists(id))
		{
			var l = locals.get(id);
			
			if (l.const != true) l.r = v;
			else warn(ECustom('Cannot reassign final, for constant expression -> $id'));
		}
		else
		{
			if (variables.exists(id))
			{
				setVar(id, v);
				return v;
			}
			
			for (parent => fields in parentFields)
			{
				if (fields.contains(id) || fields.contains('set_$id'))
				{
					Reflect.setProperty(parent, id, v);
					return v;
				}
			}
			
			if (sharedFields != null && sharedFields.exists(id)) sharedFields.set(id, v);
		}
		
		if (canDefine) setVar(id, v);
		return v;
	}
	
	override function resolve(id:String):Dynamic
	{
		if (locals.exists(id)) return locals.get(id).r;
		
		if (variables.exists(id)) return variables.get(id);
				
		if (imports.exists(id)) return imports.get(id);
		
		for (parent => fields in parentFields)
		{
			if (fields.contains(id) || fields.contains('get_$id')) return Reflect.getProperty(parent, id);
		}
		
		if (sharedFields?.exists(id)) return sharedFields.get(id);
		
		error(EUnknownVariable(id));
		
		return null;
	}
	
	override function evalAssignOp(op, fop, e1, e2):Dynamic
	{
		var v;
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				return setTo(id, fop(expr(e1), expr(e2)));
			case EField(e, f, s):
				var obj = expr(e);
				if (obj == null) if (!s) error(EInvalidAccess(f));
				else return null;
				v = fop(get(obj, f), expr(e2));
				v = set(obj, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					v = fop(getMapValue(arr, index), expr(e2));
					setMapValue(arr, index, v);
				}
				else
				{
					v = fop(arr[index], expr(e2));
					arr[index] = v;
				}
			default:
				return error(EInvalidOp(op));
		}
		return v;
	}
	
	override function assign(e1:Expr, e2:Expr):Dynamic
	{
		var v = expr(e2);
		switch (Tools.expr(e1))
		{
			case EIdent(id):
				return setTo(id, v, true);
			case EField(e, f, s):
				var e = expr(e);
				if (e == null) if (!s) error(EInvalidAccess(f));
				else return null;
				v = set(e, f, v);
			case EArray(e, index):
				var arr:Dynamic = expr(e);
				var index:Dynamic = expr(index);
				if (isMap(arr))
				{
					setMapValue(arr, index, v);
				}
				else
				{
					arr[index] = v;
				}
				
			default:
				error(EInvalidOp("="));
		}
		return v;
	}
	
	override function fcall(o:Dynamic, f:String, args:Array<Dynamic>):Dynamic
	{
		for (_using in usings)
		{
			var v = _using.call(o, f, args);
			if (v != null) return v;
		}
		
		final method = get(o, f);
		
		if (method == null)
		{
			Iris.error('Unknown function: $f', posInfos());
			return null; // return before call so we dont double error messages
		}
		
		return call(o, method, args);
	}
	
	override public function get(o:Dynamic, f:String):Dynamic
	{
		if (o is Enum) // fixes hl too
		{
			var e = Type.createEnum(o, f);
			if (e != null) return e;
			
			error(EInvalidAccess(f));
		}
		
		return super.get(o, f);
	}
	
	override public function expr(e:Expr):Dynamic
	{
		#if hscriptPos
		curExpr = e;
		#end
		
		return switch (e.e)
		{
			case EMeta(meta, _, e):
				if (meta == ':sharable' && sharedFields != null)
				{
					switch (Tools.expr(e))
					{
						case EFunction(_, _, field) if (depth == 0):
							final r = expr(e);
							sharedFields.set(field, r);
							r;
							
						case EVar(field, _, e) if (depth == 0):
							final r = (e != null ? expr(e) : null);
							sharedFields.set(field, r);
							r;
							
						default:
							expr(e);
					}
				}
				else
				{
					expr(e);
				}
			
			case EFor(i, v, it, e):
				forLoop(i, v, it, e);
				return null;
				
			default:
				super.expr(e);
		}
	}
	
	override function makeIterator(v:Dynamic):Iterator<Dynamic>
	{
		if (v is Array) return (v : Array<Dynamic>).iterator();
		
		var iter:Dynamic = v.iterator;
		v = (iter != null ? (iter : haxe.Constraints.Function)() : v);
		
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		
		return v;
	}
	
	function makeKeyValueIterator(v:Dynamic):KeyValueIterator<Dynamic, Dynamic>
	{
		if ((v is haxe.ds.IntMap) || (v is haxe.ds.StringMap) || (v is haxe.ds.ObjectMap) || (v is haxe.ds.EnumValueMap))
		{
			return (v : haxe.Constraints.IMap<Dynamic, Dynamic>).keyValueIterator();
		}
		else if (v is Array)
		{
			return (v : Array<Dynamic>).keyValueIterator();
		}
		
		var iter:Dynamic = v.keyValueIterator;
		v = (iter != null ? (iter : haxe.Constraints.Function)() : v);
		
		if (v.hasNext == null || v.next == null)
			error(EInvalidIterator(v));
		
		return v;
	}
	
	override function forLoop(n, v, it:Dynamic, e):Void
	{
		final old = declared.length;
		final ef = expr.bind(e);
		
		declared.push({ n : n, old : locals.get(n) });
		
		if (v == null)
		{
			var it = makeIterator(expr(it));
			var next:Void -> Dynamic = it.next, hasNext:Void -> Bool = it.hasNext;
			
			while (hasNext())
			{
				locals.set(n, { r: next(), const: false });
				
				if (!loopRun(ef)) break;
			}
		}
		else // keyvalue
		{
			declared.push({ n : v, old : locals.get(v) });
			
			var it = makeKeyValueIterator(expr(it));
			var next:Void -> Dynamic = it.next, hasNext:Void -> Bool = it.hasNext;
			
			while (hasNext())
			{
				var r:Dynamic = next();
				
				if (r.key == null) error(ECustom('$v has no field key'));
				if (r.value == null) error(ECustom('$v has no field value'));
				
				locals.set(n, { r: r.key, const: false });
				locals.set(v, { r: r.value, const: false });
				
				if (!loopRun(ef)) break;
			}
		}
		
		restore(old);
	}
	
	inline function loopRun(f:Void -> Void)
	{
		var cont:Bool = true;
		
		try
		{
			f();
		}
		catch (err:Any)
		{
			switch (Type.typeof(err))
			{
				case ValueType.TEnum(_): // just cuase someone wouldnt make the enum PUBLIC DIE
					switch (Type.enumConstructor(err)) {
						case 'SContinue':
						case 'SBreak': cont = false;
						default: throw err;
					}
					
				default:
					throw err;
			}
		}
		
		return cont;
	}
}
