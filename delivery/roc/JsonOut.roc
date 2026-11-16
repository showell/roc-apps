## JSON built from whole values, the one way the solver's answers become
## bytes. Every string goes through one escape, and an object keeps its
## members in the order given: the page and the gold compare stops by their
## JSON text, whose key order is semantics.

JsonOut :: List(U8).{

	string : Str -> JsonOut
	string = |text| JsonOut.(escaped_onto([], text))

	int : I64 -> JsonOut
	int = |n| JsonOut.(n.to_str().to_utf8())

	## A float, in Roc's shortest form that reads back to the same bits.
	float : F64 -> JsonOut
	float = |x| {
		if !x.is_finite() {
			crash "JsonOut.float: JSON has no ${x.to_str()}"
		}
		JsonOut.(x.to_str().to_utf8())
	}

	array : List(JsonOut) -> JsonOut
	array = |items| {
		var $out = ['[']
		var $first = True
		for JsonOut.(bytes) in items {
			if !$first {
				$out = $out.append(',')
			}
			$out = $out.concat(bytes)
			$first = False
		}
		JsonOut.($out.append(']'))
	}

	ordered_object : List((Str, JsonOut)) -> JsonOut
	ordered_object = |members| {
		var $out = ['{']
		var $first = True
		for (key, JsonOut.(bytes)) in members {
			if !$first {
				$out = $out.append(',')
			}
			$out = escaped_onto($out, key).append(':').concat(bytes)
			$first = False
		}
		JsonOut.($out.append('}'))
	}

	to_bytes : JsonOut -> List(U8)
	to_bytes = |JsonOut.(bytes)| bytes
}

## `text` as a JSON string, after `out`: a quote, a backslash and a control
## byte escaped, every other byte (UTF-8 included) as it is.
escaped_onto : List(U8), Str -> List(U8)
escaped_onto = |out, text| {
	var $out = out.append('"')
	for b in text.to_utf8() {
		$out = if b == '"' or b == '\\' {
			$out.append('\\').append(b)
		} else if b < 0x20 {
			$out.concat("\\u00".to_utf8()).append(hex_digit(b // 16)).append(hex_digit(b % 16))
		} else {
			$out.append(b)
		}
	}
	$out.append('"')
}

hex_digit : U8 -> U8
hex_digit = |d|
	if d < 10 {
		'0' + d
	} else {
		'a' + d - 10
	}

expect JsonOut.string("a\"b\\c\n").to_bytes() == "\"a\\\"b\\\\c\\u000a\"".to_utf8()
expect {
	floats = JsonOut.array([JsonOut.float(1.5), JsonOut.float(3.0)])
	JsonOut.ordered_object([("b", JsonOut.int(-2)), ("a", floats)]).to_bytes() == "{\"b\":-2,\"a\":[1.5,3]}".to_utf8()
}
expect JsonOut.array([]).to_bytes() == "[]".to_utf8()
