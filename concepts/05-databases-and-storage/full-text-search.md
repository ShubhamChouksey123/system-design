# Full-Text Search / Inverted Index

---

How you search **words inside documents** at scale — the tech behind a search bar over products, logs, emails, or articles. A normal database can't do this efficiently; the trick is a data structure called the **inverted index**. Related: [database fundamentals](./databases-fundamentals.md) (B-tree indexes), and it's usually a **secondary store** synced from your primary DB.

## 1. Why not just use `SQL LIKE`?

`SELECT * FROM articles WHERE body LIKE '%database%'` looks fine but doesn't scale:

- **Full-table scan** — a leading-`%` wildcard can't use a B-tree index, so every row is read: O(n).
- **No relevance ranking** — you get matches, but not "best match first."
- **No language smarts** — "running" won't match "run"; "the" is treated like any word; no typo tolerance.

Full-text search engines fix all three with an inverted index + a scoring model.

## 2. The inverted index (the core idea)

A normal (**forward**) index maps *document → its words*. An **inverted index** flips it: *word → the list of documents that contain it* (called a **postings list**).

```
Docs:
  1: "the cat sat on the soft mat"
  2: "the dog ran fast in the park"
  3: "the cat and dog ran in the park"
  4: "cats love running and playing outside"
  5: "the happy dog sat near the cat"

Inverted index (after analysis → term → postings):
  cat  → [1, 3, 4, 5]
  dog  → [2, 3, 5]
  run  → [2, 3, 4]        (ran, running → run)
  sat  → [1, 5]
  park → [2, 3]
```

Now "find docs containing `dog`" is a **direct lookup** returning `[2, 3, 5]` — no scan. A boolean `cat AND sat` **intersects** their postings: `[1,3,4,5] ∩ [1,5] = [1, 5]`.

**What each postings entry stores** (per document that contains the term):

1. **Document ID** — which document has the term (what you intersect on).
2. **Term frequency (TF)** — how many times it appears in that doc → feeds **ranking**.
3. **Positions** — the word offsets of each occurrence → enables **phrase / proximity** search (e.g. the phrase `"cat sat"` needs `cat` *immediately before* `sat`).
4. **Character offsets** — start/end in the text → used to **highlight** the matched terms in results.
5. **Field** *(optional)* — which field it came from (title vs body) → lets ranking weight a title hit above a body hit.

## 3. How text becomes index terms (analysis)

Before indexing, each document runs through an **analysis pipeline** so searches match despite spelling/word-form differences:

| Step | What it does | Example |
|---|---|---|
| **Tokenize** | split text into words | `"Running fast!"` → `["Running", "fast"]` |
| **Normalize** | lowercase, strip punctuation/accents | `Running` → `running` |
| **Stopword removal** | drop noise words | remove `the`, `is`, `a` |
| **Stemming** | chop a word to its **root form** (fast, rule-based) | `running`, `ran` → `run` |
| **Lemmatization** | **dictionary** lookup for the true base form (smarter, slower) | `better` → `good` |

**Stemming vs lemmatization:** *stemming* crudely strips suffixes by rules — `running`/`ran` → `run` — and can be wrong (it may over-chop), but it's fast. *Lemmatization* uses a dictionary to find the real base word, so it handles irregular forms like `better` → `good` that stemming can't. The **same pipeline runs on the query**, so "Ran" finds documents indexed under "run."

## 4. How a lookup (query) works

Searching mirrors indexing: the query runs through the **same analysis pipeline**, then walks the index. For the query `"cat sat"`:

1. **Analyze the query** → terms `[cat, sat]` (tokenize → normalize → stopwords → stem), so it matches the form docs were indexed in.
2. **Look up each term's postings** — a direct lookup in the index: `cat → [1, 3, 4, 5]`, `sat → [1, 5]`. No table scan.
3. **Combine the lists** — `AND` **intersects** (`[1,3,4,5] ∩ [1,5] = [1, 5]`), `OR` **unions**. A **phrase** query `"cat sat"` goes further and checks **positions**: only **doc 1** has `cat` immediately before `sat` (doc 5 is "…sat near the cat" — wrong order), so the phrase returns just `[1]`.
4. **Score & rank** the surviving docs by relevance (below) — presence isn't enough.
5. **Return top-k** — with **highlights** (from stored character offsets) and **facets**.

**Ranking the matched docs:**

- **TF-IDF(Term Frequency-Inverse Document Frequency)** — a term matters more if it's **frequent in this doc** (TF) but **rare across all docs** (IDF). "database" in a short doc about databases ranks high; "the" ranks near zero.
- **BM25** — the modern default (Lucene/Elasticsearch); a refined TF-IDF that dampens very frequent terms and accounts for document length.
- Engines add **fuzzy matching** (typo tolerance), **phrase** and **prefix** queries, **facets**, and **highlighting**.

## 5. Optimizing the inverted index

Beyond the basic index, engines add layers to make lookups faster and fit more of the index in memory:

| Technique | What it does | Why it helps |
|---|---|---|
| **Bi-word (phrase) index** | index adjacent word **pairs** (`"new york"`) as a single term | a common **phrase** query becomes one lookup instead of positional intersection |
| **Tiered indexes** | split docs into quality/popularity tiers and keep the **top-*m* tier in memory** | most queries are served from the small hot tier; fall through to lower tiers only if too few hits |
| **Skip pointers** | shortcuts embedded in a postings list | let `AND` intersection **skip ahead**, merging long lists in sub-linear time |
| **Compression** | delta-encode doc IDs + variable-byte / PForDelta | postings shrink → more of the index fits in **RAM/cache**, less disk I/O |
| **Caching** | cache hot query results and hot terms' postings | repeat and popular queries return instantly |

## 6. Real-world technologies

| Technology | Notes |
|---|---|
| **Apache Lucene** | the core library most engines are built on |
| **Elasticsearch / OpenSearch** | distributed search on Lucene — the industry standard. Elasticsearch is by **Elastic**; **OpenSearch** is its Apache-2.0 fork started by AWS. Both are engines you self-host or run managed (e.g. **Amazon OpenSearch Service**, Elastic Cloud) |
| **Apache Solr** | older Lucene-based search server |
| **PostgreSQL full-text** (`tsvector`/`GIN`) | built into Postgres — fine for modest scale, no extra system |
| **Algolia / Typesense / Meilisearch** | hosted/lightweight, typo-tolerant, low-latency |

## 7. System-design considerations

- **Secondary store, not the source of truth.** Your primary DB owns the data; the search index is a **derived copy** kept in sync via **[CDC](../08-distributed-systems/single-point-of-failure.md)** / a queue → so it's **eventually consistent** (a new record is searchable seconds later, not instantly).
- **Sharded + replicated** — the index is split into [shards](./sharding-and-partitioning.md) across nodes (scatter-gather a query, merge results) and replicated for availability — exactly like a distributed DB.
- **Near-real-time** — indexing isn't instant; engines "refresh" on an interval (e.g. ~1 s in Elasticsearch).
- **Write cost** — indexing is heavier than a plain insert (analysis + index update), so it trades write throughput for fast, rich reads.
- **Managed vs self-hosted** — running a search cluster is real ops work (sharding, upgrades, capacity). Small teams / early startups should **defer it**: start with **Postgres full-text** or hosted turnkey search (**Algolia/Typesense**), and when a full engine is needed, use a **managed service** (**Amazon OpenSearch Service**, Elastic Cloud) instead of self-hosting. Self-host only when scale, cost, or deep customization demands it.

## 8. One-Paragraph Summary (for quick revision)

**Full-text search** finds words inside documents at scale, which a relational `LIKE '%…%'` can't do (it scans every row, can't rank, and ignores word forms). The core structure is the **inverted index**: *term → postings list of documents that contain it*, so a search is a **lookup + intersection** instead of a scan, with positions and term frequencies stored for phrase search and ranking. Documents (and queries) pass through an **analysis pipeline** — tokenize → normalize → remove stopwords → **stem** — so "ran" matches "run." Results are **matched** via postings then **ranked** by relevance with **TF-IDF** or, in practice, **BM25** (Lucene/Elasticsearch's default), plus fuzzy/phrase/prefix queries. Architecturally the index is a **sharded, replicated secondary store** synced from the primary DB (via CDC/queues), so it's **eventually consistent** and near-real-time. In practice: **Elasticsearch/OpenSearch** and **Solr** (on **Lucene**), **Postgres full-text** for modest scale, or hosted **Algolia/Typesense**.
