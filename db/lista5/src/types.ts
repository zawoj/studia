import db from "./db.ts";
import { ObjectId } from "./deps.ts";

// Define the interfaces
export interface Organization {
  _id: ObjectId;
  name: string | null;
  nameOrg: string | null;
  description: string | null;
  idInSource: string | null;
  ids: Record<string, unknown>;
  imgCover: string | null;
  imgLogo: string | null;
  mergedID: string | null;
  registryID: string | null;
  source: string | null;
  sourceCC: string | null;
  url: string | null;
  urls: Record<string, unknown>;
}

export interface JobPosition {
  _id: ObjectId;
  organizationId: ObjectId;
  name: string | null;
  careerLevel: string | null;
  contractType: string | null;
  department: string | null;
  workType: string | null;
  locationId: ObjectId;
}

export interface JobOffer {
  _id: ObjectId;
  positionId: ObjectId;
  organizationId: ObjectId;
  contact: {
    email: string | null;
    phone: string | null;
  };
  dateCreated: Date | null;
  dateExpired: Date | null;
  dateScraped: Date | null;
  html: string | null;
  idInSource: string | null;
  json: Record<string, unknown>;
  locale: string | null;
  orgTags: Record<string, string[]>;
  referenceID: string | null;
  salary: {
    period: string | null;
    text: string | null;
    value: number | null;
  };
  source: string | null;
  sourceCC: string | null;
  text: string | null;
  url: string | null;
}

export interface Location {
  _id?: ObjectId;
  addressLine?: string;
  city?: string;
  companyName?: string;
  country?: string;
  countryCode?: string;
  county?: string;
  district?: string;
  formatted?: string;
  geoPoint?: {
    lat: number;
    lon: number;
  };
  houseNumber?: string;
  level?: string;
  postCode?: string;
  quarter?: string;
  state?: string;
  street?: string;
}

export interface JobPostingBulk {
  _id: ObjectId;
  companyID: ObjectId;
  contact: {
    email: string;
    phone: string;
  };
  dateCreated: Date;
  dateExpired: Date;
  dateScraped: Date;
  html: string;
  idInSource: string;
  json: {
    schemaOrg: any;
    pageData1?: any;
    pageData2?: any;
    pageData3?: any;
  };
  locale: string;
  locationID: ObjectId;
  name: string;
  orgAddress: {
    addressLine: string;
    city: string;
    companyName: string;
    country: string;
    countryCode: string;
    county: string;
    district: string;
    formatted: string;
    geoPoint: {
      lat: number;
      lng: number;
    };
    houseNumber: string;
    level: number;
    postCode: string;
    quarter: string;
    state: string;
    street: string;
  };
  orgCompany: {
    description: string;
    idInSource: string;
    ids: Record<string, string>;
    imgCover: string;
    imgLogo: string;
    mergedID: string;
    name: string;
    nameOrg: string;
    registryID: string;
    source: string;
    sourceCC: string;
    url: string;
    urls: Record<string, string>;
  };
  orgTags: Record<string, string[]>;
  position: {
    careerLevel: string;
    contractType: string;
    department: string;
    name: string;
    workType: string;
  };
  referenceID: string;
  salary: {
    period: string;
    text: string;
    value: number;
  };
  source: string;
  sourceCC: string;
  text: string;
  url: string;
}

// Define the models
export const OrganizationModel = db.collection<Organization>("organizations");
export const JobPositionModel = db.collection<JobPosition>("jobPositions");
export const JobOfferModel = db.collection<JobOffer>("jobOffers");
export const LocationModel = db.collection<Location>("locations");
export const JobPostingBulkModel = db.collection<JobPostingBulk>("kaggle");