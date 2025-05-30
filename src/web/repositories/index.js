const airportsJSON = require("../data/airports");
const destinationsJSON = require("../data/destinations");
const dealsJSON = require("../data/deals");
const flightsJSON = require("../data/flights");
const _BookRepository = require("./book.repository");
const _FlightsRepository = require("./flights.repository");

let bookRepository = null;

const AirportsRepository = () => airportsJSON;
const DestinationsRepository = () => destinationsJSON;
const DealsRepository = () => dealsJSON;
const BookRepository = () => {
  if (!bookRepository) {
    const listConnectionStringUrl =
      process.env.AZURE_COSMOS_LISTCONNECTIONSTRINGURL;
    const scope = process.env.AZURE_COSMOS_SCOPE;
    const clientId = process.env.AZURE_COSMOS_CLIENTID;

    if (listConnectionStringUrl && scope && clientId) {
      console.log(
        "Azure CosmosDB settings found. Booking functionality enabled."
      );
      bookRepository = new _BookRepository({
        listConnectionStringUrl,
        scope,
        clientId,
      });
    } else {
      console.warn(
        "Azure CosmosDB settings not found. Booking functionality not available."
      );
    }
  }

  return bookRepository;
};
const FlightsRepository = () => new _FlightsRepository(flightsJSON);

module.exports = {
  AirportsRepository,
  DestinationsRepository,
  DealsRepository,
  BookRepository,
  FlightsRepository,
};
