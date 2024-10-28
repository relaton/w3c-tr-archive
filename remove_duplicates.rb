require 'nokogiri'

archive = Nokogiri::XML File.read('merged/00000.rdf')

items = Hash.new { |hash, key| hash[key] = 0 }
archive.root.element_children.each do |element|
  rdf_about = element.attribute('about')&.value
  if rdf_about
    items[rdf_about.sub(/^https?:/, "")] += 1
  end
end

puts items.values.select { |count| count > 1 }.size
