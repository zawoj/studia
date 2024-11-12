import { Database } from "https://deno.land/x/mongo@v0.31.2/mod.ts";
import { MongoClient } from "./deps.ts";

const uri = "mongodb://root:example@localhost:27017"; // Replace with your MongoDB connection URI
const client = new MongoClient();

try {
  await client.connect(uri);
  console.log("Connected to MongoDB");

  // Create indexes for better performance
  const db: Database = client.database("jobs");
  
  await db.collection("locations").createIndexes([
    { key: { city: 1 } },
    { key: { country: 1 } }
  ]);

  await db.collection("organizations").createIndexes([
    { key: { name: 1 } },
    { key: { source: 1 } }
  ]);

  await db.collection("jobPositions").createIndexes([
    { key: { organizationId: 1 } },
    { key: { name: 1 } }
  ]);

  await db.collection("jobOffers").createIndexes([
    { key: { positionId: 1 } },
    { key: { organizationId: 1 } },
    { key: { dateCreated: -1 } }
  ]);

} catch (err) {
  console.error("Error connecting to MongoDB:", err);
}

const db: Database = client.database("jobs");

export default db;
