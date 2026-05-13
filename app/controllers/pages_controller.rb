class PagesController < ApplicationController
  GEMS = [
    { name: "Diamond",    mohs: 10.0, color: "Colorless / fancy",  origins: ["Botswana", "Russia (Yakutia)"],         fact: "Pure carbon - same element as graphite, just stacked differently.", tint: "slate" },
    { name: "Ruby",       mohs: 9.0,  color: "Red",                origins: ["Myanmar (Mogok)", "Mozambique"],         fact: "Red corundum colored by chromium. Trace iron tips it toward sapphire.", tint: "rose" },
    { name: "Sapphire",   mohs: 9.0,  color: "Blue (and others)",  origins: ["Sri Lanka", "Madagascar", "Kashmir"],    fact: "Same mineral as ruby - different impurity, different name.", tint: "blue" },
    { name: "Emerald",    mohs: 7.5,  color: "Green",              origins: ["Colombia (Muzo)", "Zambia"],             fact: "Beryl with chromium. Inclusions are so expected jewelers call them \"jardin.\"", tint: "emerald" },
    { name: "Opal",       mohs: 6.0,  color: "Play-of-color",      origins: ["Australia (Lightning Ridge)", "Ethiopia"], fact: "Microscopic silica spheres diffract light to produce that flash.", tint: "fuchsia" },
    { name: "Amethyst",   mohs: 7.0,  color: "Purple",             origins: ["Brazil", "Uruguay", "Zambia"],           fact: "Just quartz with a touch of iron and natural radiation - that's purple.", tint: "purple" },
    { name: "Topaz",      mohs: 8.0,  color: "Blue / yellow / clear", origins: ["Brazil", "Pakistan", "Russia (Ural)"], fact: "Most blue topaz on the market is colorless stone irradiated to taste.", tint: "sky" },
    { name: "Aquamarine", mohs: 7.5,  color: "Pale blue-green",    origins: ["Brazil", "Pakistan", "Madagascar"],      fact: "Beryl again - like emerald, but colored by iron instead of chromium.", tint: "cyan" },
    { name: "Tanzanite",  mohs: 6.5,  color: "Violet-blue",        origins: ["Tanzania (Merelani Hills)"],             fact: "Found in exactly one place on Earth - a 4 km strip near Mt. Kilimanjaro.", tint: "indigo" },
    { name: "Garnet",     mohs: 7.0,  color: "Red / orange / green", origins: ["India", "Madagascar", "Tanzania"],    fact: "Not one mineral but a whole family - pyrope, almandine, demantoid, more.", tint: "red" },
    { name: "Tourmaline", mohs: 7.0,  color: "Almost every color", origins: ["Brazil", "Afghanistan", "Mozambique"],   fact: "Pyroelectric - generates a charge when heated. Old sailors cleaned pipes with it.", tint: "pink" },
    { name: "Turquoise",  mohs: 5.5,  color: "Sky-blue / green",   origins: ["Iran (Nishapur)", "USA (Arizona, Nevada)"], fact: "Among the first gems ever mined - Sinai workings go back 6,000+ years.", tint: "teal" }
  ].freeze

  METALS = [
    { symbol: "Au",  number: 79, name: "Gold",       density: 19.3, group: "Precious",            uses: "Jewelry, electronics, reserves",       top: ["China", "Australia", "Russia"],        fact: "Doesn't tarnish in air - a Roman gold coin still looks fresh." },
    { symbol: "Ag",  number: 47, name: "Silver",     density: 10.5, group: "Precious",            uses: "Coinage, electronics, solar cells",   top: ["Mexico", "Peru", "China"],             fact: "Best electrical conductor of any metal." },
    { symbol: "Pt",  number: 78, name: "Platinum",   density: 21.5, group: "Precious",            uses: "Catalytic converters, jewelry",       top: ["South Africa", "Russia"],              fact: "South Africa alone accounts for ~70% of mine production." },
    { symbol: "Pd",  number: 46, name: "Palladium",  density: 12.0, group: "Precious",            uses: "Catalytic converters, electronics",   top: ["Russia", "South Africa"],              fact: "Briefly more expensive than gold during the 2020 EV surge." },
    { symbol: "Cu",  number: 29, name: "Copper",     density: 8.96, group: "Base",                uses: "Wiring, plumbing, alloys",            top: ["Chile", "Peru", "China"],              fact: "Antimicrobial - copper touchpoints kill bacteria on contact." },
    { symbol: "Zn",  number: 30, name: "Zinc",       density: 7.14, group: "Base",                uses: "Galvanizing steel, brass, batteries", top: ["China", "Peru", "Australia"],          fact: "Zinc-plated steel resists rust because zinc oxidizes preferentially." },
    { symbol: "Pb",  number: 82, name: "Lead",       density: 11.34, group: "Base",               uses: "Batteries, radiation shielding",      top: ["China", "Australia", "USA"],           fact: "Easy to smelt at ~327 °C - one reason it was the first metal worked at scale." },
    { symbol: "Sn",  number: 50, name: "Tin",        density: 7.31, group: "Base",                uses: "Solder, food cans, alloys",           top: ["China", "Indonesia", "Myanmar"],       fact: "Mixed with copper, you get bronze - launched an entire age." },
    { symbol: "Ni",  number: 28, name: "Nickel",     density: 8.91, group: "Base",                uses: "Stainless steel, EV batteries",       top: ["Indonesia", "Philippines", "Russia"],  fact: "Earth's core is about 5% nickel, the rest mostly iron." },
    { symbol: "Fe",  number: 26, name: "Iron",       density: 7.87, group: "Base",                uses: "Steel for everything",                top: ["Australia", "Brazil", "China"],        fact: "By tonnage, ~95% of all metal produced on Earth is iron." },
    { symbol: "Al",  number: 13, name: "Aluminum",   density: 2.70, group: "Light & Strategic",   uses: "Cans, foil, aircraft, transmission",  top: ["China", "India", "Russia"],            fact: "Third most abundant element in the crust, yet pure metal was once pricier than gold." },
    { symbol: "Ti",  number: 22, name: "Titanium",   density: 4.51, group: "Light & Strategic",   uses: "Aerospace, medical implants",         top: ["China", "Japan", "Russia"],            fact: "As strong as steel at roughly 45% the weight." },
    { symbol: "Li",  number: 3,  name: "Lithium",    density: 0.53, group: "Light & Strategic",   uses: "Lithium-ion batteries, ceramics",     top: ["Australia", "Chile", "China"],         fact: "Lightest metal - floats on water (briefly, before reacting)." },
    { symbol: "Co",  number: 27, name: "Cobalt",     density: 8.86, group: "Light & Strategic",   uses: "EV batteries, superalloys",           top: ["DR Congo", "Russia", "Australia"],     fact: "DR Congo alone supplies roughly 70% of mined cobalt." },
    { symbol: "REE", number: nil, name: "Rare Earths", density: nil, group: "Light & Strategic",  uses: "Magnets, lasers, phosphors",          top: ["China", "USA", "Australia"],           fact: "Not actually rare - just hard to separate. China refines ~85% of global supply." }
  ].freeze

  MINES = [
    { name: "Mponeng",        country: "South Africa",       region: "Africa",        commodity: "Gold",                 type: "Underground",            claim: "Deepest mine on Earth - the working face is ~4 km below the surface." },
    { name: "Witwatersrand",  country: "South Africa",       region: "Africa",        commodity: "Gold",                 type: "Underground basin",      claim: "Source of roughly 40% of all gold ever mined in human history." },
    { name: "Bingham Canyon", country: "USA (Utah)",         region: "North America", commodity: "Copper",               type: "Open pit",               claim: "Largest man-made excavation on Earth - clearly visible from orbit." },
    { name: "Carlin Trend",   country: "USA (Nevada)",       region: "North America", commodity: "Gold",                 type: "Open pit + underground", claim: "Largest gold-producing district in North America." },
    { name: "Diavik",         country: "Canada (NWT)",       region: "North America", commodity: "Diamond",              type: "Open pit / underground", claim: "Built on an island in a sub-arctic lake - reached by ice road in winter." },
    { name: "Chuquicamata",   country: "Chile",              region: "South America", commodity: "Copper",               type: "Open pit",               claim: "Over a century of continuous open-pit copper mining." },
    { name: "Cerro Rico",     country: "Bolivia",            region: "South America", commodity: "Silver",               type: "Underground",            claim: "The mountain that bankrolled the Spanish Empire - still mined today." },
    { name: "Mir Mine",       country: "Russia (Yakutia)",   region: "Asia",          commodity: "Diamond",              type: "Open pit",               claim: "A 525 m diamond pit so wide that helicopters avoid the air column above it." },
    { name: "Grasberg",       country: "Indonesia (Papua)",  region: "Asia-Pacific",  commodity: "Gold + Copper",        type: "Open pit + underground", claim: "Largest gold deposit and one of the largest copper deposits on the planet." },
    { name: "Olympic Dam",    country: "Australia (SA)",     region: "Asia-Pacific",  commodity: "Copper, Uranium, Gold", type: "Underground",           claim: "World's largest known polymetallic ore body." }
  ].freeze

  def home
    @featured_gem   = GEMS.sample
    @featured_metal = METALS.sample
    @featured_mine  = MINES.sample
  end

  def gems
    @gems = GEMS
    @mohs_scale = [
      { rank: 1,  mineral: "Talc",     note: "Scratched by a fingernail" },
      { rank: 2,  mineral: "Gypsum",   note: "Fingernail (just barely)" },
      { rank: 3,  mineral: "Calcite",  note: "Copper coin" },
      { rank: 4,  mineral: "Fluorite", note: "Steel knife (easily)" },
      { rank: 5,  mineral: "Apatite",  note: "Steel knife (with effort)" },
      { rank: 6,  mineral: "Orthoclase", note: "Steel file" },
      { rank: 7,  mineral: "Quartz",   note: "Scratches glass" },
      { rank: 8,  mineral: "Topaz",    note: "Scratches quartz" },
      { rank: 9,  mineral: "Corundum", note: "Ruby & sapphire" },
      { rank: 10, mineral: "Diamond",  note: "Scratches everything else" }
    ]
  end

  def metals
    @metals_by_group = METALS.group_by { |m| m[:group] }
  end

  def mines
    @mines_by_region = MINES.group_by { |m| m[:region] }
  end

  def submit_tip
    redirect_to root_path, notice: "Got your tip! Bedrock is a non-functional demo, so nothing was actually saved - but we appreciate the prospecting spirit."
  end
end
