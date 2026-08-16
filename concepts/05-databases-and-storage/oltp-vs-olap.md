# OLTP vs OLAP / Data Warehouse

---

Two very different jobs a "database" does: **running the app** (many tiny reads/writes) vs **analyzing the business** (few huge scans). You don't force both onto one store — **OLTP** powers the live app, **OLAP** (a **data warehouse**) powers reports and dashboards. Builds on [database fundamentals](./databases-fundamentals.md); OLAP stores are usually [columnar](../04-apis/serialization-formats.md) and often live on [object storage](./object-blob-storage.md).

## 1. The two workloads

| | **OLTP** (Online Transaction Processing) | **OLAP** (Online Analytical Processing) |
|---|---|---|
| Purpose | run the application | analyze / report on data |
| Query shape | many **small** reads/writes by key | few **huge aggregations** over columns |
| Example | "insert this order", "get user 42" | "total revenue per region per month" |
| Rows touched | one or a few | millions–billions |
| Writes | constant, real-time | bulk **loads** (batch/stream), rarely updated |
| Data | current, normalized | historical, denormalized |
| Latency target | milliseconds | seconds–minutes is fine |
| Example tech | PostgreSQL, MySQL, DynamoDB | Snowflake, BigQuery, Redshift |

**One line:** OLTP = **write-heavy, key-based, current** state; OLAP = **read-heavy, scan-based, historical** analytics.

## 2. Why not run analytics on the OLTP database?

- A `SUM(revenue) GROUP BY region` scans **millions of rows** — it hammers the DB's cache and locks, **starving the live app** it's supposed to serve.
- OLTP is **row-oriented** (whole row together, great for "get one order"); analytics reads a **few columns across all rows**, which row storage does slowly.
- So you **separate** them: keep OLTP fast for users, copy the data into an OLAP store shaped for scans.

## 3. Row vs columnar storage (the core reason OLAP is fast)

- **Row storage (OLTP)** keeps a whole record contiguously → cheap to read/write one row.
- **Columnar storage (OLAP)** keeps each **column** contiguously → an aggregation reads **only the columns it needs**, skipping the rest, and similar values compress hugely.
- That's why warehouses use columnar formats ([Parquet](../04-apis/serialization-formats.md), ORC) — a `SUM(revenue)` touches one column, not entire rows.

## 4. Getting data from OLTP → OLAP (ETL / ELT)

The warehouse is a **derived copy**; a pipeline moves data in:

- **ETL** — **Extract** from sources, **Transform** (clean/join/aggregate), **Load** into the warehouse. Classic, transform before load.
- **ELT** — Load raw first, **Transform inside** the warehouse (modern, leverages cheap warehouse compute; e.g. dbt).
- Runs as a **batch** (nightly) or **streaming** (near-real-time via [CDC](./sharding-and-partitioning.md) / Kafka), so the warehouse is **eventually consistent** with OLTP.
- A **data lake** (raw files on object storage) often sits *before* the warehouse; **lakehouse** (Databricks, Iceberg) merges the two.

## 5. Real-world technologies

| Category | Systems |
|---|---|
| **OLTP databases** | PostgreSQL, MySQL, Oracle, SQL Server; DynamoDB, MongoDB |
| **OLAP / warehouses** | **Snowflake**, Google **BigQuery**, Amazon **Redshift**, ClickHouse, **Apache Druid** |
| **Data lake / lakehouse** | S3 + Athena, Databricks, Apache Iceberg / Delta Lake |
| **ETL / ELT tools** | dbt, Airflow, Fivetran, Spark |

## 6. When to use what

- **OLTP** → the system of record behind your app: user actions, orders, payments — anything needing fast, consistent single-row reads/writes.
- **OLAP / warehouse** → BI dashboards, reporting, ad-hoc analytics, ML feature pipelines over large history.
- **Both, connected by a pipeline** is the normal shape at any real company — don't pick one; pick the right store per workload and sync between them.
- **HTAP** (e.g. TiDB, SingleStore) tries to serve both from one engine — useful when you can't afford the pipeline lag, but a niche choice.

## 7. One-Paragraph Summary (for quick revision)

**OLTP** and **OLAP** are two workloads you should *not* force onto one store. **OLTP** (PostgreSQL, MySQL, DynamoDB) runs the application: many **small, key-based reads/writes** on **current** data with **millisecond** latency, using **row** storage. **OLAP** — a **data warehouse** (Snowflake, BigQuery, Redshift) — answers analytics: **few, huge aggregations** scanning **millions of historical rows**, where seconds are fine, using **columnar** storage (Parquet/ORC) so a query reads only the needed columns and compresses well. Running analytics directly on OLTP would **starve the live app**, so data is copied over by an **ETL/ELT pipeline** (batch nightly or streaming via CDC/Kafka), making the warehouse an **eventually-consistent derived copy**; a **data lake / lakehouse** often sits in between. Rule of thumb: **OLTP for the app, OLAP for the questions about the app** — connected by a pipeline, not merged (except niche **HTAP** engines).
