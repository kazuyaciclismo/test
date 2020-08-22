require "./yahoo_auction"
require "./google_drive_spreadsheet"
require "./searched_db"

# 本番シート
SPREADSHEET_KEY = "1qdUk19VOwMmWjQA0QkxUj8j648M1ndtMoGKVy7chVUc";
SEARCHED_DB = "searched.txt"

# テストシート
#SPREADSHEET_KEY = "14ypg1DfAMYSkFXPJPAbEE4vVaE56X6_XrU83AHH9Pxc"
#SEARCHED_DB = "searched_test.txt"

session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

config  = ConfigSheet.new(spreadsheet);
bans    = BansSheet.new(spreadsheet);
inputs  = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);
searched = SearchedDB.new(SEARCHED_DB);

inputs.data.each{ |x|
	if(x[:enable] != "x")
		invalids = x[:invalids] + ' ' + bans.words.join(' ');
		puts "Now Searching '" + x[:words] + "' without '" + invalids.strip + "' limit price " + x[:maxprice].to_s
		list = YahooAuctionList.new(x, invalids.strip, config.data[:SearchLimit].to_i, config.data[:AuctionCategory].to_i);
		filtered = [];
		#  得られたリストから、まず出力シートにあるデータについて現在価格などを更新
		list.products.each{ |p|	
			if(outputs.update(p) == false) 
				# 出力シートに記載のないものは検索済みか確認
				if searched.check(p.id) == false and p.finish != ""	# 終了日時が無いものは数分で終了するアイテム
					filtered << p		# 新規アイテム
				else
					puts p.id.to_s + " is already checked";
				end
			end
			# 重複しても良いので検出したアイテムはすべて登録
			searched.add(p.id, p.finish) if p.finish != ""		
		}
		#  残ったもので出品者を出力シートに追加(ただし出品者チェック済み)
		filtered.each{ |p| 
			# 除外出品者、または除外オークションIDでなければ新規アイテムとして記録
			if p.seller?(bans.users) and p.ids?(bans.ids) and p.rating.to_f >= config.data[:SellerRateLimit].to_f 
				if p.data[:maxprice].delete(',').to_i > p.current.to_i or p.data[:order_price].delete(',').to_i > p.current.to_i or p.data[:purchase_price].delete(',').to_i > p.current.to_i
					outputs.add_new(p)
					puts "Add new product: " + p.title;
				else
					puts "price limit:" + p.current.to_s;
				end
			end
		}
		sleep(5);
	end
}
searched.save;
outputs.save
puts "done..."

