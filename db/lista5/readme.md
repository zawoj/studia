+----------------------------------------------------
| key                     | types     | Explanation
| ------------------------| ----------| -------------
| _id                     | ObjectId  | Unique ID from the MongoDB
| companyID               | ObjectId  | ID to a company document in our MongoDB (unique for company but not unique for jobs)
| contact                 | Object    | Map/Object with contact info from the JSON, HTML or extracted from job posting
| contact.email           | String    | Corporate email address mentioned from JSON or job posting
| contact.phone           | String    | Corporate phone address extracted from JSON or job posting
| dateCreated             | Date      | Date the job posting was created (or date scraped if creation date is not available)
| dateExpired             | Date      | Date the job posting expires
| dateScraped             | Date      | Date the job posting was scraped
| html                    | String    | The raw HTML of the job description (can be plain text for some sources)
| idInSource              | String    | An id used in the source portal (unique for the source)
| json                    | Object    | JSON found in the HTML page (schemaOrg contains a schem.org JobPosting and pageData1-3 source-specific json)
| locale                  | String    | Locale extracted from the JSON or job posting (e.g., "en_US")
| locationID              | ObjectId  | ID to a location document in our MongoDB (unique for company but not unique for jobs)
| name                    | String    | Title or Name of the job posting
| orgAddress              | Object    | Original address data extracted from the job posting
| orgAddress.addressLine  | String    | Raw address line - mostly just a city name
| orgAddress.city         | String    | City name from JSON, HTML or extracted from addressLine
| orgAddress.companyName  | String    | Company name from JSON, HTML or extracted from addressLine
| orgAddress.country      | String    | Country name from JSON, HTML or extracted from addressLine
| orgAddress.countryCode  | String    | ISO 3166 (2 letter) country code from JSON, HTML or extracted from addressLine
| orgAddress.county       | String    | County name from JSON, HTML or extracted from addressLine
| orgAddress.district     | String    | (City) District name from JSON, HTML or extracted from addressLine
| orgAddress.formatted    | String    | Formatted address data extracted from the job posting
| orgAddress.geoPoint     | Object    | Map of geo coordinate if stated in the JSON or job posting
| orgAddress.geoPoint.lat | Number    | Latitude of geo coordinate if stated in the JSON or job posting
| orgAddress.geoPoint.lng | Number    | Longitude of geo coordinate if stated in the JSON or job posting
| orgAddress.houseNumber  | String    | House number extracted from the street or from JSON, HTML or extracted from addressLine
| orgAddress.level        | Number    | Granularity of address (Street-level: 2, PostCode-Level: 3, City-Level: 4, ...)
| orgAddress.postCode     | String    | Postal code / zip code extracted from JSON, HTML or addressLine
| orgAddress.quarter      | String    | (City) Quarter name from JSON, HTML or extracted from addressLine
| orgAddress.state        | String    | State name or abbreviation from JSON, HTML or extracted from addressLine
| orgAddress.street       | String    | Street name (and maybe housenumber) extracted from JSON, HTML or addressLine
| orgCompany              | Object    | Original company data extracted from the job posting
| orgCompany.description  | String    | Description of the company mentioned in the job posting
| orgCompany.idInSource   | String    | An id used in the source portal (can be generated from company name but is unique)
| orgCompany.ids          | Object    | One or more ids extracted from the portal (mostly one but can include two or more sometimes (e.g., Xing often adds kununu ids for a company)
| orgCompany.imgCover     | String    | URL of the cover image specific to a company
| orgCompany.imgLogo      | String    | URL of the logo image specific to a company
| orgCompany.mergedID     | String    | ID of the merged company over all sources
| orgCompany.name         | String    | Name of the company with legal forms removed (e.g., Inc, GmbH, ...)
| orgCompany.nameOrg      | String    | Name of the company as stated on the job posting
| orgCompany.registryID   | String    | ID in the legal registry of the country
| orgCompany.source       | String    | Source portal / website the company was found (e.g., "xing_de" for Xing.com)
| orgCompany.sourceCC     | String    | CountryCode of the source website (e.g., "de" for Xing.com)
| orgCompany.url          | String    | URL to the company page on the source's website
| orgCompany.urls         | Object    | One or more urls extracted from the portal (mostly one but can include two or more sometimes)
| orgTags                 | Object    | Map of arrays with tags found in JSON, HTML or extracted from job posting
| position                | Object    | Map/Object with info on the position from the JSON, HTML or extracted from job posting
| position.careerLevel    | String    | Career level mentioned in job posting such as junior, senior, etc.
| position.contractType   | String    | Contract type as mentioned in the job posting such as fulltime, parttime, etc.
| position.department     | String    | Department the position is part of such as Marketing, Tech, etc.
| position.name           | String    | Name of position extracted from the JSON, HTML or job posting
| position.workType       | String    | Work type as mentioned in the job posting such as fulltime, parttime, etc.
| referenceID             | String    | ID from the company to identify the job posting
| salary                  | Object    | Map/Object with info on the salary from the JSON, HTML or extracted from job posting
| salary.period           | String    | Period the salary is meant for
| salary.text             | String    | Textual description of the salary (e.g., one-liner such as "50.000€/year" or "negotiable")
| salary.value            | Number    | Numerical value extracter from the textual description
| source                  | String    | Source portal / website the job posting was found (e.g., "xing_de" for Xing.com)
| sourceCC                | String    | CountryCode of the source portal / website (e.g., "de" for Xing.com)
| text                    | String    | Text of the job posting either extracted from JSON or converted from HMTL
| url                     | String    | URL of the job posting
+----------------------------------------------------
