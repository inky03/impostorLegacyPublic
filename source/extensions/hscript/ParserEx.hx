package extensions.hscript;

/**
 * Extended to read the `public` keyword.
 */
class ParserEx extends insanity.backend.Parser
{
	override function parseStructure(id, ?type)
	{
		return switch (id)
		{
			case "public":
				final e = parseExpr();
				
				switch (e.e)
				{
					case EVar(name, _, _, _, _, _), EFunction(_, _, name, _, _) if (name != null):
						mk(EMeta(':sharable', [], e), tokenMin, tokenMax);
						
					default:
						unexpected(TId(id));
				}
				
			default:
				super.parseStructure(id, type);
		}
	}
}
