require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

# 需要URL例
# https://www.ebay.com/sch/i.html?_from=R40&_nkw=SIGMA+SUPER+WIDE+II+24+2.8&_sacat=3323&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&rt=nc&LH_Sold=1&LH_Complete=1
# 供給URL例
# https://www.ebay.com/sch/i.html?_from=R40&_nkw=SIGMA+SUPER+WIDE+II+24+2.8&_sacat=3323&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&rt=nc
# LH_BIN=1		# Buy it now 
# LH_ItemCondition=4	# Condition used

# 与えられた検索ワードと除外ワードでeBayを検索する
# 検索は売れた商品の検索、現在売っている商品の検索の二種類
# それぞれ価格の平均値をだして相場を演算
# それぞれの商品数を需要数、供給数として使用


class Ebay
	BaseURL = "https://www.ebay.com/sch/i.html?"
	class Sitem
		attr_reader :title, :link, :price
		def initialize(item)
			@title = item.css('.s-item__title').inner_html
			# pp item.css('.s-item__price')
			if item.css('.s-item__price').css('.POSITIVE').length == 1
				# @price = item.css('.s-item__price').css('.POSITIVE').inner_html.delete('$').to_f
				@price = item.css('.s-item__price').css('.POSITIVE').inner_html.delete('JPY,').to_f
			else
				#@price = item.css('.s-item__price').inner_html.delete('$').to_f
				@price = item.css('.s-item__price').inner_html.delete('JPY,').to_f
			end
			@link = item.css('.s-item__link')[0][:href]
		end
	end
	attr_reader :sold, :sell;

	# 初期化
        def initialize(words, invalids, category)
                @words = words;		# 検索ワード
		@invalids = invalids;	# 除外ワード
		@category = category;	# カテゴリ

		@sold = getProducts(makeURL(:sold));
		@sell = getProducts(makeURL(:sell));
	end

	# クエリ生成
	# @param type :sold 売れたものの問い合わせ（つまり需要）, :sell 出品数の問い合わせ（つまり供給）
	def makeURL(type)
		url = BaseURL + URI.encode_www_form(_nkw: @words + " " + @invalids) + \
		    '&' + URI.encode_www_form(_sacat: @category) + \
		    "&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&LH_ItemCondition=4&rt=nc";
		url = url + "&LH_Sold=1&LH1_Complete=1" if type == :sold;
		return url;
	end

	# 商品リスト, 商品数、相場の取得
	def getProducts(url)
		count = 0;
		price = 0;
		sitems = []
		ret = {:url => url, :count => 0, :market_price => 0};
		begin
			charset = nil;
			contents = open(url, {:proxy => 'http://163.43.108.114:8080'}){ |f| charset = f.charset; f.read }
			doc = Nokogiri::HTML.parse(contents, nil, charset)
			if doc.css('.srp-controls__count-heading').css('.BOLD')[0] != nil;
				count = doc.css('.srp-controls__count-heading').css('.BOLD')[0].inner_html.to_i;
				items = doc.css('.s-item__wrapper');
				items.each{ |i| sitems << Sitem.new(i) } if(items != nil)
				sitems.each{ |p| price += p.price }
				price /= sitems.length if sitems.length > 0;
				ret[:count] = count;
				ret[:sitems] = sitems;
				ret[:market_price] = price;
			end
		rescue
                        puts "ERROR: #$!"
		end
		return ret;
	end
end

