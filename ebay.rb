require 'open-uri'
require 'nokogiri'
require 'uri'
require 'pp'

# 需要URL例
# https://www.ebay.com/sch/i.html?_from=R40&_nkw=SIGMA+SUPER+WIDE+II+24+2.8&_sacat=3323&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&rt=nc&LH_Sold=1&LH_Complete=1
# 供給URL例
# https://www.ebay.com/sch/i.html?_from=R40&_nkw=SIGMA+SUPER+WIDE+II+24+2.8&_sacat=3323&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&rt=nc


# 与えられた検索ワードと除外ワードでeBayを検索する
# 検索は売れた商品の検索、現在売っている商品の検索の二種類
# それぞれ価格の平均値をだして相場を演算
# それぞれの商品数を需要数、供給数として使用


class Ebay
	BaseURL = "https://www.ebay.com/sch/i.html?_i"
	class Sitem
		attr_reader :title, :link, :price
		def initialize(item)
			@title = item.css('.s-item__title').inner_html
			@price = item.css('.s-item__price').inner_html.delete('$')
			@link = item.css('.s-item__link')[0][:href]
		#	puts @title
		#	puts @price
		end
	end

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
		url = BaseURL + URI.encode_www_form(_nkw: @words + " " + @invalids) + '&' + URI.encode_www_form(_sacat: @category) + "&LH_TitleDesc=0&_fsrp=1&LH_BIN=1&rt=nc"
		url = url + "&LH_Sold=1&LH1_Complete=1" if type == :sold
		puts url
		return url;
	end

	# 商品リスト, 商品数、相場の取得
	def getProducts(url)
		count = 0;
		market_price = 0;
		sitems = []
		begin
			charset = nil;
			contents = open(url){ |f| charset = f.charset; f.read }
			doc = Nokogiri::HTML.parse(contents, nil, charset)
			items = doc.css('.s-item__wrapper');
			items.each{ |i| sitems << Sitem.new(i) } if(items != nil)
#			count = doc.css('.srp-controls__count-heading').css('.BOLD')[0].inner_html.to_i;
=begin
			if sitems.length > 0
				sum = 0;
				products[:sitems].each{ |p| sum = sum + p.price }
				market_price = sum / products.length;
			end
=end
		rescue
                        puts "ERROR: #$!"
		end
		return { :count => count, :sitems => sitems, :market_price => market_price };
	end
end

=begin 
ebay = Ebay.new;
puts ebay.getResultCount('https://www.ebay.com/sch/i.html?_from=R40&_trksid=p2334524.m570.l1313&_nkw=AF+Nikkor+28-105+3.5-4.5+-4.5d+-box+-boxed&_sacat=3323&LH_TitleDesc=0&_fsrp=1&_osacat=3323&_odkw=AF+Nikkor+28-105+3.5-4.5+-box+-boxed&LH_BIN=1&LH_Complete=1&LH_Sold=1');
=end

words = 'sigma super wide II 24 2.8'
invalids = '-box -boxed -case -hood -"as is" -"for repair"'
category = '3323'

ebay = Ebay.new(words, invalids, category);
pp ebay;
