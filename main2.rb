
require 'google_drive'
require './ebay'
require './exchange'
require "./google_drive_spreadsheet"

# 本番シート
SPREADSHEET_KEY = "1qdUk19VOwMmWjQA0QkxUj8j648M1ndtMoGKVy7chVUc";

# テストシート
#SPREADSHEET_KEY = "14ypg1DfAMYSkFXPJPAbEE4vVaE56X6_XrU83AHH9Pxc"

session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)
config  = ConfigSheet.new(spreadsheet);
inputs  = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);

# 入力シートの更新(eBayの需給バランス取得)
inputs.data.each_with_index{ |x, i|
#	if(x[:enable] != "x")
		puts "No." + i.to_s + " " + x[:ebay_words]
		item = Ebay.new(x[:ebay_words], x[:ebay_invalids], x[:ebay_category]);
                puts item.sold[:count].to_s + " " + item.sell[:count].to_s + " " + item.sold[:market_price].to_s + " " + item.sell[:market_price].to_s
		inputs.update(i, item.sold, item.sell);
		sleep(1);
#	end
}
inputs.save;

# 出力シートの更新(需給バランス値更新)
inputs.data.each_with_index{ |x, i|
	outputs.data.each{ |y|
		outputs.update_ebay(y[:row], x) if x[:words] == y[:words] 
	}
}

outputs.save;

puts "done..."
