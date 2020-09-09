
require "./mercari"
require "./google_drive_spreadsheet"
require "./searched_db"

# 本番シート
SPREADSHEET_KEY = "1qdUk19VOwMmWjQA0QkxUj8j648M1ndtMoGKVy7chVUc";
SEARCHED_DB = "searched_mercari.txt"
# 
# テストシート
#SPREADSHEET_KEY = "14ypg1DfAMYSkFXPJPAbEE4vVaE56X6_XrU83AHH9Pxc"
#SEARCHED_DB = "searched_mercari_test.txt"
# 
puts DateTime.now
session = GoogleDrive::Session.from_config('config.json')
spreadsheet = session.spreadsheet_by_key(SPREADSHEET_KEY)

config  = ConfigSheet.new(spreadsheet);
inputs  = InputSheet.new(spreadsheet);
outputs = OutputSheet.new(spreadsheet);
searched = SearchedDB.new(SEARCHED_DB);

inputs.data.each{ |x|
	if(x[:enable] != "x" and x[:purchase_price].to_i > 0)
		puts "Now Searching '" + x[:words] + "' limit price " + x[:purchase_price].to_s
		list = MercariList.new(x, config.data[:SearchLimit].to_i, config.data[:MercariCategory]);
		filtered = [];
		#  得られたリストから、まず出力シートにあるデータについて現在価格などを更新
		list.products.each{ |p|	
			if(outputs.check2(p) == nil) 
				# 出力シートに記載のないものは検索済みか確認
				if searched.check(p.id) == false 
					filtered << p		# 新規アイテム
				else
					puts p.id.to_s + " is already checked";
				end
			end
			# 重複しても良いので検出したアイテムはすべて登録
			searched.add(p.id) 
		}
		#  残ったもので出品者を出力シートに追加
		filtered.each{ |p| 
                        puts p.title
                        puts p.price
                        puts p.data[:purchase_price].delete(',').to_i
			if( p.price.to_i < p.data[:purchase_price].delete(',').to_i)
				outputs.add_new_item(p)
				puts "Add new product: " + p.title;
			end
		}
		sleep(5);
	end
}
searched.save;
outputs.save
puts "done..."

