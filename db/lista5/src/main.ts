import db from "./db.ts";
import { JobOfferModel, JobPositionModel, LocationModel, OrganizationModel } from "./types.ts";


interface QueryResult {
  queryName: string;
  iteration: number;
  duration: number;
}

interface QueryStats {
  queryName: string;
  avgTime: number;
  maxTime: number;
  minTime: number;
}

async function queryTime(queryName: string, queryFn: () => Promise<any>): Promise<QueryResult> {
  const startTime = performance.now();
  await queryFn();
  const endTime = performance.now();
  const duration = endTime - startTime;

  return {
    queryName,
    iteration: 0, // będzie aktualizowane w głównej pętli
    duration,
  };
}

function calculateStats(results: QueryResult[]): QueryStats[] {
  const queryGroups = new Map<string, number[]>();

  // Grupuj wyniki według nazwy zapytania
  results.forEach(result => {
    if (!queryGroups.has(result.queryName)) {
      queryGroups.set(result.queryName, []);
    }
    queryGroups.get(result.queryName)?.push(result.duration);
  });

  return Array.from(queryGroups.entries()).map(([queryName, times]) => ({
    queryName,
    avgTime: Number((times.reduce((a, b) => a + b, 0) / times.length).toFixed(2)),
    minTime: Number(Math.min(...times).toFixed(2)),
    maxTime: Number(Math.max(...times).toFixed(2))
  }));
}

async function saveStats(stats: QueryStats[], filename: string) {
  await Deno.writeTextFile(filename, JSON.stringify(stats, null, 2));
}

async function main() {
  const loopCount = 10;
  const results: QueryResult[] = [];

  try {

    await OrganizationModel.createIndexes({
      indexes: [
        { name: "name_index", key: { name: 1 } },
        { name: "source_index", key: { source: 1 } },
        { name: "idInSource_index", key: { idInSource: 1 } },
        { name: "mergedID_index", key: { mergedID: 1 } },
        { name: "registryID_index", key: { registryID: 1 } },
      ],
    });

    await JobPositionModel.createIndexes({
      indexes: [
        { name: "organizationId_index", key: { organizationId: 1 } },
        { name: "name_index", key: { name: 1 } },
        { name: "locationId_index", key: { locationId: 1 } },
      ],
    });

    await JobOfferModel.createIndexes({
      indexes: [
        { name: "positionId_index", key: { positionId: 1 } },
        { name: "organizationId_index", key: { organizationId: 1 } },
        { name: "dateCreated_index", key: { dateCreated: 1 } },
        { name: "dateExpired_index", key: { dateExpired: 1 } },
        { name: "dateScraped_index", key: { dateScraped: 1 } },
        { name: "idInSource_index", key: { idInSource: 1 } },
        { name: "referenceID_index", key: { referenceID: 1 } },
        { name: "source_index", key: { source: 1 } },
      ],
    });

    await LocationModel.createIndexes({
      indexes: [
        { name: "city_index", key: { city: 1 } },
        { name: "country_index", key: { country: 1 } },
        { name: "countryCode_index", key: { countryCode: 1 } },
        { name: "state_index", key: { state: 1 } },
        { name: "postCode_index", key: { postCode: 1 } },
      ],
    });

    console.log("Starting query benchmarks...");

    console.log("\nExecuting simple findOne queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running findOne query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`jobOffers findone`, () =>
        db.collection('jobOffers').findOne()
      );
      result.iteration = index;
      results.push(result);
    }

    console.log("\nExecuting sorted queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running sorted query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`jobOffers sort by name`, () =>
        db.collection('jobOffers').find().sort({ dateCreated: -1 }).limit(10).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    console.log("\nExecuting complex queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running complex query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Complex query`, () =>
        db.collection('jobOffers')
          .find({
            dateExpired: { $gt: new Date() },
            "salary.value": { $exists: true },
            "contact.email": { $ne: null }
          })
          .limit(5)
          .toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // 1. Znajdź wszystkie oferty pracy dla organizacji z określonej branży (używając tagów)
    console.log("\nExecuting industry specific queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running industry query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Industry specific offers`, () =>
        db.collection('jobOffers').aggregate([
          {
            $match: {
              "orgTags.industry": "IT"
            }
          },
          {
            $lookup: {
              from: "organizations",
              localField: "organizationId",
              foreignField: "_id",
              as: "organization"
            }
          },
          {
            $limit: 10
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // 2. Analiza wynagrodzeń według lokalizacji
    console.log("\nExecuting salary analysis queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running salary analysis iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Salary analysis by location`, () =>
        db.collection('jobOffers').aggregate([
          {
            $lookup: {
              from: "jobPositions",
              localField: "positionId",
              foreignField: "_id",
              as: "position"
            }
          },
          {
            $lookup: {
              from: "locations",
              localField: "position.locationId",
              foreignField: "_id",
              as: "location"
            }
          },
          {
            $match: {
              "salary.value": { $exists: true }
            }
          },
          {
            $group: {
              _id: "$location.city",
              avgSalary: { $avg: "$salary.value" },
              count: { $sum: 1 }
            }
          },
          {
            $sort: { avgSalary: -1 }
          },
          {
            $limit: 5
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // 3. Znajdź najaktywniejsze organizacje rekrutujące
    console.log("\nExecuting recruiting organization queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running organization query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Most active recruiting organizations`, () =>
        db.collection('jobOffers').aggregate([
          {
            $match: {
              dateCreated: {
                $gte: new Date(new Date().setMonth(new Date().getMonth() - 1))
              }
            }
          },
          {
            $lookup: {
              from: "organizations",
              localField: "organizationId",
              foreignField: "_id",
              as: "organization"
            }
          },
          {
            $group: {
              _id: "$organizationId",
              organizationName: { $first: "$organization.name" },
              offerCount: { $sum: 1 }
            }
          },
          {
            $sort: { offerCount: -1 }
          },
          {
            $limit: 10
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // 4. Znajdź oferty pracy z podobnymi wymaganiami
    console.log("\nExecuting position requirement queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running position query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Similar position requirements`, () =>
        db.collection('jobPositions').aggregate([
          {
            $match: {
              careerLevel: "Senior",
              department: "Engineering"
            }
          },
          {
            $lookup: {
              from: "jobOffers",
              localField: "_id",
              foreignField: "positionId",
              as: "offers"
            }
          },
          {
            $match: {
              "offers.salary.value": { $exists: true }
            }
          },
          {
            $project: {
              name: 1,
              careerLevel: 1,
              department: 1,
              averageSalary: { $avg: "$offers.salary.value" }
            }
          },
          {
            $limit: 10
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // 5. Analiza trendów rekrutacyjnych w czasie
    console.log("\nExecuting recruitment trends queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running trends analysis iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Recruitment trends analysis`, () =>
        db.collection('jobOffers').aggregate([
          {
            $match: {
              dateCreated: {
                $gte: new Date(new Date().setMonth(new Date().getMonth() - 6))
              }
            }
          },
          {
            $lookup: {
              from: "jobPositions",
              localField: "positionId",
              foreignField: "_id",
              as: "position"
            }
          },
          {
            $group: {
              _id: {
                month: { $month: "$dateCreated" },
                department: "$position.department"
              },
              count: { $sum: 1 },
              avgSalary: { $avg: "$salary.value" }
            }
          },
          {
            $sort: { "_id.month": 1 }
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }


    // Zapytania dla Organizations
    console.log("\nExecuting organization queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running organization basic query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Organizations by source`, () =>
        db.collection('organizations')
          .find({ source: { $exists: true } })
          .limit(10)
          .toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // Organizacje z największą liczbą obrazów/URL
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running organization media query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Organizations with media`, () =>
        db.collection('organizations').find({
          $and: [
            { imgLogo: { $ne: null } },
            { imgCover: { $ne: null } }
          ]
        }).limit(10).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // Locations queries
    console.log("\nExecuting location queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running location country query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Locations by country`, () =>
        db.collection('locations')
          .find({ countryCode: "US" })
          .limit(10)
          .toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // Lokalizacje z określonymi współrzędnymi geograficznymi
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running location geo query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Locations with coordinates`, () =>
        db.collection('locations')
          .find({
            "geoPoint": { $exists: true }
          })
          .limit(10)
          .toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // JobPositions queries
    console.log("\nExecuting job position queries...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running position contract type query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Positions by contract type`, () =>
        db.collection('jobPositions')
          .find({ contractType: "FULL_TIME" })
          .limit(10)
          .toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // Złożone zapytanie dla pozycji
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running complex position query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Complex position query`, () =>
        db.collection('jobPositions').aggregate([
          {
            $match: {
              workType: "REMOTE",
              careerLevel: "SENIOR"
            }
          },
          {
            $lookup: {
              from: "organizations",
              localField: "organizationId",
              foreignField: "_id",
              as: "organization"
            }
          },
          {
            $lookup: {
              from: "locations",
              localField: "locationId",
              foreignField: "_id",
              as: "location"
            }
          },
          {
            $project: {
              name: 1,
              department: 1,
              "organization.name": 1,
              "location.city": 1,
              "location.country": 1
            }
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // Cross-collection analysis
    console.log("\nExecuting cross-collection analysis...");
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running cross-collection query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Organization location distribution`, () =>
        db.collection('jobPositions').aggregate([
          {
            $lookup: {
              from: "locations",
              localField: "locationId",
              foreignField: "_id",
              as: "location"
            }
          },
          {
            $lookup: {
              from: "organizations",
              localField: "organizationId",
              foreignField: "_id",
              as: "organization"
            }
          },
          {
            $group: {
              _id: {
                organizationId: "$organizationId",
                country: "$location.country"
              },
              positionCount: { $sum: 1 },
              organizationName: { $first: "$organization.name" }
            }
          },
          {
            $sort: { positionCount: -1 }
          },
          {
            $limit: 10
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    // Statystyki departamentów
    for (let index = 0; index < loopCount; index++) {
      console.log(`Running department statistics query iteration ${index + 1}/${loopCount}`);
      const result = await queryTime(`Department statistics`, () =>
        db.collection('jobPositions').aggregate([
          {
            $group: {
              _id: "$department",
              positionCount: { $sum: 1 },
              uniqueOrganizations: { $addToSet: "$organizationId" }
            }
          },
          {
            $project: {
              department: "$_id",
              positionCount: 1,
              organizationCount: { $size: "$uniqueOrganizations" }
            }
          },
          {
            $sort: { positionCount: -1 }
          }
        ]).toArray()
      );
      result.iteration = index;
      results.push(result);
    }

    console.log("\nCalculating final statistics...");
    const stats = calculateStats(results);
    await saveStats(stats, 'query_stats.json');
    console.log("Results saved to query_stats.json");

  } catch (error) {
    console.error("Error during execution:", error)
  }

}

main()