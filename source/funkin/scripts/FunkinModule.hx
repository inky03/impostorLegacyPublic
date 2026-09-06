package funkin.scripts;

import insanity.backend.Expr;
import insanity.backend.types.Scripted;

@:access(insanity.backend.Parser)
@:access(insanity.backend.Interp)
class FunkinModule extends insanity.Module implements IFunkinModule
{
	public var hash:String;
	
	public override function parse(string:String):Array<ModuleDecl>
	{
		hash = haxe.crypto.Sha256.encode(string);
		
		return super.parse(string);
	}
	
	public override function start(?environment:insanity.Environment):Void {
		if (decls.length == 0) return;
		
		return super.start();
	}
	
	public override function startType(?environment:insanity.Environment, type:IInsanityType):IInsanityType
	{
		if (type is InsanityScriptedClass) {
			var cls:InsanityScriptedClass = cast type;
			
			cls.safe = true;
			cls.onExpressionError = function(e:Dynamic, field:String, ?expr:Expr)
			{
				FunkinScript.log(Std.string(e), interp.posInfos(), ERROR);
			}
			cls.onInstanceError = function(e:Dynamic, fun:String, ?instance:IInsanityScripted)
			{
				FunkinScript.log(Std.string(e), interp.posInfos(), ERROR);
			}
		}
		
		return super.startType(environment, type);
	}
	
	public override dynamic function onProgramError(e:haxe.Exception):Void
	{
		FunkinScript.log(Std.string(e), interp.posInfos(), FATAL);
	}
	public override dynamic function onParsingError(e:haxe.Exception):Void
	{
		FunkinScript.log(Std.string(e), cast {fileName: path, lineNumber: parser.line}, FATAL);
	}
	public override dynamic function onTypeError(e:haxe.Exception, type:IInsanityType):Void
	{
		FunkinScript.log(Std.string(e), cast {fileName: type.path, showLine: false}, FATAL);
	}
	
	public override function setDefaults():Void
	{
		super.setDefaults();
		
		var setImport = interp.imports.set;
		
		// abstracts  (these will be removed but its ok)
		setImport('FlxPoint', flixel.math.FlxPoint.FlxBasePoint);
		setImport("FlxTextAlign", funkin.utils.MacroUtil.buildAbstract(flixel.text.FlxText.FlxTextAlign));
		setImport('FlxAxes', funkin.utils.MacroUtil.buildAbstract(flixel.util.FlxAxes));
		setImport("FlxKey", funkin.utils.MacroUtil.buildAbstract(flixel.input.keyboard.FlxKey));
		setImport('BlendMode', funkin.utils.MacroUtil.buildAbstract(openfl.display.BlendMode));
	}
}

@:access(insanity.backend.Parser)
@:access(insanity.backend.Interp)
class FunkinImportModule extends insanity.ImportModule implements IFunkinModule
{
	public var hash:String;
	
	public override function parse(string:String):Array<ModuleDecl>
	{
		hash = haxe.crypto.Sha256.encode(string);
		
		return super.parse(string);
	}
	
	public override dynamic function onProgramError(e:haxe.Exception):Void
	{
		FunkinScript.log(Std.string(e), interp.posInfos(), ERROR);
	}
	public override dynamic function onParsingError(e:haxe.Exception):Void
	{
		FunkinScript.log(Std.string(e), cast {fileName: name, lineNumber: parser.line}, ERROR);
	}
}

interface IFunkinModule
{
	public var hash:String;
}