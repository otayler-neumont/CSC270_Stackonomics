# Pretty-prints the specimens table for demos.
# Run with: bin/rails runner scripts/db-show.rb   (or: ruby bin/rails runner scripts/db-show.rb)

cols = %w[id name tint color mohs origin]
rows = Specimen.order(:id).map do |s|
  [s.id.to_s, s.name.to_s, s.tint.to_s, s.color.to_s, s.mohs.to_s, s.origin.to_s]
end

widths = cols.each_index.map do |i|
  ([cols[i]] + rows.map { |r| r[i] }).map(&:length).max
end

fmt = ->(parts) { parts.each_with_index.map { |p, i| p.ljust(widths[i]) }.join("  ") }

puts
puts "specimens  (#{ActiveRecord::Base.connection.adapter_name}, db=#{ActiveRecord::Base.connection_db_config.database})"
puts fmt.call(cols)
puts widths.map { |w| "-" * w }.join("  ")
rows.each { |r| puts fmt.call(r) }
puts
puts "Total rows: #{Specimen.count}"
