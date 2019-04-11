require 'nokogiri'
require 'open-uri'
require 'pry'
require 'fileutils'
require 'csv'
require 'typhoeus'


class RoyalCopenhagen
	def initialize(source, output)
		@source = CSV.read(source)
		@output = output
	end

	def perform
		# loop through all list in csv
		@source.each_with_index do |row, i|
			# reject the first row of list
			next if i == 0
			url = row[1]
			# parse each url
			doc = parse_url(url)
			# reject if the url is invalid
			next if doc == :missing_url
			doc = doc.at_css("body")
			# extract sku, rc_size, rc_main_material, rc_design_by
			product = extract_informations(doc)
			# create specification html
			specs = format_specifications_with(product)
			# get list of full quality images
			images = parse_images(doc)
			# download all the images in list and save them in directory
			download_images(images, product, 20)
			# sleep()
			write_new_list(row, specs, product, @output)
		end
	end

	private

	def parse_url(url)
		begin
			Nokogiri::HTML(open(url, 'User-Agent' => random_user_agent), nil, "UTF-8")
		rescue OpenURI::HTTPError => ex
			puts "Url is missing"
			:missing
		end
	end

	def extract_informations(doc)
		product = OpenStruct.new
		main = doc.xpath('//div[@id = "product-details-accordion"]//tbody')
		product.sku = main.xpath('//tr[@class="sku"]/td').text
		product.rc_size = main.xpath('//tr[@class="rc_size"]/td').text
		product.rc_main_material = main.xpath('//tr[@class="rc_main_material"]/td').text
		product.rc_design_by = main.xpath('//tr[@class="rc_design_by"]/td').text
		product
	end

	def format_specifications_with(product)
		spec = []
		product.marshal_dump.each do |k, v|
			if k == :sku && v != ""
				spec << "<p><span>產品編號</span>: #{v}</p>"
			elsif k == :rc_size && v != ""
				spec << "<p><span>尺寸</span>: #{v}</p>"
			elsif k == :rc_design_by && v != ""
				spec << "<p><span>設計師</span>: #{v}</p>"
			elsif k == :rc_main_material && v != ""
				spec << "<p><span>材質</span>: #{v}</p>"
			else
				spec << ""
			end
		end

		spec = spec.reject {|x| x.blank?}
		specification = spec.join("\n")
	end

	def parse_images(doc)
		images = doc.search("script").text.scan(/full":"(.*?)",/).flatten
		images = images.map {|image| image.gsub(/\\/, '') }
	end

	def download_images(images, product, concurrency)
		hydra = Typhoeus::Hydra.new(max_concurrency: concurrency)

		images.each do |url|
			request = Typhoeus::Request.new url
			request.on_complete do |response|
				FileUtils.mkdir_p "aadesh/#{product.sku}"
				File.open("aadesh/#{product.sku}/#{url.split('/').last}", "wb") do |saved_file|
					saved_file.write(response.response_body)
				end
			end
			hydra.queue request
		end
		hydra.run
	end

	def write_new_list(row, specs, product, output)
		CSV.open(output, "ab") do |csv|
			puts "writing #{[row[0], row[1], product.rc_size, specs]} to file new_list.csv"
			if product.rc_size.include?('ml')
				csv << [row[0], row[1], product.rc_size, specs]
			elsif product.rc_size.include?('cm')
				csv << [row[0], row[1], "meta-size=#{product.rc_size}", specs]
			else
				csv << [row[0], row[1], product.rc_size, specs]
			end
		end
	end

	def random_user_agent
		ua = [
			"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
			"Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36",
			"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/44.0.2403.157 Safari/537.36",
			"Mozilla/5.0 (Windows NT 5.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2490.71 Safari/537.36",
			"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36",
			"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/63.0.3239.132 Safari/537.36",
			"Mozilla/5.0 (Windows NT 5.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36",
			"Mozilla/5.0 (Windows NT 6.2; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.90 Safari/537.36"
		]
		ua.sample
	end
end