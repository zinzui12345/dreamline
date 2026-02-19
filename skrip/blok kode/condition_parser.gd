extends Node
class_name ConditionParser

var tokens : Array
var current : int = 0

# =============================
# ENTRY POINT
# =============================
func parse(text : String):
	tokens = tokenize(text)
	current = 0
	return parse_or()


# =============================
# TOKENIZER
# =============================
func tokenize(text : String) -> Array:
	var regex = RegEx.new()
	regex.compile(r"\s*(>=|<=|==|!=|and|or|not|[()*/+\-<>]|[A-Za-z_][A-Za-z0-9_]*|\d+(\.\d+)?)")
	
	var result = []
	for m in regex.search_all(text):
		result.append(m.get_string().strip_edges())
	
	return result


func peek():
	if current < tokens.size():
		return tokens[current]
	return null


func advance():
	var t = peek()
	current += 1
	return t


func is_match(value):
	if peek() == value:
		advance()
		return true
	return false


# =============================
# PARSER LEVELS
# =============================

func parse_or():
	var expr = parse_and()
	while is_match("or"):
		expr = {
			"type": "or",
			"left": expr,
			"right": parse_and()
		}
	return expr


func parse_and():
	var expr = parse_not()
	while is_match("and"):
		expr = {
			"type": "and",
			"left": expr,
			"right": parse_not()
		}
	return expr


func parse_not():
	if is_match("not"):
		return {
			"type": "not",
			"value": parse_not()
		}
	return parse_comparison()


func parse_comparison():
	var expr = parse_expression()
	
	var ops = [">", "<", ">=", "<=", "==", "!="]
	if peek() in ops:
		var op = advance()
		return {
			"type": "compare",
			"operator": op,
			"left": expr,
			"right": parse_expression()
		}
	
	return expr


func parse_expression():
	var expr = parse_term()
	
	while peek() in ["+", "-"]:
		var op = advance()
		expr = {
			"type": "arithmetic",
			"operator": op,
			"left": expr,
			"right": parse_term()
		}
	
	return expr


func parse_term():
	var expr = parse_factor()
	
	while peek() in ["*", "/"]:
		var op = advance()
		expr = {
			"type": "arithmetic",
			"operator": op,
			"left": expr,
			"right": parse_factor()
		}
	
	return expr


func parse_factor():
	var token = peek()
	
	if is_match("("):
		var expr = parse_or()
		is_match(")")
		return expr
	
	advance()
	
	if token.is_valid_float():
		return {
			"type": "number",
			"value": float(token)
		}
	
	return {
		"type": "identifier",
		"value": token
	}
