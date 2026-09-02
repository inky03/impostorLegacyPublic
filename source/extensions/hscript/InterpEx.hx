package extensions.hscript;

import insanity.backend.Expr;
import insanity.backend.Exception;

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
@:access(insanity.backend.Interp)
class InterpEx extends insanity.backend.Interp
{
	public var sharedFields:Null<Sharables> = null;
	
	public function new(?environment:insanity.Environment, ?parent:Dynamic, ?shareables:Sharables)
	{
		super(environment, parent);
		
		this.sharedFields = shareables;
		addParent(this.parent);
	}
	
	public override function trace(args:Array<Dynamic>):Void
	{
		var inf = posInfos();
		var v = args.shift();
		if (args.length > 0) inf.customParams = args;
		
		funkin.scripts.FunkinScript.log(Std.string(v), inf);
	}
	
	public var parentFields:haxe.ds.ObjectMap<Dynamic, Map<String, Bool>> = new haxe.ds.ObjectMap();
	public var parents:Array<Dynamic> = [];
	
	public function setParent(value:Dynamic)
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
				parentFields.set(parent, [for (field in Type.getInstanceFields(Type.getClass(parent))) field => true]);
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
	
	override function setVar(name:String, v:Dynamic):Dynamic
	{
		if (insanity.backend.types.Abstract.AbstractTools.isAbstract(v))
			v = v.__a;
		
		if (sharedFields?.exists(name))
		{
			sharedFields.set(name, v);
			return v;
		}
		
		if (imports.exists(name) || variables.exists(name)) return super.setVar(name, v);
		
		for (parent => fields in parentFields)
		{
			if (fields.exists(name) || fields.exists('set_$name'))
			{
				Reflect.setProperty(parent, name, v);
				return v;
			}
		}
		
		if (stack.length <= 1 || defineGlobals) {
			variables.set(name, v);
			return v;
		}
		
		error(EUnknownVariable(name));
		
		return v;
	}
	
	override function resolve(id:String):Dynamic
	{
		for (parent => fields in parentFields)
		{
			if (fields.exists(id) || fields.exists('get_$id')) return Reflect.getProperty(parent, id);
		}
		
		if (sharedFields?.exists(id)) return sharedFields.get(id);
		
		return super.resolve(id);
	}
	
	override function isResolvable(id:String):Bool {
		if (imports.exists(id) || variables.exists(id) || sharedFields?.exists(id)) return true;
		
		for (parent => fields in parentFields)
		{
			if (fields.exists(id) || fields.exists('get_$id')) return true;
		}
		
		return false;
	}
	
	#if (hl)
	override public function get(o:Dynamic, f:String):Dynamic
	{
		if (o is Enum)
		{
			var e = Type.createEnum(o, f);
			if (e != null) return e;
			
			error(EInvalidAccess(f));
		}
		
		return super.get(o, f);
	}
	#end
	
	override public function expr(e:Expr, ?t:CType, void:Bool = false, mapCompr:Bool = false):Dynamic
	{
		return switch (e.e)
		{
			case EMeta(meta, _, e):
				if (meta == ':sharable' && sharedFields != null)
				{
					switch (e.e)
					{
						case EFunction(_, _, field) if (stack.length <= 1):
							final r = expr(e, t, void, mapCompr);
							sharedFields.set(field, r);
							r;
							
						case EVar(field, _, e) if (stack.length <= 1):
							final r = (e != null ? expr(e, t, void, mapCompr) : null);
							sharedFields.set(field, r);
							r;
							
						default:
							expr(e, t, void, mapCompr);
					}
				}
				else
				{
					expr(e, t, void, mapCompr);
				}
				
			default:
				super.expr(e, t, void, mapCompr);
		}
	}
}
