#---------------------------------------------------
#
#                        fast-html-template
#
#---------------------------------------------------

module HTML

class Template

	#------------------ �O���֐� ----------------------#
	
	# �����������FHTML�t�@�C�������[�h������
	def initialize( param = nil)
		@path = ['.','']
		@material = String.new				# �t�@�C������HTML�����󂯎��
		@completion = String.new			# �ŏI�I�o�͂���HTML���𒀎��i�[���Ă䂭
		@remainber = String.new			# material�̐��K�\����̎c����đ���p�Ɋm��
		@item = Hash.new					# <!var>�ɑΉ�����n�b�V���f�[�^���i�[
		@prep = nil
		@proc = Hash.new
		@procflag = false					# proc�^�O�̈������A�����Ȃ̂�������Ȃ̂�
		
		if ( param )
			load( param )						# �t�@�C�����������Ƃ��ă��[�h����
		end
	end
	
	
	# ���Ƃ���HTML����ǂݍ��ޏꍇ
	def set_html( html )
		@material = html
	end
	
	
	# �u������f�[�^�̃I�u�W�F�N�g������(���ݕ�����ւ̒P���Ȓu���̂ݑΉ�)
	def param( hash = {} )
		hash.each { |k,v|
				@item[k] = v					# �Ƃ肠�����S�ẴI�u�W�F�N�g��ۑ�
		}
	end
	
			
	# �o�͂���HTML����Ԃ�
	def output
		parse
		return @completion
	end
	
	
	# preprocess�^�O��Proc��ۑ�
	def set_prep( hash = {} )
		hash.each{ |k,v|
			@item[k] = v
		}
	end
	
	
	# preprocess�^�O���Ȃ��Ă�Proc�����s����悤�ɂȂ�
	def def_prep( proc = nil )
		@prep = proc
	end
	
	# proc�^�O��proc��ݒ�
	def set_proc( hash = {} )
		hash.each{ |k,v|
			@proc[k] = v
		}
	end
	
	
	alias expand param
	
	#-------------------- �����֐� --------------------#
	private
	
	# �t�@�C���̃��[�h
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
	
	
	# include�^�O���������ꍇ�A���̏ꏊ�Ƀt�@�C������u��
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
	
	
	# �J��Ԃ����������郁�\�b�h(�l�X�g�̏ꍇ�������Ă�)
	def repeat( body, itemname, value = [] )
		return "" if ( value == nil )
		ret_val = String.new							# �o�͂��镶����
		value.each { |h|								# �z��ɂ�������each
			imitation = body.dup
			item = Hash.new							# �J��Ԃ�����var_item(���O���Ԃ�̖h�����߃��[�J��)
			h.each{ |k,v|								# �z��̒��g�̃n�b�V���ɑ΂���each
				item[k] = v							# �I�u�W�F�N�g������i�z��̗v�f�̐���������������j
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
	
	# ��������������ǂ郁�\�b�h�i�l�X�g�̏ꍇ�������Ăԁj
	def divergence( body, itemname, value = nil, type = nil )
		ret_val = String.new
		item = Hash.new
		imitation = body.dup
		if ( type == 'if' )							# if�ŌĂ΂ꂽ�ꍇ
			if ( value == nil )					# �n�b�V���̒l��nil�̏ꍇ�����ɖ߂�
				return ""
			end
			if ( value.is_a?(Hash) )
				value.each{ |k,v|
					item[k] = v
				}
			end
		else										# unless�ŌĂ΂ꂽ�ꍇ
			if ( value[itemname] != nil )		# �n�b�V���̒l��nil�ȊO�̏ꍇ�����ɖ߂�
				return ""
			end
	#		if (!(value.member?(itemname)))   ���f���f�[�^�����݂��Ȃ������ꍇ��
	#			return ""                           if,unless���ɕ\���������Ȃ��Ƃ��L���ɂ���
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


	# <!begin>�^�O���������Ƃ��A�ꍇ�������Ă��ꂼ��̏������Ăяo��
	def begintag( body, itemname, value = nil )
		ret_val = String.new
		if ( value.is_a?( Array ) )
			ret_val << repeat( body,itemname,value )
		elsif ( value.is_a?( Hash ))
			ret_val << divergence( body, itemname, value, 'if' )
		end
		return ret_val		
	end
	
	# proc�^�O�̏���
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
	
	
	# �������`�F�b�N���āA�Y������u���֐����Ăяo���B�K�v�Ȃ��ꍇ�͂��̂܂܏o��string��
	def parse
		# HTML�R�����g�X�^�C�����T�|�[�g
		@material.gsub!(%r~<\!\-\-\s+(loop|loopend|if|ifend|var|include|preprocess|proc|procend|begin|end):([\w\./\-]+)\s+\-\->~,'<!\1:\2>')
		
		# �����珇�Ԃɕ]��
		while ( !(@material.empty?) )
			if (( @material =~ /<!loop:(.+?)>(.+?)<!loopend:\1>|<!if:(.+?)>(.+?)<!ifend:\3>|<!var:(.+?)>|<!preprocess:(.+?)><!var:(.+?)>|<!include:(.+?)>|<!unless:(.+?)>(.+?)<!unlessend:\9>|<!begin:(.+?)>(.+?)<!end:\11>|<!proc:(.+?)>(.+?)<!procend:\13>/m) != nil )
				@completion << $`
				@remainder = $'
				if ( $&[0...5] == "<!var")								# �ǂ̎�ނ̒u�����`�F�b�N�ivar�j
					if ( @prep == nil )									# def_prep�����s����Ă��Ȃ��ꍇ
						@completion << @item[$5].to_s
					else
						@completion << @prep.call( @item[$5].to_s)
					end
				elsif ( $&[0...5] == "<!loo")							# ���ɓ����iloop�j
					@completion << repeat( $2, $1, @item[$1] )		# loop�^�O�ɂ͂��܂ꂽ������PARAMETER_NAME��n��
				elsif ( $&[0...5] == "<!if:")
					@completion << divergence( $4, $3, @item[$3], 'if' )	# ���ɓ����iif�j
				elsif ( $&[0...5] == "<!pre")
					@completion << @item[$6].call(@item[$7].to_s)	# ���ɓ����ipreprocess�j
				elsif ( $&[0...5] == "<!inc")
					@completion << get_file( $8 )
				elsif ( $&[0...5] == "<!unl" )
					@completion << divergence( $10, $9, @item, 'unless')
				elsif ( $&[0...5] == "<!beg" )
					@completion << begintag( $12, $11, @item[$11] )	# begin�^�O�ɑΉ�
				elsif ( $&[0...5] == "<!pro")
					@completion << procedure( $14, $13 )
				end
				@material = @remainder											# �f�ނ̎c����đ���i�|�C���^��r������ɏo����ƂȂ��ǂ�(�Ȃ��Ă�H))
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