# DnsResolver -- emitted from Codex by rocemit (rust-codex-compiler). Do not edit.
import CceText
import Hamt

DnsResolver :: [].{
	DnsRecord : [DnsA(List(I64)), DnsCname(CceText), DnsTxt(CceText)]
	DnsEntry := { name : CceText, dns_rec : DnsResolver.DnsRecord, ttl : I64, created : I64 }.{
		is_eq : DnsResolver.DnsEntry, DnsResolver.DnsEntry -> Bool
		is_eq = |a, b| eq_DnsEntry(a, b)
	}
	DnsCache := { entries : Hamt.HamtMap(DnsResolver.DnsEntry), count : I64 }.{
		is_eq : DnsResolver.DnsCache, DnsResolver.DnsCache -> Bool
		is_eq = |a, b| eq_DnsCache(a, b)
	}
	HostEntry := { hostname : CceText, ip : List(I64) }.{
		is_eq : DnsResolver.HostEntry, DnsResolver.HostEntry -> Bool
		is_eq = |a, b| eq_HostEntry(a, b)
	}
	HostTable := { hosts : List(DnsResolver.HostEntry), count : I64 }.{
		is_eq : DnsResolver.HostTable, DnsResolver.HostTable -> Bool
		is_eq = |a, b| eq_HostTable(a, b)
	}
	DnsResolver := { cache : DnsResolver.DnsCache, hosts : DnsResolver.HostTable }.{
		is_eq : DnsResolver.DnsResolver, DnsResolver.DnsResolver -> Bool
		is_eq = |a, b| eq_DnsResolver(a, b)
	}
	DnsAnswer := { rtype : I64, ttl : I64, rdata : List(I64) }.{
		is_eq : DnsResolver.DnsAnswer, DnsResolver.DnsAnswer -> Bool
		is_eq = |a, b| eq_DnsAnswer(a, b)
	}
	DnsResponse := { tx_id : I64, flags : I64, answer_count : I64, answers : List(DnsResolver.DnsAnswer), valid : Bool }.{
		is_eq : DnsResolver.DnsResponse, DnsResolver.DnsResponse -> Bool
		is_eq = |a, b| eq_DnsResponse(a, b)
	}

	dns_cache_empty : DnsResolver.DnsCache
	dns_cache_empty = DnsResolver.DnsCache.{ entries: Hamt.hamt_empty, count: 0 }

	host_table_empty : DnsResolver.HostTable
	host_table_empty = DnsResolver.HostTable.{ hosts: [], count: 0 }

	host_table_add : DnsResolver.HostTable, CceText, List(I64) -> DnsResolver.HostTable
	host_table_add = |ht, name, ip| ({
		entry = DnsResolver.HostEntry.{ hostname: name, ip: ip }
		DnsResolver.HostTable.{ hosts: List.append(ht.hosts, entry), count: (ht.count + 1) }
	})

	resolver_new : DnsResolver.HostTable -> DnsResolver.DnsResolver
	resolver_new = |ht| DnsResolver.DnsResolver.{ cache: dns_cache_empty, hosts: ht }

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

	eq_DnsEntry : DnsResolver.DnsEntry, DnsResolver.DnsEntry -> Bool
	eq_DnsEntry = |ex, ey| ((((ex.name == ey.name) and eq_DnsRecord(ex.dns_rec, ey.dns_rec)) and (ex.ttl == ey.ttl)) and (ex.created == ey.created))

	eq_DnsCache : DnsResolver.DnsCache, DnsResolver.DnsCache -> Bool
	eq_DnsCache = |ex, ey| ((ex.entries == ey.entries) and (ex.count == ey.count))

	eq_HostEntry : DnsResolver.HostEntry, DnsResolver.HostEntry -> Bool
	eq_HostEntry = |ex, ey| ((ex.hostname == ey.hostname) and (ex.ip == ey.ip))

	eq_HostTable : DnsResolver.HostTable, DnsResolver.HostTable -> Bool
	eq_HostTable = |ex, ey| ((ex.hosts == ey.hosts) and (ex.count == ey.count))

	eq_DnsResolver : DnsResolver.DnsResolver, DnsResolver.DnsResolver -> Bool
	eq_DnsResolver = |ex, ey| (eq_DnsCache(ex.cache, ey.cache) and eq_HostTable(ex.hosts, ey.hosts))

	eq_DnsAnswer : DnsResolver.DnsAnswer, DnsResolver.DnsAnswer -> Bool
	eq_DnsAnswer = |ex, ey| (((ex.rtype == ey.rtype) and (ex.ttl == ey.ttl)) and (ex.rdata == ey.rdata))

	eq_DnsResponse : DnsResolver.DnsResponse, DnsResolver.DnsResponse -> Bool
	eq_DnsResponse = |ex, ey| (((((ex.tx_id == ey.tx_id) and (ex.flags == ey.flags)) and (ex.answer_count == ey.answer_count)) and (ex.answers == ey.answers)) and (ex.valid == ey.valid))
}
