require 'google_drive'


# 設定
class ConfigSheet
	attr_reader :data
	def initialize(spreadsheet)
		sheet = spreadsheet.worksheet_by_title("config")
		@data = {};
		i = 1;
		loop{
			key = sheet[i,1];
			val = sheet[i,2];
			break if key == nil or key == "";
			@data[key.to_sym] = val;
			i += 1;
		}
	end
end

# 除去リスト
class BansSheet
	attr_reader :users, :ids, :words
	def initialize(spreadsheet)
		sheet = spreadsheet.worksheet_by_title("black")
		@users = [];
		@ids = [];
		@words = [];
		load(sheet, @users, "出品者リスト");
		load(sheet, @ids, "オークションiD");
		load(sheet, @words, "除外キーワード");
	end
	def load(sheet, ary, key)
		col = 1;
		loop{
			val = sheet[1,col]
			break if val == nil or val == "";
			if val == key 
				row = 2;
				loop{
					val = sheet[row,col]
					break if val == nil or val == "";
					ary << val;
					row += 1;
				}
				break;
			end
			col += 1;
		}
	end
end

# 入力データシート
class InputSheet
	attr_reader :data
	def initialize(spreadsheet)
		sheet = spreadsheet.worksheet_by_title("input")
		@data = [];
		i = 2;
		loop{
			break if sheet[i,1] == nil or sheet[i,1] == "";
			@data << {:words => sheet[i,1], :invalids => sheet[i,2], :ebay_words => sheet[i,3], :ebay_invalids => sheet[i,4], :ebay_category => sheet[i,5], :enable => sheet[i,6], :maxprice => sheet[i,7].delete(",").to_i, :order_price => sheet[i,8], :purchase_price => sheet[i,9], :ebay_sold => sheet[i,10], :ebay_sold_url => sheet[i,11], :ebay_sell => sheet[i,12], :ebay_sell_url => sheet[i,13], :ebay_sold_price => sheet[i,14], :ebay_sell_price => sheet[i,15], :postage => sheet[i,16], :priority => sheet[i,17]}
			i += 1;
		}
	end
end

# 出力データシート
class OutputSheet
	def initialize(spreadsheet)
		@sheet = spreadsheet.worksheet_by_title("output")
		@data = [];
		@products = [];
		i = 2;
		loop{
			url = @sheet[i,3];
			break if url == nil or url == "";
			@data << {:row => i, :url => url}
			i += 1;
		}
	end

	# シートに記載がある商品の場合は更新する
	def update(product)
		row = check(product);
		if(row != nil)
			@sheet[row, 1] = product.date.new_offset('+9:00').strftime("%Y/%m/%d %H:%M");
			@sheet[row, 4] = product.current;
			@sheet[row, 5] = product.immediate;
			@sheet[row, 8] = product.finish
			return true;
		end
		return false;
	end

	# 新着商品を末尾に追加
	def add_new(product)
		row = lastRow;
		@sheet[row, 1] = product.date.new_offset('+9:00').strftime("%Y/%m/%d %H:%M");
		@sheet[row, 2] = product.title;
		@sheet[row, 3] = product.link;
		@sheet[row, 4] = product.current;
		@sheet[row, 5] = product.immediate;
		@sheet[row, 6] = product.seller;
		@sheet[row, 7] = product.seller_url;
		@sheet[row, 8] = product.finish
		@sheet[row, 9] = product.data[:words];
		@sheet[row, 10] = product.invalids;
		@sheet[row, 11] = product.data[:maxprice];
		#@sheet[row, 12] = product.data[:maxprice]; # 入札予定
		#@sheet[row, 13] = product.data[:maxprice];  # 予測収益
		@sheet[row, 14] = product.data[:order_price];  # 価格指定
		@sheet[row, 15] = product.data[:sold];
		@sheet[row, 16] = product.data[:sold_url];
		@sheet[row, 17] = product.data[:sell];
		@sheet[row, 18] = product.data[:sell_url];
	end

	# 既存or新規チェック
	def check(product)
		@data.each{ |x|	return x[:row] if x[:url] == product.link }
		return nil;
	end

	def lastRow
		i=2;
		loop{
			return i if @sheet[i,1] == "" or @sheet[i,1] == nil;
			i += 1;
		}
	end

	# シートに商品情報をストア
	def save 
		@sheet.save
	end
end

#str = sheets_config[1,1]
#p str
#sheets_config.save
