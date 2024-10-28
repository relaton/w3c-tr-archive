require 'mechanize'
require 'json'
require 'fileutils'

base_url = 'https://web.archive.org/__wb/calendarcaptures/2?url=http%3A%2F%2Fwww.w3.org%2F2002%2F01%2Ftr-automation%2Ftr.rdf'
agent = Mechanize.new
# agent.request_headers = {
#   'Accept' => '*/*',
# }

(2024..2024).each do |year|
  year_url = "#{base_url}&date=#{year}&groupby=day"
  year_data = JSON.parse agent.get(year_url).body
  year_data['items'].each do |day|
    # next if year == 2021 && day[0] < 1005

    month_day = day[0].to_s.rjust(4, '0')
    day_url = "#{base_url}&date=#{year}#{month_day}"
    day_data = JSON.parse agent.get(day_url).body
    day_data['items'].each do |hour|
      # next if [500, 502, 503, 504].include? hour[1] || hour[0] < 230342 && year == 2021 && day[0] < 1005

      attempts = 0
      begin
        time = hour[0].to_s.rjust(6, '0')
        url = "https://web.archive.org/web/#{year}#{month_day}#{time}/http://www.w3.org/2002/01/tr-automation/tr.rdf"
        file = agent.get(url)
        file_path = "archives/#{year}#{month_day}#{time}.rdf"
        FileUtils.rm file_path
        file.save_as file_path
      rescue StandardError => e
        attempts += 1
        if attempts < 5
          sleep 10 * attempts
          retry
        else
          puts "Failed to fetch #{url}: #{e}"
        end
      end
    end
  end
end
