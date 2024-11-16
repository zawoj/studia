import { ObjectId } from "./deps.ts";
import { JobOffer, JobPosition, JobPostingBulk, Location, Organization, LocationModel, JobOfferModel, JobPositionModel, OrganizationModel, JobPostingBulkModel } from "./types.ts";

export async function convertJobPostingBulk(jobPostingBulk: JobPostingBulk): Promise<[Location, JobOffer, JobPosition, Organization]> {
  const location: Location = {
    addressLine: jobPostingBulk.orgAddress?.addressLine ?? null,
    city: jobPostingBulk.orgAddress?.city ?? null,
    companyName: jobPostingBulk.orgAddress?.companyName ?? null,
    country: jobPostingBulk.orgAddress?.country ?? null,
    countryCode: jobPostingBulk.orgAddress?.countryCode ?? null,
    county: jobPostingBulk.orgAddress?.county ?? null,
    district: jobPostingBulk.orgAddress?.district ?? null,
    formatted: jobPostingBulk.orgAddress?.formatted ?? null,
    houseNumber: jobPostingBulk.orgAddress?.houseNumber ?? null,
    level: jobPostingBulk.orgAddress?.level ? String(jobPostingBulk.orgAddress.level) : null,
    postCode: jobPostingBulk.orgAddress?.postCode ?? null,
    quarter: jobPostingBulk.orgAddress?.quarter ?? null,
    state: jobPostingBulk.orgAddress?.state ?? null,
    street: jobPostingBulk.orgAddress?.street ?? null,
  };

  const organization: Organization = {
    _id: new ObjectId(),
    name: jobPostingBulk.orgCompany?.name ?? null,
    nameOrg: jobPostingBulk.orgCompany?.nameOrg ?? null,
    description: jobPostingBulk.orgCompany?.description ?? null,
    idInSource: jobPostingBulk.orgCompany?.idInSource ?? null,
    ids: jobPostingBulk.orgCompany?.ids ?? {},
    imgCover: jobPostingBulk.orgCompany?.imgCover ?? null,
    imgLogo: jobPostingBulk.orgCompany?.imgLogo ?? null,
    mergedID: null,
    registryID: jobPostingBulk.orgCompany?.registryID ?? null,
    source: jobPostingBulk.orgCompany?.source ?? null,
    sourceCC: jobPostingBulk.orgCompany?.sourceCC ?? null,
    url: jobPostingBulk.orgCompany?.url ?? null,
    urls: jobPostingBulk.orgCompany?.urls ?? {},
  };

  const jobPosition: JobPosition = {
    _id: new ObjectId(),
    organizationId: organization._id,
    name: jobPostingBulk.position?.name ?? null,
    careerLevel: jobPostingBulk.position?.careerLevel ?? null,
    contractType: jobPostingBulk.position?.contractType ?? null,
    department: jobPostingBulk.position?.department ?? null,
    workType: jobPostingBulk.position?.workType ?? null,
    locationId: new ObjectId(location._id),
  };

  const jobOffer: JobOffer = {
    _id: new ObjectId(),
    positionId: jobPosition._id,
    organizationId: organization._id,
    contact: {
      email: jobPostingBulk.contact?.email ?? null,
      phone: jobPostingBulk.contact?.phone ?? null,
    },
    dateCreated: jobPostingBulk.dateCreated ?? null,
    dateExpired: jobPostingBulk.json?.schemaOrg?.validThrough ? new Date(jobPostingBulk.json.schemaOrg.validThrough) : null,
    dateScraped: jobPostingBulk.dateScraped ?? null,
    html: jobPostingBulk.html ?? null,
    idInSource: jobPostingBulk.idInSource ?? null,
    json: jobPostingBulk.json ?? {},
    locale: jobPostingBulk.locale ?? null,
    orgTags: jobPostingBulk.orgTags ?? {},
    referenceID: null,
    salary: {
      period: jobPostingBulk.salary?.period ?? null,
      text: jobPostingBulk.salary?.text ?? null,
      value: jobPostingBulk.salary?.value ?? null,
    },
    source: jobPostingBulk.source ?? null,
    sourceCC: jobPostingBulk.sourceCC ?? null,
    text: jobPostingBulk.text ?? null,
    url: jobPostingBulk.url ?? null,
  };

  return [location, jobOffer, jobPosition, organization];
}

export async function saveTransformedDataBatch(jobPostingBulks: JobPostingBulk[]) {
  const transformedData = await Promise.all(
    jobPostingBulks.map(convertJobPostingBulk)
  );

  const locations = [];
  const organizations = [];
  const jobPositions = [];
  const jobOffers = [];

  transformedData.forEach(([location, jobOffer, jobPosition, organization]) => {
    locations.push(location);
    organizations.push(organization);
    jobPositions.push(jobPosition);
    jobOffers.push(jobOffer);
  });

  // Split into chunks of 100 to stay under MongoDB's 16MB limit
  const chunkSize = 100;
  for (let i = 0; i < locations.length; i += chunkSize) {
    const chunk = {
      locations: locations.slice(i, i + chunkSize),
      organizations: organizations.slice(i, i + chunkSize),
      jobPositions: jobPositions.slice(i, i + chunkSize),
      jobOffers: jobOffers.slice(i, i + chunkSize)
    };
    
    // Save data in bulk while maintaining referential integrity
    if (chunk.locations.length > 0) await LocationModel.insertMany(chunk.locations);
    if (chunk.organizations.length > 0) await OrganizationModel.insertMany(chunk.organizations);
    if (chunk.jobPositions.length > 0) await JobPositionModel.insertMany(chunk.jobPositions);
    if (chunk.jobOffers.length > 0) await JobOfferModel.insertMany(chunk.jobOffers);
  }
}

export async function processKaggleData(batchSize = 1000) {
  const cursor = JobPostingBulkModel.find({});
  let processed = 0;
  let batch: JobPostingBulk[] = [];

  for await (const doc of cursor) {
    try {
      batch.push(doc);

      if (batch.length >= batchSize) {
        await saveTransformedDataBatch(batch);
        processed += batch.length;
        console.log(`Processed ${processed} documents`);
        batch = [];
      }
    } catch (error) {
      console.error(`Error processing batch:`, error);
    }
  }

  // Process remaining documents
  if (batch.length > 0) {
    try {
      await saveTransformedDataBatch(batch);
      processed += batch.length;
    } catch (error) {
      console.error(`Error processing final batch:`, error);
    }
  }

  console.log(`Finished processing ${processed} documents`);
}


await processKaggleData();