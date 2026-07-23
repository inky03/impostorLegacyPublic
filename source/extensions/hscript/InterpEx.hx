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
	
	override function makeIterator(v:Dynamic):Iterator<Dynamic>
	{
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if (v.iterator != null) v = v.iterator();
		#else
		// DATA CHANGE //does a null check because this crashes on debug build
		if (v.iterator != null) try
			v = v.iterator()
		catch (e:Dynamic) {};
		#end
		if (v.hasNext == null || v.next == null) error(EInvalidIterator(v));
		return v;
	}
	
	public var parentFields:Array<String> = [];
	public var parent(default, set):Dynamic;
	
	function set_parent(value:Dynamic)
	{
		parent = value;
		parentFields = value != null ? Type.getInstanceFields(Type.getClass(value)) : [];
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
				var l = locals.get(id);
				var v:Dynamic = (locals.exists(id) ? l.r : resolve(id));
				
				function setTo(a) {
					if (locals.exists(id))
					{
						if (l.const != true) l.r = a else error(ECustom("Cannot reassign final, for constant expression -> " + id));
						
						return;
					}
					
					if (variables.exists(id))
					{
						setVar(id, a);
					}
					else if (parentFields?.contains(id))
					{
						Reflect.setProperty(parent, id, a);
					}
					else if (sharedFields?.exists(id))
					{
						sharedFields.set(id, a);
					}
				}
				
				if (prefix)
				{
					v += delta;
					setTo(v);
				}
				else
				{
					setTo(v + delta);
				}
				
				return v;
			
			default:
				return super.increment(e, prefix, delta);
		}
	}
	
	override function resolve(id:String):Dynamic
	{
		if (locals.exists(id)) return locals.get(id).r;
		
		if (variables.exists(id)) return variables.get(id);
				
		if (imports.exists(id)) return imports.get(id);
		
		if (parentFields.contains(id) || parentFields.contains('get_$id')) return Reflect.getProperty(parent, id);
		
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
				var l = locals.get(id);
				v = fop(expr(e1), expr(e2));
				if (l == null)
				{
					if (parentFields.contains(id) || parentFields.contains('set_$id'))
					{
						Reflect.setProperty(parent, id, v);
					}
					else if (sharedFields?.exists(id))
					{
						sharedFields.set(id, v);
					}
					else
					{
						setVar(id, v);
					}
				}
				else
				{
					if (l.const != true) l.r = v;
					else warn(ECustom("Cannot reassign final, for constant expression -> " + id));
				}
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
				var l = locals.get(id);
				if (l == null)
				{
					if (!variables.exists(id) && (parentFields.contains(id) || parentFields.contains('set_$id')))
					{
						Reflect.setProperty(parent, id, v);
					}
					else if (!variables.exists(id) && sharedFields != null && sharedFields.exists(id))
					{
						sharedFields.set(id, v);
					}
					else
					{
						setVar(id, v);
					}
				}
				else
				{
					if (l.const != true) l.r = v;
					else warn(ECustom("Cannot reassign final, for constant expression -> " + id));
				}
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
				
			default:
				super.expr(e);
		}
	}
}
