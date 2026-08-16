# Serialization Formats — JSON / Protobuf / Avro

---

**Serialization** turns an in-memory object into bytes for the wire or disk; **deserialization** rebuilds it on the other side. The format you pick sets **payload size, encode/decode speed, and how safely schemas evolve** — a real architectural lever. Companion to [gRPC](./grpc.md) (protobuf) and [Kafka](../07-messaging-and-events/apache-kafka.md) (Avro); the transport is usually [HTTP](./http.md).

## 1. Text vs binary

- **Text formats** (JSON, XML) — human-readable, self-describing, debuggable with `curl`; but **verbose** (field names repeated on every record) and **slow** to parse.
- **Binary formats** (Protobuf, Avro, Thrift) — compact and fast, but **opaque** (need the schema to read). Trade debuggability for size + speed.

Every field name and whitespace in JSON is bytes you pay for on **every message** — at millions of messages/sec (Kafka, service mesh) that dominates bandwidth and CPU, which is why internal systems go binary.

## 2. The three formats

| | **JSON** | **Protobuf** | **Avro** |
|---|---|---|---|
| Encoding | text | binary | binary |
| Schema | none (implicit) | **required** (`.proto`) | **required** (JSON schema) |
| Schema travels with data | n/a | no (compiled into code) | **can** (embedded, or via registry) |
| Size | large | **small** | **small** |
| Encode/decode speed | slow | **fast** | **fast** |
| Human-readable | ✅ | ❌ | ❌ |
| Typical home | public/web APIs | gRPC, microservices | Kafka / big-data pipelines |

**How binary saves space:** Protobuf tags each field with an **integer number** (from the `.proto`) instead of its name, and skips absent fields. Avro drops field identifiers **entirely** — it writes values in schema order, so the reader must have the schema to decode. Fewer bytes, but no self-description.

## 3. Schema & evolution (the real interview point)

Schemas change over time; the format decides whether old and new code interoperate:

- **Backward compatible** — new code reads **old** data. **Forward compatible** — old code reads **new** data. You usually want both so producers and consumers can deploy independently.
- **JSON** — schemaless, so "anything goes": add a field and old readers ignore it, but there's **no enforcement** — a typo or type change fails at runtime.
- **Protobuf** — **field numbers** are the contract. **Never reuse/renumber a tag**; add new fields with new numbers, keep old ones `optional`. Unknown fields are preserved/ignored → clean forward + backward compatibility.
- **Avro** — reader and writer schemas are **resolved** at decode time; add fields **with defaults** to stay compatible. Because the schema is separate from the data, Kafka stores it in a **Schema Registry** (see below) rather than in every message.

**Example — the same `User`, then adding an `email` field:**

**JSON** — data only, no schema; just add the key (nothing enforces it):

```jsonc
{ "id": 123, "name": "Ada" }
{ "id": 123, "name": "Ada", "email": "ada@x.com" }   // old readers ignore "email"
```

**Protobuf** — the `.proto` schema; the new field gets a **new number** (tags 1, 2 unchanged):

```proto
message User {
  int32  id    = 1;
  string name  = 2;
  string email = 3;   // added later — old code skips unknown tag 3
}
```

**Avro** — the schema (`.avsc`) is separate from the data; the new field needs a **default** so old data still decodes. The record itself is stored **binary** on the wire, but its logical value is:

```jsonc
// schema — user.avsc
{ "type": "record", "name": "User", "fields": [
  { "name": "id",    "type": "int" },
  { "name": "name",  "type": "string" },
  { "name": "email", "type": "string", "default": "" }
]}

// data — the record (binary on the wire; shown here as its logical value)
{ "id": 123, "name": "Ada", "email": "ada@x.com" }
```

## 4. Real-world technologies

| Technology | Format | Notes |
|---|---|---|
| **REST / web APIs** | JSON | default for public, browser-facing APIs |
| **gRPC** | Protobuf | typed contract + HTTP/2, service-to-service |
| **Apache Kafka + Confluent Schema Registry** | Avro (also Protobuf/JSON) | registry stores schemas by ID; messages carry only the ID |
| **Apache Thrift** | binary | Facebook's protobuf-equivalent RPC + serialization |
| **MessagePack / BSON** | binary | "binary JSON" — compact, schemaless (MongoDB uses BSON) |

## 5. When to use what

- **JSON** → public APIs, browser clients, low-volume or debug-first paths — readability wins.
- **Protobuf** → internal gRPC microservices needing a **typed contract**, low latency, and small payloads.
- **Avro** → **Kafka / data lakes** with a Schema Registry, where records are schema-heavy and evolve often, and you want the schema decoupled from the payload.
- **Parquet** → **analytics / OLAP at rest** (data lakes, S3, Spark, query engines). Unlike the three above — which are **row-oriented** (whole record together, for messaging/transport) — Parquet is **columnar**: it stores each column contiguously, so a query reads only the columns it needs and compresses far better (similar values sit together). Use it for large, read-heavy analytical tables; **not** for row-at-a-time messaging (that's Avro's job). Rule of thumb: **Avro to move rows, Parquet to store columns for scans.**

## 6. One-Paragraph Summary (for quick revision)

**Serialization** encodes objects to bytes; the format trades **readability against size and speed**. **JSON** is text — self-describing and debuggable but verbose and slow, the right default for **public/web APIs**. **Protobuf** and **Avro** are **binary** — compact and fast, but need the schema to decode. Protobuf uses **integer field numbers** as its contract (never reuse a tag; add new optional fields) and powers **gRPC**; Avro writes values in schema order with no field IDs, resolves reader-vs-writer schemas at decode time, and pairs with a **Schema Registry** in **Kafka** pipelines. The interview crux is **schema evolution** — pick binary + a schema when you need compact, high-throughput messages and independently-deployable producers/consumers (backward *and* forward compatible); pick JSON when a human needs to read it.
