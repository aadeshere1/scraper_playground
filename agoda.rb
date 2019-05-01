require 'nokogiri'
require 'open-uri'
require 'json'
require 'rest-client'


def get_reviews(hotel_id, page)
	uri = 'https://www.agoda.com/NewSite/en-us/Review/HotelReviews'
	header = {'Content-Type': 'application/json', 'accept': 'application/json'}
	payload = {
				"hotelId": hotel_id.to_i,
				"pageNo": page,
				"pageSize":100,
				"sorting":1,
				"isReviewPage": false,
				"isCrawlablePage": true
			}
	# RestClient.proxy = "http://45.33.70.209:55555/"
	response = RestClient.post uri, payload, header
	doc = JSON.parse response
end


hotel_page_url = "https://www.agoda.com/the-paramount-hotel/hotel/seattle-wa-us.html?cid=-218"
cut_off_date = Date.parse("2000-01-01")

if hotel_page_url.nil?
	puts "No agoda link for this hotel"
else
	#parse url with nokogiri openuri
	hotel_page = Nokogiri::HTML(open(hotel_page_url))
	hotel_link = hotel_page.xpath('//link[@id="propertyApiPreload"]/@href').text()
	hotel_id = hotel_link.scan(/hotel_id=([0-9].*)&/).flatten.first

	all_reviews = []
	comments = ["startingNonEmpty"]

	start = 1
	while !comments.empty?
		reviews = get_reviews(hotel_id, start)
		comments = reviews["commentList"]["comments"]
		puts all_reviews
		all_reviews << comments
		start = start+1
	end

	all_reviews.flatten!

	all_reviews.each do |review|
		date = Date.parse review["reviewDate"]

		next if cut_off_date > date

		customer = review["reviewerInfo"]["displayMemberName"]
		country = review["reviewerInfo"]["countryName"]
		room_type = review["reviewerInfo"]["roomTypeName"]
		travel_type = review["reviewerInfo"]["reviewGroupName"]
		review_title = review["reviewTitle"]
		positive_review = review["reviewPositives"]
		negative_review = review["reviewNegatives"]
		review_comment = review["reviewComments"]
		rating = review["rating"]

		puts "date: #{date}"
		puts "customer: #{customer}"
		puts "country: #{country}"
		puts "Room Type: #{room_type}"
		puts "Travel type: #{travel_type}"
		puts "Review title: #{review_title}"
		puts "Review positive: #{positive_review}"
		puts "Review negative: #{negative_review}"
		puts "Review comment: #{review_comment}"
		puts "Rating: #{rating}"
		puts "\n\n\n"
	end
end