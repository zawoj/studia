import db from "./db.ts";

async function runTransaction() {
  try {
    const result = await db.transaction(async () => {
      const organization = await db.collection("organizations")
        .findOne({ name: "Example Org" });

      if (!organization) {
        throw new Error("Organization not found");
      }

      const newPosition = {
        organizationId: organization._id,
        name: "Software Engineer",
        careerLevel: "Senior",
        contractType: "Full-time",
        department: "IT",
        workType: "Remote",
        locationId: null,
      };

      const positionResult = await db.collection("jobPositions")
        .insertOne(newPosition);

      const newOffer = {
        positionId: positionResult.id,
        organizationId: organization._id,
        contact: {
          email: "careers@example.com",
          phone: "+1234567890",
        },
        dateCreated: new Date(),
        dateExpired: null,
        dateScraped: new Date(),
        html: "<p>Example job offer</p>",
        idInSource: "JO123",
        json: {},
        locale: "en",
        orgTags: {},
        referenceID: "REF456",
        salary: {
          period: "monthly",
          text: "$5000 - $6000",
          value: 5500,
        },
        source: "example.com",
        sourceCC: "US",
        text: "Example job offer description",
        url: "https://example.com/jobs/123",
      };

      await db.collection("jobOffers").insertOne(newOffer);
      return { position: positionResult, offer: newOffer };
    });

    console.log("Transaction completed successfully", result);
  } catch (error) {
    console.error("Transaction aborted:", error);
  }
}

runTransaction();