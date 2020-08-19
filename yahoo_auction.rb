require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

#
# Yahoo Auctionの検索と商品情報のスクレイピングを行う
# 					2020/08/10
#

=begin
Product
        Product__detail
                Product__infoTable
                        Product__title
                                Product__titleLink      # タイトル、リンク
                        Product__seller [title] [href]

                Product__priceInfo
                        Product__price [現在]
                                Product__priceValue u-textRed
                        Product__price [即決]
                                Product__priceValue
=end

class YahooAuctionList
        YahooAuctionURL = 'https://auctions.yahoo.co.jp/search/search?'

	attr_reader :products
        # 初期化(検索と商品情報の抽出)
        def initialize(data, invalids, limit, category=nil)
		@data = data;
		@invalids = invalids; #除外ワード
                @limit = limit; # 最大検索数
		@category = category; # 検索カテゴリ
                @count = 0;     # ヒット数
                @products = []; # 商品リスト
                @charset = nil; # 文字コード
                @request = 50;  # 1回あたりの表示数
                offset = 1;
                while @products.size < @limit
                        list = getList(offset);
                        @products += list;
                        break if list.size < @request;	
                        offset += @request;
			puts "sleep...";
			sleep(5);
                end
        end

        # 商品リスト取得
        # @param offset オフセット
        # @return 商品リスト配列
        def getList(offset)
                list = [];
		# url = YahooAuctionURL + URI.encode_www_form(va: @words) + '&' + URI.encode_www_form(ve: @invalids) + '&b=' + offset.to_s + '&n=' + @request.to_s + '&mode=2&ei=UTF-8&new=1&s1=new&f_adv=1&fr=auc_adv&f=0x4'; # 詳細表示、UTF8、新着、新着順表示
		url = YahooAuctionURL + URI.encode_www_form(va: @data[:words]) + '&' + URI.encode_www_form(ve: @invalids) + '&b=' + offset.to_s + '&n=' + @request.to_s + '&mode=2&ei=UTF-8&new=1&s1=new'; # 詳細表示、UTF8、新着、新着順表示
		url = url + '&aucmaxprice=' + @data[:maxprice].to_s if @data[:maxprice] != nil
		url = url + '&auccat=' + @category.to_s if @category != nil
		puts "query: " + url;
                begin
                        contents = open(url){ |f| @charset = f.charset; f.read }
			date = DateTime.now
                        doc = Nokogiri::HTML.parse(contents, nil, @charset)
			if checkCount(doc);
                        	doc.css('.Product').each{ |p| 
					# product = YahooAuctionProduct.new(p, @data[:words], @invalids, @data[:maxprice], date);
					# list << product if product.valid?; 
					list << YahooAuctionProduct.new(p, @data, @invalids, date);
				}
			end
                rescue
                        puts "ERROR: #$!"
                end
                return list;
        end

	# 
	def checkCount(doc)
		auction = doc.css('.SearchMode').css('.Tab__item')[1].css('.Tab__subText').inner_html
		flat = doc.css('.SearchMode').css('.Tab__item')[2].css('.Tab__subText').inner_html
		return true if auction != "" or flat != ""
		return false;
	end
end

class YahooAuctionProduct
	attr_reader :title, :link, :seller, :seller_url, :current, :immediate, :finish, :data, :invalids, :date, :id
        # 初期化
        # @param product 商品情報
        def initialize(product, data, invalids, date)
               @title = product.css('.Product__titleLink')[0][:title]           # 商品タイトル
               @link = product.css('.Product__titleLink')[0][:href]             # 商品リンク
               @seller = product.css('.Product__seller')[0][:title]             # 出品者名
               @seller_url = product.css('.Product__seller')[0][:href]          # 出品者リンク
               @current = product.css('.Product__priceValue').first.inner_html.delete('円'); # 現在価格
               @immediate = product.css('.Product__priceValue')[1] == nil ? "-" : product.css('.Product__priceValue')[1].inner_html.delete('円');  # 即決価格
	       @finish = product.css('.Product__otherInfo').css('.u-textGray').inner_html;
	       @finish = $1 if /([0-9\s:\/]+)/ =~ @finish		        # 終了日時(ただし残り数分になると表示されない)
	       @data = data;
	       @invalids = invalids;
	       @date = date;
	       @id = auctionID
        end

        # 除外出品者チェック
        # @param names 出品者リスト
        def seller?(names)
		names.each{ |x| return false if x == @seller }
		return true;
        end

        # 除外IDチェック
        # @param ids オークションIDリスト
        def ids?(ids)
		ids.each{ |x| return false if x == @id }
		return true;
        end

	# 本文検索でヒットした可能性があるため改めてタイトル内にすべての検索ワードが含まれているか確認
	# 大文字小文字は無視
	def valid?
		puts "check for " + @title  + " with " + @data[:words];
		@words.split(' ').each{ |w| 
			if /#{w}/i =~ @title then
			else 
				puts "invalid: " + w;
				return false 
			end
		}

		puts "valid"
		return true;
	end

	# URLからオークションID抽出
	def auctionID
		id = "-";
		id = $1 if /auction\/(.+)\z/ =~ @link;
		return id;
	end
end

#yahoo = YahooAuctionList.new("キャノン", "ジャンク", nil, 30);
#yahoo = YahooAuctionList.new("canon ae-1 black 50 1.4", "ジャンク", nil, 30);
#yahoo = YahooAuctionList.new("canon ae-1 black", "ジャンク", nil, 30, 550, 23640);
# pp yahoo;


