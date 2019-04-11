require 'open-uri'
require 'nokogiri'

class UpcService
	attr_accessor :upc, :url, :doc
	def initialize(upc)
		@upc = upc
		@url = url
		@doc = parse_url
	end

	def call
		title = get_upc_title
		link = get_url
		uri_parse = URI.parse link
		unless uri_parse.scheme == "http" || uri_parse.scheme == "https"
			link = "https://www.amazon.com/#{link}"
		end
		return {name: title, link: link}
	end

	private
	def url
		@url = "https://www.amazon.com/s/ref=nb_sb_noss?url=search-alias%3Daps&field-keywords=#{upc}"
	end

	def parse_url
		user_agent = random_user_agent
		Nokogiri::HTML(open(@url, 'User-Agent' => user_agent), nil, "UTF-8")
	end

	def get_upc_title
		title = @doc.xpath('//div[contains(@class, "s-item-container")]//h2[contains(@class, "access-title")]//text()').to_s
		if title.empty?
			title = @doc.xpath('//div[contains(@class, "result-list")]//h5//span//text()').to_s
		end
		title
	end

	def get_url
		title_url = @doc.xpath('//div[contains(@class, "s-item-container")]//h2[contains(@class, "access-title")]/parent::a/@href').to_s
		if title_url.empty?
			title_url = @doc.xpath('//div[contains(@class, "result-list")]//h5//a/@href').to_s
		end
		title_url
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