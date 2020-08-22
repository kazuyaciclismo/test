
require 'google_drive'
require './ebay'
require './exchange'
require "./google_drive_spreadsheet"

# 本番シート
SPREADSHEET_KEY = "1qdUk19VOwMmWjQA0QkxUj8j648M1ndtMoGKVy7chVUc";

# テストシート
# SPREADSHEET_KEY = "14ypg1DfAMYSkFXPJPAbEE4vVaE56X6_XrU83AHH9Pxc"

session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)
config  = ConfigSheet.new(spreadsheet);
inputs  = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);

# 入力シートの更新(eBayの需給バランス取得)
inputs.data.each_with_index{ |x, i|
	if(x[:enable] != "x")
		puts "No." + i.to_s;
		item = Ebay.new(x[:ebay_words], x[:ebay_invalids], x[:ebay_category]);
		inputs.update(i, item.sold, item.sell);
		sleep(1);
	end
}
inputs.save;

# 出力シートの更新(需給バランス値更新)
inputs.data.each_with_index{ |x, i|
	outputs.data.each{ |y|
		outputs.update_ebay(y[:row], x[:maxprice], x[:order_price], x[:purchase_price], x[:ebay_sold], x[:ebay_sell], x[:ebay_sold_price], x[:ebay_sell_price]) if x[:ebay_sold_url] == y[:url_ebay] 
	}
}

outputs.save;

puts "done..."
