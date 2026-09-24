# Hmac -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import ListUtils
import Sha256
import Text

Hmac :: [].{

	hmac_sha256 : List(I64), List(I64) -> List(I64)
	hmac_sha256 = |key, msg| ({
		k_prime = hmac_normalize_key(key)
		ipad_key = xor_bytes(k_prime, repeat_byte(54, 64), 0, 64, [])
		opad_key = xor_bytes(k_prime, repeat_byte(92, 64), 0, 64, [])
		inner_hash = Sha256.sha256(List.concat(ipad_key, msg))
		inner_bytes = hash_words_to_bytes(inner_hash)
		Sha256.sha256(List.concat(opad_key, inner_bytes))
	})

	hmac_normalize_key : List(I64) -> List(I64)
	hmac_normalize_key = |key| (if (U64.to_i64_wrap(List.len(key)) > 64) { pad_to_64(hash_words_to_bytes(Sha256.sha256(key))) } else { (if (U64.to_i64_wrap(List.len(key)) == 64) { key } else { pad_to_64(ListUtils.map_list(lam_0, key)) }) })

	pad_to_64 : List(I64) -> List(I64)
	pad_to_64 = |bs| (if (U64.to_i64_wrap(List.len(bs)) >= 64) { bs } else { pad_to_64(List.append(bs, 0)) })

	xor_bytes : List(I64), List(I64), I64, I64, List(I64) -> List(I64)
	xor_bytes = |a, b, i, len, acc| (if (i == len) { acc } else { xor_bytes(a, b, (i + 1), len, List.append(acc, I64.bitwise_xor((List.get(a, I64.to_u64_wrap(i)) ?? crash("list-at out of range")), (List.get(b, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))))) })

	repeat_byte : I64, I64 -> List(I64)
	repeat_byte = |val, n| repeat_byte_loop(val, n, [])

	repeat_byte_loop : I64, I64, List(I64) -> List(I64)
	repeat_byte_loop = |val, n, acc| (if (n <= 0) { acc } else { repeat_byte_loop(val, (n - 1), List.append(acc, val)) })

	hmac_sha256_hex : List(I64), List(I64) -> Text
	hmac_sha256_hex = |key, msg| Sha256.sha256_to_hex(hmac_sha256(key, msg))

	hash_words_to_bytes : List(I64) -> List(I64)
	hash_words_to_bytes = |ws| hmac_hw2b(ws, 0, U64.to_i64_wrap(List.len(ws)), [])

	hmac_hw2b : List(I64), I64, I64, List(I64) -> List(I64)
	hmac_hw2b = |ws, i, len, acc| (if (i == len) { acc } else { ({
		w = (List.get(ws, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		hmac_hw2b(ws, (i + 1), len, List.concat(acc, [I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(24)), 255), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(16)), 255), I64.bitwise_and(I64.shr_zf_wrap(w, I64.to_u8_wrap(8)), 255), I64.bitwise_and(w, 255)]))
	}) })

	lam_0 : I64 -> I64
	lam_0 = |b| b
}
