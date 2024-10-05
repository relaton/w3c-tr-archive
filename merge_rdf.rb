# require 'benchmark'
require 'nokogiri'

# archives = Dir['archives/*.rdf'].sort

# Load the older RDF/XML file
# older_file_path = archives[0]
# older_doc = Nokogiri::XML(File.read(older_file_path))

# Benchmark.bm do |x|
def merge_rdf(archives, remove_old_files: false)
  archives.each_slice(2).with_index do |(older_file_path, newer_file_path), idx|
    # Load the older RDF/XML file
    older_doc = Nokogiri::XML(File.read(older_file_path))
    File.delete(older_file_path) if remove_old_files

    if newer_file_path.nil?
      merged_file_path = "merged/#{idx}.rdf"
      File.write(merged_file_path, older_doc.to_xml)
      puts "Copy #{older_file_path} to #{merged_file_path}"
      next
    end

    # Load the newer RDF/XML file
    # newer_file_path = archive
    newer_doc = Nokogiri::XML(File.read(newer_file_path))
    File.delete(newer_file_path) if remove_old_files

    # Create a hash to store rdf:about attributes from the newer file
    newer_elements = {}
    # x.report("Store new elements to hash #{newer_file_path}") do
      newer_doc.root.element_children.each do |element|
        rdf_about = element.attribute('about')&.value
        newer_elements[rdf_about] = element if rdf_about
      end
    # end

    # Replace or add elements in the older document
    # x.report("Replace elements in the older document") do
      older_doc.root.element_children.each do |element|
        rdf_about = element.attribute('about')&.value
        if rdf_about && newer_elements[rdf_about]
          element.replace(newer_elements[rdf_about])
          newer_elements.delete(rdf_about)
        end
      end
    # end

    # Add remaining new elements to the older document
    # x.report("Add new elements to the older document") do
      newer_elements.each_value do |element|
        older_doc.root.add_child(element)
      end
    # end

    # Add new namespaces from the newer document to the older document
    # x.report("Add new namespaces to the older document") do
      newer_doc.root.namespace_definitions.each do |ns|
        unless older_doc.root.namespace_definitions.any? { |old_ns| old_ns.href == ns.href }
          older_doc.root.add_namespace_definition(ns.prefix, ns.href)
        end
      end
    # end
    merged_file_path = "merged/#{idx}.rdf"
    File.write(merged_file_path, older_doc.to_xml)
    puts "Merge #{older_file_path} and #{newer_file_path} into #{merged_file_path}"
  end
end

archives = Dir['archives/*.rdf'].sort
merge_rdf(archives)

while Dir['merged/*.rdf'].size > 1
  archives = Dir['merged/*.rdf'].sort
  merge_rdf(archives, remove_old_files: true)
end

# Save the merged document
# merged_file_path = 'merged.rdf'
# File.write(merged_file_path, older_doc.to_xml)

# puts "Merged #{older_file_path} and #{newer_file_path} into #{merged_file_path}"
