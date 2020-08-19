require 'date'
require 'pp'

class SearchedDB
	# 初期化
	#  ファイルの読み込み、リストの初期化
	# @param filename リスト格納ファイル名
	def initialize(filename)
		@name = filename;
		@list = []# ファイルから読み込んでリストを初期化
		if File.exist?(@name)  
			File.readlines(@name).each{ |line|
				rec = line.split(/,/)
				@list << { :id => rec[0], :deadtime => rec[1].strip }
			}
			clean;	   # 終了日時を過ぎているアイテムは削除
		end
	end

	# リストの追加
	# @param id オークションID
	# @param deadtime 終了日時(DateTime)
	def add(id, deadtime)
		@list << { :id => id, :deadtime => deadtime }
	end

	# IDの存在確認
	# @param id オークションID
	# @return true: 検索済み false: 新規アイテム
	def check(id)
		@list.each{ |x| return true if  x[:id] == id }
		return false;
	end

	# 終了日時 + 2weekを過ぎているアイテムはリストから削除
	def clean
		dst = []
		now = DateTime.now + Rational(9, 24) 
		@list.each{ |x| 
			if x[:deadtime] != ""		# 終了日時が存在しない場合は残り数分
				dead = DateTime.parse(x[:deadtime]) + 14;	# 終了日時から2週間立ったら消す(追加しない)
				dst << x if dead > now 
			end
		}
		@list = dst;
	end

	# 検索履歴DBの保存
	def save
		File.open(@name,"w") { |f|
			@list.each{ |x| f.puts("%s,%s" % [x[:id], x[:deadtime]]) }
		}
	end
end

