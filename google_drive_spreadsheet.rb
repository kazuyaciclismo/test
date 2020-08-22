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
		@sheet = spreadsheet.worksheet_by_title("input")
		@data = [];
		@rows = [
			:words, 
			:invalids, 
			:ebay_words, 
			:ebay_invalids, 
			:ebay_category, 
			:enable, 
			:maxprice, 
			:order_price, 
			:purchase_price, 
			:ebay_sold, 
			:ebay_sold_url, 
			:ebay_sell, 
			:ebay_sell_url, 
			:ebay_sold_price, 
			:ebay_sell_price, 
			:postage, 
			:priority
		];
		i = 2;
		loop{
			break if @sheet[i,1] == nil or @sheet[i,1] == "";
			rec = Hash.new;
			@rows.each_with_index{ |x,r| rec[x] = @sheet[i, r+1] }
			@data << rec;
			i += 1;
		}
	end

	# 入力シートの需給バランス項目を更新
	def update(num, sold, sell)
		row = num + 1 + 1;	# 項目名 + sheet index offset
		@sheet[row, @rows.index(:ebay_sold) + 1] = sold[:count] if sold[:count]
		@sheet[row, @rows.index(:ebay_sold_url) + 1] = sold[:url];
		@sheet[row, @rows.index(:ebay_sold_price) + 1] = sold[:market_price] if sold[:market_price]
		@sheet[row, @rows.index(:ebay_sell) + 1] = sell[:count] if sell[:count]
		@sheet[row, @rows.index(:ebay_sell_url) + 1] = sell[:url];
		@sheet[row, @rows.index(:ebay_sell_price) + 1] = sell[:market_price] if sell[:market_price]
	end

	# シートの保存
	def save 
		@sheet.save
	end
end

# 出力データシート
class OutputSheet
	attr_reader :data;
	def initialize(spreadsheet)
		@sheet = spreadsheet.worksheet_by_title("output")
		@data = [];
		@products = [];
		i = 2;
		loop{
			url = @sheet[i,3];
			url_ebay = @sheet[i,17];	# eBay需要URL
			break if url == nil or url == "";
			@data << {:row => i, :url => url, :url_ebay => url_ebay}
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
		@sheet[row, 1] = product.date.new_offset('+9:00').strftime("%Y/%m/%d %H:%M");	# 収集日時
		@sheet[row, 2] = product.title;				# 商品タイトル
		@sheet[row, 3] = product.link;				# 商品URL
		@sheet[row, 4] = product.current;			# 現在価格
		@sheet[row, 5] = product.immediate;			# 即決価格
		@sheet[row, 6] = product.seller;			# 出品者
		@sheet[row, 7] = product.seller_url;			# 出品者URL
		@sheet[row, 8] = product.finish;			# 終了日時
		@sheet[row, 9] = product.data[:words];			# 検索ワード
		@sheet[row, 10] = product.invalids;			# 除外ワード
		@sheet[row, 11] = "";					# 入札予定
		@sheet[row, 12] = "";					# 予測収益
		@sheet[row, 13] = product.data[:maxprice];		# 価格指定
		@sheet[row, 14] = product.data[:order_price];		# 購入相場
		@sheet[row, 15] = product.data[:purchase_price];	# 入札上限 
		@sheet[row, 16] = product.data[:ebay_sold];		# 需要
		@sheet[row, 17] = product.data[:ebay_sold_url];		# 需要URL
		@sheet[row, 18] = product.data[:ebay_sell];		# 供給
		@sheet[row, 19] = product.data[:ebay_sell_url];		# 供給URL
		@sheet[row, 20] = product.data[:ebay_sold_price];	# 落札相場
		@sheet[row, 21] = product.data[:ebay_sell_price];	# 出品相場
		@sheet[row, 22] = product.data[:postage];		# 送料
		@sheet[row, 23] = product.data[:priority];		# 優先順位 
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

	def update_ebay(row, maxprice, order_price, purchase_price, sold, sell, sold_price, sell_price)
		@sheet[row, 13] = maxprice;
		@sheet[row, 14] = order_price;
		@sheet[row, 15] = purchase_price;
		@sheet[row, 16] = sold;		# 需要
		@sheet[row, 18] = sell;	        # 供給
		@sheet[row, 20] = sold_price;	# 落札相場
		@sheet[row, 21] = sell_price;	# 出品相場
	end

	# シートに商品情報をストア
	def save 
		@sheet.save
	end
end

#str = sheets_config[1,1]
#p str
#sheets_config.save
