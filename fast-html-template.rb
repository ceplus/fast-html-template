#---------------------------------------------------
#
#                        fast-html-template
#
#---------------------------------------------------

module HTML

class Template

	#------------------ 外部関数 ----------------------#
	
	# 初期化処理：HTMLファイルをロードさせる
	def initialize( param = nil)
		@path = ['.','']
		@material = String.new				# ファイルからHTML文を受け取る
		@completion = String.new			# 最終的出力するHTML文を逐次格納してゆく
		@remainber = String.new			# materialの正規表現後の残りを再代入用に確保
		@item = Hash.new					# <!var>に対応するハッシュデータを格納
		@prep = nil
		@proc = Hash.new
		@procflag = false					# procタグの引数が、数字なのか文字列なのか
		
		if ( param )
			load( param )						# ファイル名を引数としてロードする
		end
	end
	
	
	# あとからHTML文を読み込む場合
	def set_html( html )
		@material = html
	end
	
	
	# 置換するデータのオブジェクトをつくる(現在文字列への単純な置換のみ対応)
	def param( hash = {} )
		hash.each { |k,v|
				@item[k] = v					# とりあえず全てのオブジェクトを保存
		}
	end
	
			
	# 出力するHTML文を返す
	def output
		parse
		return @completion
	end
	
	
	# preprocessタグのProcを保存
	def set_prep( hash = {} )
		hash.each{ |k,v|
			@item[k] = v
		}
	end
	
	
	# preprocessタグがなくてもProcを実行するようになる
	def def_prep( proc = nil )
		@prep = proc
	end
	
	# procタグのprocを設定
	def set_proc( hash = {} )
		hash.each{ |k,v|
			@proc[k] = v
		}
	end
	
	
	alias expand param
	
	#-------------------- 内部関数 --------------------#
	private
	
	# ファイルのロード
	def load( file )
		@path.each { |path|
			if (FileTest.exist?( filepath = File.join(path,file)))
				begin
					fp = File.open( filepath, "r")
					@material = fp.read
					fp.close
				rescue
					raise ( IO Error )
				end
			end
		}
		if @material
			return
		end
		raise ( IO Error,"Template file not found" )
	end
	
	
	# includeタグが合った場合、その場所にファイル名を置換
	def get_file( param )
		fp = nil
		ret_val = String.new
		@path.each { |path|
			if (FileTest.exist?(filepath = File.join(path,param)))
				begin
					fp = File.open( filepath, "r")
					ret_val = fp.read
					fp.close
				rescue
					raise (IO Error)
				end
			end
		}
		if ret_val
			return ret_val
		end
		raise ( IO Error,"Include template node found")
	end
	
	
	# 繰り返しを処理するメソッド(ネストの場合自分を呼ぶ)
	def repeat( body, itemname, value = [] )
		return "" if ( value == nil )
		ret_val = String.new							# 出力する文字列
		value.each { |h|								# 配列にたいしてeach
			imitation = body.dup
			item = Hash.new							# 繰り返し内のvar_item(名前かぶるの防ぐためローカル)
			h.each{ |k,v|								# 配列の中身のハッシュに対してeach
				item[k] = v							# オブジェクトをつくる（配列の要素の数だけ代入し直す）
			}
			while ( !( imitation.empty?) )
				if (( imitation =~ /<!loop:(.+?)>(.+?)<!loopend:\1>|<!if:(.+?)>(.+?)<!ifend:\3>|<!var:(.+?)>|<!preprocess:(.+?)><!var:(.+?)>|<!include:(.+?)>|<!unless:(.+?)>(.+?)<!unlessend:\9>|<!begin:(.+?)>(.+?)<!end:\11>/m) != nil )
					ret_val << $`
					if ( $&[0...5] == "<!var")
						if ( @prep == nil )
							ret_val << item[$5].to_s
						else
							ret_val << @prep.call( item[$5].to_s)
						end
					elsif ( $&[0...5] == "<!loo")
						ret_val << repeat( $2, $1, item[$1])
					elsif ( $&[0...5] == "<!if:")
						ret_val << divergence( $4, $3, item[$3], 'if')
					elsif ( $&[0...5] == "<!pre")
						ret_val << @item[$6].call(item[$7].to_s)
					elsif ( $&[0...5] == "<!inc")
						ret_val << get_file($8)
					elsif ( $&[0...5] == "<!unl" )
						ret_val << divergence( $10, $9, item, 'unless')
					elsif ( $&[0...5] == "<!beg" )
						ret_val << begintag( $12, $11, item[$11] )
					end
					imitation = $'
				else
					ret_val << imitation
					imitation = ""
				end
			end
		}
		return ret_val
	end
	
	# 条件分岐をつかさどるメソッド（ネストの場合自分を呼ぶ）
	def divergence( body, itemname, value = nil, type = nil )
		ret_val = String.new
		item = Hash.new
		imitation = body.dup
		if ( type == 'if' )							# ifで呼ばれた場合
			if ( value == nil )					# ハッシュの値がnilの場合即座に戻す
				return ""
			end
			if ( value.is_a?(Hash) )
				value.each{ |k,v|
					item[k] = v
				}
			end
		else										# unlessで呼ばれた場合
			if ( value[itemname] != nil )		# ハッシュの値がnil以外の場合即座に戻す
				return ""
			end
	#		if (!(value.member?(itemname)))   モデルデータが存在しなかった場合に
	#			return ""                           if,unless共に表示したくないとき有効にする
	#		end
		end
		
		while ( !( imitation.empty?))
			if (( imitation =~ /<!loop:(.+?)>(.+?)<!loopend:\1>|<!if:(.+?)>(.+?)<!ifend:\3>|<!var:(.+?)>|<!preprocess:(.+?)><!var:(.+?)>|<!include:(.+?)>|<!unless:(.+?)>(.+?)<!unlessend:\9>|<!begin:(.+?)>(.+?)<!end:\11>/m) != nil )
				ret_val << $`
				if ( $&[0...5] == "<!var")
					if ( @prep == nil )
						ret_val << item[$5].to_s
					else
						ret_val << @prep.call( item[$5].to_s)
					end
				elsif ( $&[0...5] == "<!loo")
					ret_val << repeat( $2, $1, item[$1])
				elsif ( $&[0...5] == "<!if:")
					ret_val << divergence( $4, $3, item[$3], 'if')
				elsif ( $&[0...5] == "<!pre")
					ret_val << @item[$6].call(item[$7].to_s)
				elsif ( $&[0...5] == "<!inc")
					ret_val << get_file($8)
				elsif ( $&[0...5] == "<!unl" )
					ret_val << divergence( $10, $9, item, 'unless')
				elsif ( $&[0...5] == "<!beg" )
					ret_val << begintag( $12, $11, item[$11] )
				end
				imitation = $'
			else
				ret_val << imitation
				imitation = ""
			end
		end
		return ret_val
	end


	# <!begin>タグがあったとき、場合分けしてそれぞれの処理を呼び出す
	def begintag( body, itemname, value = nil )
		ret_val = String.new
		if ( value.is_a?( Array ) )
			ret_val << repeat( body,itemname,value )
		elsif ( value.is_a?( Hash ))
			ret_val << divergence( body, itemname, value, 'if' )
		end
		return ret_val		
	end
	
	# procタグの処理
	def procedure( body, procname )
		if ( !(@proc.member?(procname)))
			return ""
		end
		return "" if ( @proc[procname] == nil )
		ret_val = String.new
		array = Array.new
		while (( body =~ /<!var:(.+?)>/ ) != nil )
			array.push(@item[$1])
			body = $'
		end
		body.split(/,/).each{ |i|
				array.push( i.to_s )
		}
		ret_val << @proc[procname].call(array.each{|i|})
		return ret_val
	end
	
	
	# 属性をチェックして、該当する置換関数を呼び出す。必要ない場合はそのまま出力stringへ
	def parse
		# HTMLコメントスタイルをサポート
		@material.gsub!(%r~<\!\-\-\s+(loop|loopend|if|ifend|var|include|preprocess|proc|procend|begin|end):([\w\./\-]+)\s+\-\->~,'<!\1:\2>')
		
		# 頭から順番に評価
		while ( !(@material.empty?) )
			if (( @material =~ /<!loop:(.+?)>(.+?)<!loopend:\1>|<!if:(.+?)>(.+?)<!ifend:\3>|<!var:(.+?)>|<!preprocess:(.+?)><!var:(.+?)>|<!include:(.+?)>|<!unless:(.+?)>(.+?)<!unlessend:\9>|<!begin:(.+?)>(.+?)<!end:\11>|<!proc:(.+?)>(.+?)<!procend:\13>/m) != nil )
				@completion << $`
				@remainder = $'
				if ( $&[0...5] == "<!var")								# どの種類の置換かチェック（var）
					if ( @prep == nil )									# def_prepが実行されていない場合
						@completion << @item[$5].to_s
					else
						@completion << @prep.call( @item[$5].to_s)
					end
				elsif ( $&[0...5] == "<!loo")							# ↑に同じ（loop）
					@completion << repeat( $2, $1, @item[$1] )		# loopタグにはさまれた部分とPARAMETER_NAMEを渡す
				elsif ( $&[0...5] == "<!if:")
					@completion << divergence( $4, $3, @item[$3], 'if' )	# ↑に同じ（if）
				elsif ( $&[0...5] == "<!pre")
					@completion << @item[$6].call(@item[$7].to_s)	# ↑に同じ（preprocess）
				elsif ( $&[0...5] == "<!inc")
					@completion << get_file( $8 )
				elsif ( $&[0...5] == "<!unl" )
					@completion << divergence( $10, $9, @item, 'unless')
				elsif ( $&[0...5] == "<!beg" )
					@completion << begintag( $12, $11, @item[$11] )	# beginタグに対応
				elsif ( $&[0...5] == "<!pro")
					@completion << procedure( $14, $13 )
				end
				@material = @remainder											# 素材の残りを再代入（ポインタを途中からに出来るとなお良い(なってる？))
			else
				@completion << @material
				@material = ""
			end
		end
	end
end


end

#---------------------------------------------------
#Copyright (C) 2005 Community Engine Inc. All rights reserved.
#Author : ede
#---------------------------------------------------