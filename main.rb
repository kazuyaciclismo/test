require "./yahoo_auction"
require "./google_drive_spreadsheet"
require "./searched_db"

SPREADSHEET_KEY = "1qdUk19VOwMmWjQA0QkxUj8j648M1ndtMoGKVy7chVUc";
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

config  = ConfigSheet.new(spreadsheet);
bans    = BansSheet.new(spreadsheet);
inputs  = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);
searched = SearchedDB.new("searched.txt");

inputs.data.each{ |x|
	invalids = x[:invalids] + ' ' + bans.words.join(' ');
	puts "Now Searching '" + x[:words] + "' without '" + invalids.strip + "' limit price " + x[:maxprice].to_s
	list = YahooAuctionList.new(x, invalids.strip, config.data[:SearchLimit].to_i, config.data[:AuctionCategory].to_i);
	filtered = [];
	# pp list;
	# 検索結果の扱い
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
		searched.add(p.id, p.finish) if p.finish != ""		# 重複しても良いので検出したアイテムはすべて登録
	}
	#  残ったもので出品者を出力シートに追加(ただし出品者チェック済み)
	filtered.each{ |p| 
		if p.seller?(bans.users) and p.ids?(bans.ids) # 除外出品者、または除外オークションIDでなければ新規アイテムとして記録
			outputs.add_new(p)
			puts "Add new product: " + p.title;
		end
	}
	sleep(5);
}
# searched.save;
# outputs.save
puts "done..."

