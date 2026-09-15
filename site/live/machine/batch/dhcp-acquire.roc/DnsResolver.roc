# DnsResolver -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CCE
import Cce
import Ethernet
import Hamt
import Maybe
import Udp

DnsResolver :: [].{
	DnsRecord : [DnsA(List(I64)), DnsCname(Str), DnsTxt(Str)]
	DnsEntry : { name : Str, dns_rec : DnsResolver.DnsRecord, ttl : I64, created : I64 }
	DnsCache : { entries : Hamt.HamtMap(DnsResolver.DnsEntry), count : I64 }
	HostEntry : { hostname : Str, ip : List(I64) }
	HostTable : { hosts : List(DnsResolver.HostEntry), count : I64 }
	DnsResolver : { cache : DnsResolver.DnsCache, hosts : DnsResolver.HostTable }
	DnsAnswer : { rtype : I64, ttl : I64, rdata : List(I64) }
	DnsResponse : { tx_id : I64, flags : I64, answer_count : I64, answers : List(DnsResolver.DnsAnswer), valid : Bool }

	dns_cache_empty : DnsResolver.DnsCache
	dns_cache_empty = { entries: Hamt.hamt_empty, count: 0 }

	dns_cache_put : DnsResolver.DnsCache, Str, DnsResolver.DnsRecord, I64, I64 -> DnsResolver.DnsCache
	dns_cache_put = |cache, name, rec, ttl, now| ({
		entry = { name: name, dns_rec: rec, ttl: ttl, created: now }
		had = Hamt.hamt_contains(cache.entries, name)
		{ entries: Hamt.hamt_set(cache.entries, name, entry), count: (if had { cache.count } else { (cache.count + 1) }) }
	})

	dns_cache_lookup : DnsResolver.DnsCache, Str, I64 -> Maybe.Maybe(DnsResolver.DnsRecord)
	dns_cache_lookup = |cache, name, now| ({
		found = Hamt.hamt_get(cache.entries, name)
		(match found {
			None => None
			Just(entry) => (if ((now - entry.created) > entry.ttl) { None } else { Just(entry.dns_rec) })
		})
	})

	dns_cache_remove : DnsResolver.DnsCache, Str -> DnsResolver.DnsCache
	dns_cache_remove = |cache, name| (if Hamt.hamt_contains(cache.entries, name) { { entries: Hamt.hamt_remove(cache.entries, name), count: (cache.count - 1) } } else { cache })

	dns_cache_count : DnsResolver.DnsCache -> I64
	dns_cache_count = |cache| cache.count

	host_table_empty : DnsResolver.HostTable
	host_table_empty = { hosts: [], count: 0 }

	host_table_add : DnsResolver.HostTable, Str, List(I64) -> DnsResolver.HostTable
	host_table_add = |ht, name, ip| ({
		entry = { hostname: name, ip: ip }
		{ hosts: List.append(ht.hosts, entry), count: (ht.count + 1) }
	})

	host_table_lookup : DnsResolver.HostTable, Str -> Maybe.Maybe(List(I64))
	host_table_lookup = |ht, name| host_lookup_loop(ht.hosts, name, 0, ht.count)

	host_lookup_loop : List(DnsResolver.HostEntry), Str, I64, I64 -> Maybe.Maybe(List(I64))
	host_lookup_loop = |hosts, name, i, len| (if (i >= len) { None } else { ({
		h = (List.get(hosts, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (h.hostname == name) { Just(h.ip) } else { host_lookup_loop(hosts, name, (i + 1), len) })
	}) })

	resolver_new : DnsResolver.HostTable -> DnsResolver.DnsResolver
	resolver_new = |ht| { cache: dns_cache_empty, hosts: ht }

	resolve : DnsResolver.DnsResolver, Str, I64 -> Maybe.Maybe(List(I64))
	resolve = |r, name, now| ({
		host_result = host_table_lookup(r.hosts, name)
		(match host_result {
			Just(ip) => Just(ip)
			None => ({
				cache_result = dns_cache_lookup(r.cache, name, now)
				(match cache_result {
					Just(rec) => (match rec {
						DnsA(ip) => Just(ip)
						_ => None
					})
					None => None
				})
			})
		})
	})

	resolver_cache_result : DnsResolver.DnsResolver, Str, List(I64), I64, I64 -> DnsResolver.DnsResolver
	resolver_cache_result = |r, name, ip, ttl, now| ({
		new_cache = dns_cache_put(r.cache, name, DnsA(ip), ttl, now)
		{ cache: new_cache, hosts: r.hosts }
	})

	format_dns_record : DnsResolver.DnsRecord -> Str
	format_dns_record = |rec| (match rec {
		DnsA(ip) => format_ip(ip)
		DnsCname(name) => Str.concat("CNAME ", name)
		DnsTxt(txt) => Str.concat("TXT ", txt)
	})

	format_ip : List(I64) -> Str
	format_ip = |ip| (if (U64.to_i64_wrap(List.len(ip)) < 4) { "?" } else { Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(Str.concat(I64.to_str((List.get(ip, I64.to_u64_wrap(0)) ?? crash("list-at out of range"))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(1)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(2)) ?? crash("list-at out of range")))), "."), I64.to_str((List.get(ip, I64.to_u64_wrap(3)) ?? crash("list-at out of range")))) })

	dns_port : I64
	dns_port = 53

	dns_type_a : I64
	dns_type_a = 1

	dns_type_cname : I64
	dns_type_cname = 5

	dns_type_txt : I64
	dns_type_txt = 16

	dns_class_in : I64
	dns_class_in = 1

	dns_flags_query_rd : I64
	dns_flags_query_rd = 256

	dns_header_size : I64
	dns_header_size = 12

	dns_encode_name : Str -> List(I64)
	dns_encode_name = |name| dns_encode_labels(name, 0, Cce.length(name), [])

	dns_encode_labels : Str, I64, I64, List(I64) -> List(I64)
	dns_encode_labels = |name, start, len, acc| (if (start >= len) { List.concat(acc, [0]) } else { ({
		dot_pos = dns_find_dot(name, start, len)
		label_len = (dot_pos - start)
		label_bytes = dns_extract_label(name, start, dot_pos, [])
		next = (if (dot_pos < len) { (dot_pos + 1) } else { dot_pos })
		dns_encode_labels(name, next, len, List.concat(List.concat(acc, [label_len]), label_bytes))
	}) })

	dns_find_dot : Str, I64, I64 -> I64
	dns_find_dot = |name, i, len| (if (i >= len) { len } else { (if (Cce.at_or_crash(name, i) == Cce.at_or_crash(".", 0)) { i } else { dns_find_dot(name, (i + 1), len) }) })

	dns_extract_label : Str, I64, I64, List(I64) -> List(I64)
	dns_extract_label = |name, i, stop, acc| (if (i >= stop) { acc } else { dns_extract_label(name, (i + 1), stop, List.append(acc, CCE.to_unicode(Cce.at_or_crash(name, i)))) })

	dns_build_query : I64, Str, I64 -> List(I64)
	dns_build_query = |tx_id, name, qtype| ({
		header = List.concat(List.concat(List.concat(List.concat(List.concat(Ethernet.write_be16(tx_id), Ethernet.write_be16(dns_flags_query_rd)), Ethernet.write_be16(1)), Ethernet.write_be16(0)), Ethernet.write_be16(0)), Ethernet.write_be16(0))
		qname = dns_encode_name(name)
		question = List.concat(List.concat(qname, Ethernet.write_be16(qtype)), Ethernet.write_be16(dns_class_in))
		List.concat(header, question)
	})

	dns_build_a_query : I64, Str -> List(I64)
	dns_build_a_query = |tx_id, name| dns_build_query(tx_id, name, dns_type_a)

	dns_parse_response : List(I64) -> DnsResolver.DnsResponse
	dns_parse_response = |data| ({
		dlen = U64.to_i64_wrap(List.len(data))
		(if (dlen < dns_header_size) { { tx_id: 0, flags: 0, answer_count: 0, answers: [], valid: False } } else { ({
			tx_id = Ethernet.read_be16(data, 0)
			flags = Ethernet.read_be16(data, 2)
			qdcount = Ethernet.read_be16(data, 4)
			ancount = Ethernet.read_be16(data, 6)
			q_end = dns_skip_questions(data, dns_header_size, qdcount)
			answers = dns_parse_answers(data, q_end, ancount, [])
			{ tx_id: tx_id, flags: flags, answer_count: U64.to_i64_wrap(List.len(answers)), answers: answers, valid: True }
		}) })
	})

	dns_skip_questions : List(I64), I64, I64 -> I64
	dns_skip_questions = |data, off, count| (if (count <= 0) { off } else { ({
		name_end = dns_skip_name(data, off)
		dns_skip_questions(data, (name_end + 4), (count - 1))
	}) })

	dns_skip_name : List(I64), I64 -> I64
	dns_skip_name = |data, off| (if (off >= U64.to_i64_wrap(List.len(data))) { off } else { ({
		b = (List.get(data, I64.to_u64_wrap(off)) ?? crash("list-at out of range"))
		(if (b == 0) { (off + 1) } else { (if (I64.bitwise_and(b, 192) == 192) { (off + 2) } else { dns_skip_name(data, ((off + 1) + b)) }) })
	}) })

	dns_parse_answers : List(I64), I64, I64, List(DnsResolver.DnsAnswer) -> List(DnsResolver.DnsAnswer)
	dns_parse_answers = |data, off, count, acc| (if (count <= 0) { acc } else { (if ((off + 10) > U64.to_i64_wrap(List.len(data))) { acc } else { ({
		name_end = dns_skip_name(data, off)
		rtype = Ethernet.read_be16(data, name_end)
		ttl = dns_read_be32(data, (name_end + 4))
		rdlen = Ethernet.read_be16(data, (name_end + 8))
		rdata = dns_extract_rdata(data, (name_end + 10), rdlen, [])
		answer = { rtype: rtype, ttl: ttl, rdata: rdata }
		dns_parse_answers(data, ((name_end + 10) + rdlen), (count - 1), List.append(acc, answer))
	}) }) })

	dns_read_be32 : List(I64), I64 -> I64
	dns_read_be32 = |data, off| (if ((off + 4) > U64.to_i64_wrap(List.len(data))) { 0 } else { ({
		b0 = I64.shl_wrap((List.get(data, I64.to_u64_wrap(off)) ?? crash("list-at out of range")), I64.to_u8_wrap(24))
		b1 = I64.shl_wrap((List.get(data, I64.to_u64_wrap((off + 1))) ?? crash("list-at out of range")), I64.to_u8_wrap(16))
		b2 = I64.shl_wrap((List.get(data, I64.to_u64_wrap((off + 2))) ?? crash("list-at out of range")), I64.to_u8_wrap(8))
		b3 = (List.get(data, I64.to_u64_wrap((off + 3))) ?? crash("list-at out of range"))
		I64.bitwise_or(b0, I64.bitwise_or(b1, I64.bitwise_or(b2, b3)))
	}) })

	dns_extract_rdata : List(I64), I64, I64, List(I64) -> List(I64)
	dns_extract_rdata = |data, off, len, acc| (if (len <= 0) { acc } else { (if (off >= U64.to_i64_wrap(List.len(data))) { acc } else { dns_extract_rdata(data, (off + 1), (len - 1), List.append(acc, (List.get(data, I64.to_u64_wrap(off)) ?? crash("list-at out of range")))) }) })

	dns_first_a_record : DnsResolver.DnsResponse -> Maybe.Maybe(List(I64))
	dns_first_a_record = |resp| (if (resp.valid == False) { None } else { dns_find_a_in_answers(resp.answers, 0, U64.to_i64_wrap(List.len(resp.answers))) })

	dns_find_a_in_answers : List(DnsResolver.DnsAnswer), I64, I64 -> Maybe.Maybe(List(I64))
	dns_find_a_in_answers = |answers, i, len| (if (i >= len) { None } else { ({
		a = (List.get(answers, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (a.rtype == dns_type_a) { (if (U64.to_i64_wrap(List.len(a.rdata)) == 4) { Just(a.rdata) } else { dns_find_a_in_answers(answers, (i + 1), len) }) } else { dns_find_a_in_answers(answers, (i + 1), len) })
	}) })

	dns_first_a_ttl : DnsResolver.DnsResponse -> I64
	dns_first_a_ttl = |resp| dns_find_a_ttl(resp.answers, 0, U64.to_i64_wrap(List.len(resp.answers)))

	dns_find_a_ttl : List(DnsResolver.DnsAnswer), I64, I64 -> I64
	dns_find_a_ttl = |answers, i, len| (if (i >= len) { 0 } else { ({
		a = (List.get(answers, I64.to_u64_wrap(i)) ?? crash("list-at out of range"))
		(if (a.rtype == dns_type_a) { a.ttl } else { dns_find_a_ttl(answers, (i + 1), len) })
	}) })

	dns_build_udp_query : List(I64), List(I64), I64, Str -> List(I64)
	dns_build_udp_query = |src_ip, dns_ip, tx_id, name| ({
		query = dns_build_a_query(tx_id, name)
		Udp.udp_build_ip_packet(src_ip, dns_ip, 1024, dns_port, query)
	})

	eq_DnsRecord : DnsResolver.DnsRecord, DnsResolver.DnsRecord -> Bool
	eq_DnsRecord = |ex, ey| (match ex {
		DnsA(exf0) => (match ey {
			DnsA(eyf0) => (exf0 == eyf0)
			_ => False
		})
		DnsCname(exf0) => (match ey {
			DnsCname(eyf0) => (exf0 == eyf0)
			_ => False
		})
		DnsTxt(exf0) => (match ey {
			DnsTxt(eyf0) => (exf0 == eyf0)
			_ => False
		})
	})
}
