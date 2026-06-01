# Idempotent demo data for Phase 5.
#
# Creates a few members, gives them specimens, and sprinkles in likes and
# comments so a fresh database (local SQLite or the prod Postgres volume)
# demos with a populated community instead of an empty grid.
#
# All demo accounts use the same password below so they're easy to show off.
DEMO_PASSWORD = "rockhound"

# --- Members ---------------------------------------------------------------
users = [
  { name: "Ada Quartz",   email_address: "ada@bedrock.dev" },
  { name: "Linus Geode",  email_address: "linus@bedrock.dev" },
  { name: "Grace Garnet",  email_address: "grace@bedrock.dev" }
].map do |attrs|
  User.find_or_create_by!(email_address: attrs[:email_address]) do |u|
    u.name = attrs[:name]
    u.password = DEMO_PASSWORD
    u.password_confirmation = DEMO_PASSWORD
  end
end

ada, linus, grace = users

# --- Specimens (owned) -----------------------------------------------------
seed_rows = [
  { name: "Diamond",    color: "Colorless / fancy", mohs: 10.0, origin: "Botswana; Russia (Yakutia)", tint: "slate", fact: "Pure carbon - same element as graphite, just stacked differently.", owner: ada },
  { name: "Ruby",       color: "Red",               mohs: 9.0,  origin: "Myanmar (Mogok); Mozambique", tint: "rose", fact: "Red corundum colored by chromium.", owner: ada },
  { name: "Sapphire",   color: "Blue",              mohs: 9.0,  origin: "Sri Lanka; Madagascar", tint: "blue", fact: "Same mineral as ruby - different impurity, different name.", owner: linus },
  { name: "Emerald",    color: "Green",             mohs: 7.5,  origin: "Colombia (Muzo); Zambia", tint: "emerald", fact: "Beryl with chromium. Inclusions are so expected jewelers call them jardin.", owner: linus },
  { name: "Opal",       color: "Play-of-color",     mohs: 6.0,  origin: "Australia (Lightning Ridge)", tint: "fuchsia", fact: "Microscopic silica spheres diffract light to produce that flash.", owner: grace },
  { name: "Amethyst",   color: "Purple",            mohs: 7.0,  origin: "Brazil; Uruguay", tint: "purple", fact: "Quartz with a touch of iron and natural radiation.", owner: grace }
]

specimens = seed_rows.map do |attrs|
  owner = attrs.delete(:owner)
  specimen = Specimen.find_or_create_by!(name: attrs[:name]) do |s|
    s.assign_attributes(attrs)
  end
  # Backfill ownership for any specimen that predates Phase 5 (e.g. rows already
  # in the persistent prod volume) without clobbering a real owner.
  specimen.update!(user: owner) if specimen.user.nil?
  specimen
end

by_name = specimens.index_by(&:name)

# --- Likes -----------------------------------------------------------------
likes = [
  [linus, "Diamond"], [grace, "Diamond"], [ada, "Sapphire"],
  [grace, "Emerald"], [ada, "Opal"], [linus, "Amethyst"]
]
likes.each do |user, specimen_name|
  next unless (specimen = by_name[specimen_name])

  specimen.likes.find_or_create_by!(user: user)
end

# --- Comments --------------------------------------------------------------
comments = [
  [linus, "Diamond",  "Stunning clarity - was this an estate find or a show purchase?"],
  [grace, "Diamond",  "Where in Botswana did this come from? The Orapa mine?"],
  [ada,   "Sapphire", "Love the color saturation. Any heat treatment on this one?"],
  [ada,   "Opal",     "That play-of-color is unreal. Lightning Ridge never misses."]
]
comments.each do |user, specimen_name, body|
  next unless (specimen = by_name[specimen_name])

  specimen.comments.find_or_create_by!(user: user, body: body)
end

puts "Seeded #{User.count} users, #{Specimen.count} specimens, #{Like.count} likes, #{Comment.count} comments."
puts "Demo login: ada@bedrock.dev / #{DEMO_PASSWORD}"
