import db from "./db.ts";
import { JobOfferModel, JobPositionModel, LocationModel, OrganizationModel } from "./types.ts";

async function geoQueries() {
  await LocationModel.createIndexes({
    indexes: [
      { name: "geoPoint_2dsphere", key: { "geoPoint": "2dsphere" } }
    ],
  });

  const wroclaw = {
    type: "Point",
    coordinates: [17.0385, 51.1079] // długość i szerokość geograficzna Wrocławia
  };

  const nearbyLocations = await db.collection("locations").find({
    geoPoint: {
      $near: {
        $geometry: wroclaw,
        $maxDistance: 50000 // 50km w metrach
      }
    }
  }).toArray();

  const polandBounds = {
    type: "Polygon",
    coordinates: [[
      [14.12, 49.00], // SW
      [24.15, 49.00], // SE
      [24.15, 54.83], // NE
      [14.12, 54.83], // NW
      [14.12, 49.00]  // zamknięcie wielokąta
    ]]
  };

  const locationsInPoland = await db.collection("locations").find({
    geoPoint: {
      $geoWithin: {
        $geometry: polandBounds
      }
    }
  }).toArray();

  return { nearbyLocations, locationsInPoland };
}

async function textSearchQueries() {
  await JobOfferModel.createIndexes({
    indexes: [
      {
        name: "text_search_index",
        key: {
          text: "text",
          html: "text",
          "contact.email": "text"
        }
      }
    ],
  });

  const searchResults = await db.collection("jobOffers").find({
    $text: {
      $search: "python javascript developer",
      $caseSensitive: false,
      $diacriticSensitive: false
    }
  })
    .sort({ score: { $meta: "textScore" } })
    .limit(10)
    .toArray();

  const regexResults = await db.collection("jobOffers").find({
    $or: [
      { text: /senior|lead/i },
      { html: /<strong>urgent<\/strong>/i }
    ]
  }).toArray();

  return { searchResults, regexResults };
}

async function mapReduceAnalysis() {

  await JobOfferModel.createIndexes({
    indexes: [
      {
        name: "salary_date_index",
        key: {
          "salary.value": 1,
          dateCreated: 1
        }
      },
      {
        name: "organization_date_index",
        key: {
          organizationId: 1,
          dateCreated: 1
        }
      }
    ],
  });

  const salaryByDepartment = await db.collection("jobPositions").aggregate([
    {
      $lookup: {
        from: "jobOffers",
        localField: "_id",
        foreignField: "positionId",
        as: "offers"
      }
    },
    {
      $unwind: "$offers"
    },
    {
      $group: {
        _id: "$department",
        avgSalary: { $avg: "$offers.salary.value" },
        count: { $sum: 1 }
      }
    },
    {
      $sort: { avgSalary: -1 }
    }
  ]).toArray();

  const hiringTrends = await db.collection("jobOffers").aggregate([
    {
      $match: {
        dateCreated: {
          $gte: new Date(new Date().setMonth(new Date().getMonth() - 6))
        }
      }
    },
    {
      $group: {
        _id: {
          year: { $year: "$dateCreated" },
          month: { $month: "$dateCreated" },
          department: "$position.department"
        },
        count: { $sum: 1 }
      }
    },
    {
      $sort: { "_id.year": 1, "_id.month": 1 }
    }
  ]).toArray();

  return { salaryByDepartment, hiringTrends };
}


function main() {
  async function runAllFunctions() {
    const results = await main();
    await mapReduceAnalysis()
    await geoQueries()
    await textSearchQueries()
    console.log("Results:", results);
  }

  runAllFunctions();
}


main()