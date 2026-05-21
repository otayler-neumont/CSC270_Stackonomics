# Sample specimens for Phase 3 demos (idempotent).
seed_rows = [
  { name: "Diamond",    color: "Colorless / fancy", mohs: 10.0, origin: "Botswana; Russia (Yakutia)", tint: "slate", fact: "Pure carbon — same element as graphite, just stacked differently." },
  { name: "Ruby",       color: "Red",               mohs: 9.0,  origin: "Myanmar (Mogok); Mozambique", tint: "rose", fact: "Red corundum colored by chromium." },
  { name: "Sapphire",   color: "Blue",              mohs: 9.0,  origin: "Sri Lanka; Madagascar", tint: "blue", fact: "Same mineral as ruby — different impurity, different name." },
  { name: "Emerald",    color: "Green",             mohs: 7.5,  origin: "Colombia (Muzo); Zambia", tint: "emerald", fact: "Beryl with chromium. Inclusions are so expected jewelers call them jardin." },
  { name: "Opal",       color: "Play-of-color",     mohs: 6.0,  origin: "Australia (Lightning Ridge)", tint: "fuchsia", fact: "Microscopic silica spheres diffract light to produce that flash." },
  { name: "Amethyst",   color: "Purple",            mohs: 7.0,  origin: "Brazil; Uruguay", tint: "purple", fact: "Quartz with a touch of iron and natural radiation." }
]

seed_rows.each do |attrs|
  Specimen.find_or_create_by!(name: attrs[:name]) do |s|
    s.assign_attributes(attrs)
  end
end

puts "Seeded #{Specimen.count} specimens."
