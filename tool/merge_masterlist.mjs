// One-off: merge the 47-row masterlist (Sheet1 (4).pdf, 23 Sep 2026) into hotels.json.
// - Patches the 26 existing entries (phones, room counts, rates, distances) from the sheet.
// - Appends the 21 new hotels as lean entries (photos pending).
// Reads assets/data/hotels.json, writes the merged result back to the same file.
// Run: node tool/merge_masterlist.mjs
import fs from 'node:fs';

const R = (label, rate) => ({ label, rate });
const phones = (...p) => (p.length ? p.join(', ') : null);

const old = JSON.parse(fs.readFileSync('assets/data/hotels.json', 'utf8').replace(/^\uFEFF/, ''));

// Masterlist rows keyed to existing app entries (S/N 1-26). Column streams were
// realigned per page using rate names/phones; values differ from old data where
// the newer sheet supersedes it.
const sheet = {
  solce: {
    phone: phones('0816 466 5927'), roomsCount: 30, dist: '5.5 KM',
    roomSum: '30 rooms (sheet)',
    rooms: [R('Super Deluxe', 'N59,000'), R('Business Suite', 'N82,600'), R('Royal Suite', 'N112,150')],
  },
  'golden-sand': {
    phone: phones('0816 466 5927'), roomsCount: 23, dist: '5.5 KM',
    roomSum: '23 rooms (sheet)',
    rooms: [R('Superior', 'N64,900'), R('Business Suite', 'N88,550'), R('Royal Suite', 'N118,100')],
  },
  'grand-polo': {
    phone: phones('0907 274 9452'), roomsCount: 54, dist: '4.5 KM',
    roomSum: '54 rooms (sheet)',
    rooms: [R('Standard Room', 'N65,000'), R('Executive Suite', 'N80,000'), R('Luxury Suite', 'N90,000'), R('Diplomatic Suite', 'N150,000')],
  },
  'grand-pinnacle': {
    phone: phones('0803 892 4133'), roomsCount: null, dist: '7.2 KM',
    roomSum: 'Categories priced',
    rooms: [R('Standard Room', 'N60,000 (15% discount)'), R('Premium Room', 'N80,000 (15% discount)'), R('Executive Suite', 'N115,000 (15% discount)')],
  },
  'city-star': {
    phone: phones('0809 740 0003', '0808 022 3610'), roomsCount: 20, dist: '5 KM',
    roomSum: '20 rooms (sheet)',
    rooms: [R('Executive', 'N45,000'), R('Deluxe', 'N45,000'), R('Suite', 'N60,000')],
  },
  amada: {
    phone: phones('0816 726 1763'), roomsCount: 25, dist: '3.7 KM',
    roomSum: '25 rooms (sheet)',
    rooms: [R('Standard Room', 'N47,000'), R('Classic Room', 'N52,500'), R('Deluxe Room', 'N57,000'), R('Luxury Suite', 'N71,500 (breakfast included)')],
  },
  'borno-state-hotel': {
    phone: phones('0806 889 6400'), roomsCount: 30, dist: '4.2 KM',
    roomSum: '30 rooms (sheet)',
    rooms: [R('Chalet', 'N85,000 (VAT & service incl.)'), R('Standard Room', 'N68,000'), R('Deluxe Room', 'N78,000'), R('Studio', 'N88,500'), R('Luxury', 'N115,000')],
  },
  'kelrich-hotel': {
    phone: phones('0802 447 8888'), roomsCount: 79, dist: '3.9 KM',
    roomSum: '79 rooms (sheet)',
    rooms: [R('Standard', 'N30,000'), R('Royal Double', 'N45,000'), R('VIP', 'N85,000'), R('Executive VIP', 'N95,000'), R('Suites', 'N135,000')],
  },
  'rb-hotel': {
    phone: phones('0706 136 6090', '0808 437 1255'), roomsCount: 27, dist: '5.4 KM',
    roomSum: '27 rooms (sheet)',
    rooms: [R('Studio', 'N35,500'), R('Deluxe', 'N48,500'), R('Executive', 'N58,500'), R('VIP', 'N68,500'), R('Suite', 'N75,500')],
  },
  zairan: {
    phone: phones('0803 357 9896', '0913 230 6750'), roomsCount: 45, dist: null,
    roomSum: '45 rooms (sheet)',
    rooms: [R('Rates', 'Pending')],
  },
  'nanne-and-boi': {
    phone: phones('0703 050 9184'), roomsCount: 100, dist: null,
    roomSum: '100 rooms (sheet)',
    rooms: [R('Luxury Suites', 'N50,000'), R('Executive Suites', 'N65,000'), R('Royal Suites', 'N70,000'), R('Premium / VIP option', 'N250,000')],
  },
  'aiba-sport-resort': {
    phone: phones('0703 050 9184'), roomsCount: 45, dist: null,
    roomSum: '45 rooms (sheet)',
    rooms: [R('Standard', 'N35,000'), R('Deluxe', 'N40,000'), R('Executive', 'N45,000'), R('Premium', 'N50,000'), R('Suite', 'N60,000'), R('Chalets', 'N1,080,000')],
  },
  barwee: {
    phone: phones('0706 650 2891'), roomsCount: null, dist: null,
    roomSum: 'Categories priced',
    rooms: [R('Luxury Standard', 'N35,000'), R('Mini Royal Suites', 'N45,000'), R('Royal Suites', 'N55,000'), R('Chalet', 'N60,000 (restaurant & outdoor catering available)')],
  },
  dujima: {
    phone: phones('0814 064 3051'), roomsCount: 37, dist: null,
    roomSum: '37 rooms (sheet)',
    rooms: [R('Single Standard', 'N38,000'), R('Double Standard', 'N48,000'), R('Executive Suite', 'N50,000'), R('VIP Suite', 'N60,000')],
  },
  'desert-view': {
    phone: phones('0806 511 9443'), roomsCount: 14, dist: '4.5 KM',
    roomSum: '14 rooms (sheet)',
    rooms: [R('Standard Room', 'N21,829 - N30,409')],
  },
  djado: {
    phone: phones('0906 511 0643'), roomsCount: 32, dist: '8 KM',
    roomSum: '32 rooms (sheet)',
    rooms: [R('Executive Room', 'N35,000'), R('Deluxe Room', 'N45,000'), R('Suite Room', 'N55,000')],
  },
  'dujima-annex': {
    phone: phones('0806 873 2382'), roomsCount: 30, dist: '2.8 KM',
    roomSum: '30 rooms (sheet)',
    rooms: [R('Single', 'N18,000'), R('Standard', 'N21,000'), R('Single Luxury', 'N25,000'), R('Executive Studio', 'N32,000'), R("Governor's Lodge", 'N38,000'), R('Presidential Suite', 'N50,000')],
  },
  'garki-guest': {
    phone: phones('0814 064 3051', '0703 310 2009'), roomsCount: 37, dist: '1.6 KM',
    roomSum: 'Main + annex rooms (sheet)',
    rooms: [
      R('Main Superior', 'N20,000'), R('Main Suite / Deluxe', 'N22,000'), R('Main VIP', 'N25,000'),
      R('Annex Single', 'N17,000'), R('Annex Suite', 'N25,000'),
    ],
  },
  'khanan-hotel': {
    phone: null, roomsCount: null, dist: '9 KM',
    roomSum: '3 room categories',
    rooms: [R('Standard', 'N35,000'), R('Super', 'N45,000'), R('Premium', 'N55,000')],
  },
  muna: {
    phone: phones('0803 262 5065'), roomsCount: 7, dist: '5.7 KM',
    roomSum: '7 rooms (sheet)',
    rooms: [R('Standard', 'N25,000 discounted / N35,000 tariff'), R('Deluxe', 'N35,000 discounted / N40,000 tariff'), R('Luxury Suites', 'N40,000 discounted / N50,000 tariff')],
  },
  'command-guest-inn': {
    phone: phones('0808 675 7682'), roomsCount: 50, dist: '5.7 KM',
    roomSum: '50 rooms (sheet)',
    rooms: [R('Standard rooms', 'From N20,500'), R('Larger rooms', 'Up to N27,500')],
  },
  'bajele-hotels': {
    phone: null, roomsCount: 10, dist: null,
    roomSum: '10 rooms (sheet); rates pending',
    rooms: [R('Rates', 'Pending')],
  },
  'galaxy-hotel': {
    phone: null, roomsCount: null, dist: null,
    roomSum: 'Rooms pending',
    rooms: [R('Rates', 'Pending')],
  },
  'glopet-hotel': {
    phone: null, roomsCount: 8, dist: '11 KM',
    roomSum: '8 rooms (sheet)',
    rooms: [R('Rates', 'Pending')],
  },
  'unimaid-guest-inn': {
    phone: phones('0706 962 5892'), roomsCount: 8, dist: '5.7 KM',
    roomSum: '8 rooms (sheet)',
    rooms: [R('Mini suite', 'N18,000'), R('Chalet', 'N25,000'), R('Luxury suites', 'N22,000'), R('Executive suite', 'N30,000')],
  },
  'yerwa-guest-inn': {
    phone: null, roomsCount: null, dist: '5.2 KM',
    roomSum: 'Rooms pending',
    rooms: [R('Rates', 'Pending')],
  },
};

// New hotels S/N 27-47, lean entries. Rates/phones/room-counts from the sheet.
const NEW = [
  {
    id: 'sahel-hotel', rank: 27, tier: 'standard', name: 'Sahel Hotel', sn: 'Sahel',
    tone: 'Budget stay near UNIMAID',
    loc: 'Bama Road, opposite UNIMAID, Maiduguri',
    dist: '5.5 KM', phone: phones('0703 261 6413'), roomsCount: 40,
    desc: 'Budget-friendly hotel opposite the University of Maiduguri on Bama Road, listed in the official masterlist.',
    rooms: [R('Standard', 'N17,000'), R('Deluxe', 'N34,000')],
  },
  {
    id: 'lale-guest-house', rank: 28, tier: 'value', name: 'Lale Guest House', sn: 'Lale',
    tone: 'Value option on Bama Road',
    loc: 'Bama Road, adjacent NUJ, Maiduguri',
    dist: '5.5 KM', phone: phones('0706 634 1555', '0802 871 4718'), roomsCount: 27,
    desc: 'Value guest house adjacent the NUJ press centre on Bama Road, listed in the official masterlist.',
    rooms: [R('Standard', 'N10,750'), R('Double room 1', 'N16,150'), R('Double room 2', 'N19,350'), R('Luxury', 'N22,000'), R('Executive', 'N32,250')],
  },
  {
    id: 'prime-lodge', rank: 29, tier: 'standard', name: 'Prime Lodge', sn: 'Prime',
    tone: 'City-centre lodge',
    loc: 'Off Circular Road, Abba Kyari / Abba Kolo Street, Maiduguri',
    dist: null, phone: phones('0702 681 3147'), roomsCount: null,
    desc: 'Lodge off Circular Road in the Abba Kyari/Abba Kolo Street area, listed in the official masterlist.',
    rooms: [R('Single', 'N45,000'), R('Suite', 'N70,000'), R('Executive', 'N85,000'), R('Penthouse', 'N150,000')],
  },
  {
    id: 'bamus-suites', rank: 30, tier: 'standard', name: 'Bamus Suites and Apartments', sn: 'Bamus',
    tone: 'Serviced apartments by Lagos Street bridge',
    loc: 'No. 1 beside Lagos Street bridge, Maiduguri',
    dist: null, phone: phones('0701 293 9350', '0806 998 8464'), roomsCount: null,
    desc: 'Serviced suites and apartments beside the Lagos Street bridge, listed in the official masterlist.',
    rooms: [R('Studio', 'N56,000'), R('Premium', 'N80,000 (N75,000 discounted)'), R('Executive', 'N90,000 (N85,000 discounted)'), R('Presidential Suite', 'N300,000 (N280,000 discounted)')],
  },
  {
    id: 'imperial-hotel', rank: 31, tier: 'standard', name: 'Imperial Hotel', sn: 'Imperial',
    tone: 'Old GRA stay',
    loc: 'Old GRA, Circular Road, Maiduguri',
    dist: null, phone: null, roomsCount: null,
    desc: 'Hotel in the Old GRA on Circular Road, listed in the official masterlist.',
    rooms: [R('Rates', 'Pending')],
  },
  {
    id: 'house-174', rank: 32, tier: 'standard', name: 'House 174', sn: 'House 174',
    tone: 'Boutique option in Polo GRA',
    loc: 'Plot 176 Kamao, Polo Old GRA, Maiduguri',
    dist: '5.8 KM', phone: phones('0805 933 3053'), roomsCount: 3,
    desc: 'Small boutique property in the Polo Old GRA area, listed in the official masterlist.',
    rooms: [R('Suite', 'N45,000'), R('Suite (premium)', 'N150,000')],
  },
  {
    id: 'jemdove-homes', rank: 33, tier: 'standard', name: 'Jemdove Homes and Apartments', sn: 'Jemdove',
    tone: 'Low-cost estate apartments',
    loc: 'A8 Federal Low-Cost Housing Estate, Maiduguri',
    dist: '5.5 KM', phone: phones('0701 036 2776'), roomsCount: null,
    desc: 'Apartment-style accommodation in the Federal Low-Cost Housing Estate, listed in the official masterlist.',
    rooms: [R('Executive Suite', 'N70,000'), R('Diplomatic Suite', 'N80,000')],
  },
  {
    id: 'cityden-apartments', rank: 34, tier: 'standard', name: 'Cityden Apartments', sn: 'Cityden',
    tone: 'Agoja-area serviced apartments',
    loc: 'No. 3 Abu Zar Algifarri Road, off Muhammed Goni Street (Agoja area), Old GRA, Maiduguri',
    dist: '8.4 KM', phone: phones('0806 110 5548', '0802 550 1048'), roomsCount: 20,
    desc: 'Serviced apartments off Muhammed Goni Street in the Agoja area of Old GRA, listed in the official masterlist.',
    rooms: [R('Classic Suite', 'N90,000'), R('VIP Suite', 'N120,000'), R('Chalet Suite', 'N150,000')],
  },
  {
    id: 'lake-chad-hotel', rank: 35, tier: 'value', name: 'Lake Chad Hotel', sn: 'Lake Chad',
    tone: 'Value stay on Kashim Ibrahim Road',
    loc: 'Kashim Ibrahim Road, Maiduguri',
    dist: '10 KM', phone: phones('0906 686 3917', '0814 408 4721'), roomsCount: null,
    desc: 'Value hotel on Kashim Ibrahim Road, listed in the official masterlist.',
    rooms: [R('Standard', 'N20,000'), R('Deluxe / Luxury', 'N23,000'), R('Executive', 'N25,000'), R('Double Room', 'N30,000')],
  },
  {
    id: 'garki-annex', rank: 36, tier: 'value', name: 'Garki Guest Inn Annex', sn: 'Garki Annex',
    tone: 'Annex of Garki Guest Inn',
    loc: 'Maiduguri 610111, Borno',
    dist: '10 KM', phone: phones('0703 310 2009'), roomsCount: 33,
    desc: 'Annex property of Garki Guest Inn, listed separately in the official masterlist.',
    rooms: [R('Single', 'N17,000'), R('Suite', 'N25,000')],
  },
  {
    id: 'rahama-lodge', rank: 37, tier: 'value', name: 'Rahama Lodge', sn: 'Rahama',
    tone: 'Budget lodge on Damboa Road',
    loc: 'R4CV+VW2, Yerwa Road, Damboa Road, Maiduguri',
    dist: '10 KM', phone: phones('0706 767 5556', '0803 256 1263'), roomsCount: 95,
    desc: 'Large budget lodge on Yerwa/Damboa Road, listed in the official masterlist.',
    rooms: [R('Complimentary rooms', 'Complimentary (limited)'), R('Single', 'N20,000')],
  },
  {
    id: 'umth-guest-house', rank: 38, tier: 'value', name: 'UMTH Guest House', sn: 'UMTH',
    tone: 'Teaching-hospital guest house',
    loc: 'University of Maiduguri Teaching Hospital, Maiduguri',
    dist: null, phone: null, roomsCount: null,
    desc: 'Guest house of the University of Maiduguri Teaching Hospital, listed in the official masterlist.',
    rooms: [R('Rates', 'Pending')],
  },
  {
    id: 'starlight-peace', rank: 39, tier: 'standard', name: 'Starlight Peace & Luxury Hotel', sn: 'Starlight',
    tone: 'Near Maimalari Barracks',
    loc: 'Opposite Maimalari Barracks, Baga Road, Maiduguri',
    dist: null, phone: null, roomsCount: null,
    desc: 'Hotel opposite Maimalari Barracks on Baga Road, listed in the official masterlist.',
    rooms: [R('Rates', 'Pending')],
  },
  {
    id: 'haske-guest-inn', rank: 40, tier: 'value', name: 'Haske Guest Inn', sn: 'Haske',
    tone: 'Budget stay in Low-Cost',
    loc: 'Gubio Road, Low-Cost, Maiduguri',
    dist: null, phone: phones('0806 863 8335'), roomsCount: 75,
    desc: 'Budget guest inn on Gubio Road in the Low-Cost area, listed in the official masterlist.',
    rooms: [R('Single', 'N12,000'), R('Standard', 'N15,000')],
  },
  {
    id: 'travel-heaven', rank: 41, tier: 'value', name: 'Travel Heaven', sn: 'Travel Heaven',
    tone: 'Budget stay on Gubio Road',
    loc: 'W33W+7R6 Gubio Road, Maiduguri',
    dist: null, phone: phones('0803 256 1263'), roomsCount: 20,
    desc: 'Budget accommodation on Gubio Road, listed in the official masterlist.',
    rooms: [R('Single', 'N15,000'), R('Standard', 'N20,000')],
  },
  {
    id: 'peace-lodge', rank: 42, tier: 'value', name: 'Peace Lodge', sn: 'Peace',
    tone: 'Budget stay by Baga Road',
    loc: 'Adjacent Maximum Prison, Baga Road, Maiduguri',
    dist: '6 KM', phone: phones('0813 967 8380'), roomsCount: 12,
    desc: 'Budget lodge adjacent the Maximum Correctional Centre on Baga Road, listed in the official masterlist.',
    rooms: [R('Single', 'N13,000'), R('Standard', 'N15,000')],
  },
  {
    id: 'ali-chairman', rank: 43, tier: 'value', name: 'Ali Chairman Guest Inn', sn: 'Ali Chairman',
    tone: 'Budget stay on Custom Road',
    loc: 'R55R+2PV along Custom Road, Maiduguri',
    dist: '2.9 KM', phone: phones('0803 987 3187'), roomsCount: 30,
    desc: 'Budget guest inn along Custom Road, listed in the official masterlist.',
    rooms: [R('Single', 'N16,000'), R('Standard', 'N28,000')],
  },
  {
    id: 'horizontal-inn', rank: 44, tier: 'value', name: 'Horizontal Guest Inn', sn: 'Horizontal',
    tone: 'Budget stay with discount',
    loc: 'Maiduguri, Borno State',
    dist: '7.8 KM', phone: phones('0803 850 3548'), roomsCount: 20,
    desc: 'Budget guest inn offering a 7.5% discount, listed in the official masterlist.',
    rooms: [R('Studio', 'N18,000'), R('Deluxe', 'N25,000'), R('Luxury', 'N35,000 (7.5% discount)')],
  },
  {
    id: 'tourist-hotel', rank: 45, tier: 'value', name: 'Tourist Hotel', sn: 'Tourist',
    tone: 'Budget stay',
    loc: 'Maiduguri, Borno State',
    dist: '7.7 KM', phone: null, roomsCount: 30,
    desc: 'Budget hotel listed in the official masterlist.',
    rooms: [R('Single', 'N10,000')],
  },
  {
    id: 'mara-zaine', rank: 46, tier: 'value', name: 'Mara Zaine', sn: 'Mara Zaine',
    tone: 'Budget stay beside UMTH',
    loc: 'Beside UMTH, Gwange, Maiduguri',
    dist: '7.0 KM', phone: null, roomsCount: null,
    desc: 'Budget property beside the University of Maiduguri Teaching Hospital in Gwange, listed in the official masterlist.',
    rooms: [R('Single', 'N7,000'), R('Standard', 'N9,000'), R('Luxury', 'N10,000'), R('Executive', 'N15,000')],
  },
  {
    id: 'borno-hotel-2', rank: 47, tier: 'value', name: 'Unnamed Property (S/N 47)', sn: 'S/N 47',
    tone: 'Rates listed, identity pending',
    loc: 'Maiduguri, Borno State',
    dist: null, phone: null, roomsCount: null,
    desc: 'Final row of the masterlist with rates (single N10,500 / standard N15,000) but no legible hotel name or address in the PDF; verify against the source spreadsheet.',
    rooms: [R('Single', 'N10,500'), R('Standard', 'N15,000')],
  },
];

const desc = (h) => `${h.desc} Data from the official Maiduguri hotels masterlist (Sheet1 (4), 23 Sep 2026).`;
const highlights = (h, extras = []) => [
  ...extras,
  `Contact: ${h.phone || 'not supplied'}`,
  `Rooms: ${h.roomsCount ?? 'not supplied'}`,
  `Distance to venue: ${h.dist ?? 'not supplied'}`,
].filter((x) => !x.endsWith('not supplied'));

const merged = old.map((h) => {
  const s = sheet[h.id];
  if (!s) return h;
  return {
    ...h,
    contactPhone: s.phone ?? h.contactPhone,
    distanceToVenue: s.dist ?? h.distanceToVenue,
    roomSummary: s.roomSum || h.roomSummary,
    rooms: s.rooms ?? h.rooms,
    highlights: highlights(
      { phone: s.phone ?? h.contactPhone, roomsCount: s.roomsCount, dist: s.dist ?? h.distanceToVenue },
      h.highlights.filter((x) => !/^Contact:|^Rooms:|^Distance to venue:/.test(x)),
    ),
  };
});

const appended = NEW.map((h) => ({
  id: h.id,
  rank: h.rank,
  qualityTier: h.tier,
  name: h.name,
  shortName: h.sn,
  tone: h.tone,
  location: h.loc,
  distanceToVenue: h.dist ?? 'Distance pending official logistics confirmation',
  contactPhone: h.phone,
  description: desc(h),
  roomSummary: h.roomsCount != null ? `${h.roomsCount} rooms (sheet)` : 'Categories priced',
  rateStatus: h.rooms.some((r) => r.rate === 'Pending') ? 'Rates pending' : 'Rates listed',
  highlights: highlights(h),
  rooms: h.rooms,
  images: [],
  photoCount: 0,
}));

const result = [...merged, ...appended];
fs.writeFileSync('assets/data/hotels.json', '\uFEFF' + JSON.stringify(result, null, 4) + '\r\n');
console.log(`OK: ${merged.length} patched + ${appended.length} new = ${result.length} hotels`);
