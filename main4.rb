require "./yahoo_auction"
require "./google_drive_spreadsheet"

# 本番シート
SPREADSHEET_KEY = "1qdUk19VOwMmWjQA0QkxUj8j648M1ndtMoGKVy7chVUc";
SEARCHED_DB = "searched.txt"

# テストシート
# SPREADSHEET_KEY = "14ypg1DfAMYSkFXPJPAbEE4vVaE56X6_XrU83AHH9Pxc"
# SEARCHED_DB = "searched_test.txt"
# 
#
puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

outputs = OutputSheet.new(spreadsheet);

outputs.data.each{ |x|
	if x[:url].include?('yahoo')
		puts "Now Checking..." + x[:url];
		status = YahooAuctionProduct.CheckAlive(x[:url]);
		puts status.to_s;
		outputs.set_status_mark(x[:row], status);
		sleep(2);
	end
}

outputs.save
puts "done..."



