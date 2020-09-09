require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

#
# Mercariの検索と商品情報のスクレイピングを行う
# 					2020/09/05
#
#
# https://www.mercari.com/jp/search/?sort_order=&keyword=nikon+md-2&category_root=&brand_name=&brand_id=&size_group=&price_min=&price_max=20000&item_condition_id%5B1%5D=1&item_condition_id%5B2%5D=1&item_condition_id%5B3%5D=1&status_on_sale=1
class MercariList 
        URL = 'https://www.mercari.com/jp/search/?'

	attr_reader :products
        # 初期化(検索と商品情報の抽出)
        def initialize(data, limit, category)
		@data = data;
                @limit = limit; # 最大検索数
                @count = 0;     # ヒット数
                @products = []; # 商品リスト
                @request = 50;  # 1回あたりの表示数
		@category = category;
                page = 1;
                while @products.size < @limit
                        list = getList(page);
                        @products += list;
                        break if list.size < @request;	
                        page += 1;
			puts "sleep...";
			sleep(3);
                end
        end

        # 商品リスト取得
        # @param offset オフセット
        # @return 商品リスト配列
        def getList(page)
                list = [];
		url = URL + URI.encode_www_form(keyword: @data[:words]);
		url = url + '&category_root=7&category_child=' + @category;
		url = url + '&item_condition_id%5B1%5D=1&item_condition_id%5B2%5D=1&item_condition_id%5B3%5D=1&status_on_sale=1'
		url = url + '&price_max=' + @data[:purchase_price].delete(',').to_s; 
		url = url + '&' + URI.encode_www_form(page: page);
		puts "query: " + url;
                begin
			charset = nil
                        contents = open(url){ |f| charset = f.charset; f.read }
			date = DateTime.now
                        doc = Nokogiri::HTML.parse(contents, nil, charset)
			if doc.css('.search-result-number')[0] != nil
				doc.css('.items-box').each{ |p| 
					product = Product.new(p, @data, date);
					if product.check == true;
						list << product 
						sleep(2)
					end
				}
			else
				puts "Item not found...";
			end
                rescue
                        puts "ERROR: #$!"
                end
                return list;
        end
end

class Product
	URL = 'https://www.mercari.com'
	attr_reader :data, :title, :link, :seller, :seller_url, :seller_good, :seller_bad, :date, :id, :price
        # 初期化
        # @param product 商品情報
        # @param data input情報
        # @param data 共通除外キーワードを含む除外キーワード
        # @param date 検索日時
        def initialize(product, data, date)
		@data = data;
		@date = date;
		@link = URL + product.css('a')[0][:href];					# 商品リンク
		@title = product.css('.items-box-name')[0].inner_html				# 商品タイトル
		@price = product.css('.items-box-price')[0].inner_html.delete(',¥').to_i;	# 商品価格
		@sold = (product.css('.item-sold-out-badge').size > 0 ? :SOLD: :SELL);		# 販売状態
		@id = auctionID;
		load if check == true and  @sold == :SELL
        end

	def check
		puts "check: " + @title;
		puts "words: " + @data[:words];
		@data[:words].split(/\s/).each{ |w| return false if @title.downcase.include?(w.downcase) == false }
		return true;
	end

	# 商品詳細情報のロード
	def load
		puts "load...: " + @title;
                begin
			charset = nil
                        contents = open(@link){ |f| charset = f.charset; f.read }
                        doc = Nokogiri::HTML.parse(contents, nil, charset)
			p = doc.css('.item-detail-table')[0].css('td')
			@seller = p.css('a')[0].inner_html
			@seller_url = p.css('a')[0][:href]
			@seller_good = p.css('.item-user-ratings')[0].css('span').inner_html;
			@seller_bad = p.css('.item-user-ratings')[1].css('span').inner_html;
                rescue
                        puts "ERROR: #$!"
                end
	end

	# URLからオークションID抽出
	def auctionID
		id = "-";
		id = $1 if /items\/(.+)\// =~ @link;
		return id;
	end
end

=begin
data = { :words => "nikon md-2", :purchase_price => "20,000" }
limit = 10;
list = MercariList.new(data, limit);

pp list.products
=end
