require 'mechanize'
require 'json'

def parse_url(url)
    begin
      retries ||= 0
      agent = Mechanize.new
      agent.user_agent_alias = Mechanize::AGENT_ALIASES.keys.sample
      response = agent.get(url)
    rescue Mechanize::ResponseCodeError => e
      sleep(rand(10))
      retry if (e.response_code == "429" && (retries += 1) < 10 )
    end
end

def fetch_reviews(hotel_id, cut_off_date, start=0)
	reviews_to_display = 500
	api_url = "https://www.expedia.com/ugc/urs/api/hotelreviews/hotel/#{hotel_id}/?_type=json&start=#{start}&items=#{reviews_to_display}&pageName=page.Hotels.Infosite.Information&caller=Expedia&includeRatingsOnly=false&includeRatingsOnly=false"
	api_response = parse_url(api_url)
	resp = JSON.parse api_response.body
	no_of_reviews_in_page = resp["reviewDetails"]["numberOfReviewsInThisPage"]
	
	resp["reviewDetails"]["reviewCollection"]["review"].each do |rev|
		date = Date.parse(rev["reviewSubmissionTime"])
		next if cut_off_date > date
		user_rating = rev["ratingOverall"]
		hotel_responses = rev["managementResponses"]
		puts "Title: #{rev["title"]}\nReviewText: #{rev["reviewText"]}\nSubmissionTime: #{date}\nUserLocation: #{rev["userLocation"]}"
		# show_hotel_responses(hotel_responses) if hotel_responses.size > 0

		if hotel_responses.size > 0
			hotel_responses.each do |res|
			  puts "Hotel Response: #{res['response']}"
			end
		end

		puts "User rating: #{user_rating}"
		puts "\n\n\n"
	end

	# puts no_of_reviews_in_page
	start += 500
	if no_of_reviews_in_page > 0
		fetch_reviews(hotel_id, cut_off_date, start) 
	end
end

hotel_page_url = "https://www.expedia.com/Hiroshima-Hotels-Sheraton-Grand-Hiroshima-Hotel.h4165914.Hotel-Information"

cut_off_date = Date.parse("2019-01-01")


hotel_id = hotel_page_url.scan(/h(\d+)/).flatten[0]

if hotel_page_url.nil?
	puts "No Expedia link for this hotel"
else
	# scrape hotel url
	hotel_page = parse_url(hotel_page_url)
	hotel_name = hotel_page.xpath('//h1[@id="hotel-name"]').text

	fetch_reviews(hotel_id, cut_off_date)
end