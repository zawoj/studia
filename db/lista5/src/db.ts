import { Database } from "https://deno.land/x/mongo@v0.31.2/mod.ts";
import { MongoClient } from "./deps.ts";

const uri = "mongodb://root:example@localhost:27017";
const client = new MongoClient();

try {
  await client.connect(uri);

} catch (err) {
  console.error("Error connecting to MongoDB:", err);
}

const db: Database = client.database("jobs");

export default db;
