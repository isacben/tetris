pico-8 cartridge // http://www.pico-8.com
version 39
__lua__
function _init()
	t=0
	spd=28
	vel=8
	lwall=8
	rwall=88
	lines=0
	score=0
	level=0
	is_pressed=false
	can_drop=true
	
	--start.game.delete.over
	state="start"
	
	piece_x=32 --center of 96
	piece_y=0
	
	board={}
	over_y=128
	reset_board()
	
	--piece stuff
	pce_squares={}
	del_squares={}
	current_pce={}
	next_pce=get_next()
	squares={}
	
	wait=0
	
	init_current_pce()
	
	debug=""
end

function _update()
	update()
end

function _draw()
	t+=1
	
	draw()
	print(debug,10,2,0)
end
-->8
-- draw

function draw()
	--start screen
	if state=="start" then
		cls(5)
		start_scr()
	
	--game screen
	elseif state=="game" then
		cls(7)
		stage()
		paint_squares()
		
	--delete line
	elseif state=="delete" then
		animate_del_squares()
	
	--cover with blocks
	elseif state=="cover" then
		cover_board()
		
	--gameover screen
	elseif state=="gameover" then
		--cls(6)
		--stage()
		gameover()
	end
end


function animate_del_squares()
	if	t<wait then
		for s in all(del_squares) do
			if t%6<2 then
				spr(s.spr,s.x,s.y)
			else
				spr(11,s.x,s.y)
			end
		end
	else
		state="game"
		wait=0
		del_squares={}
	end
end


function start_scr()
	rectfill(1,1,126,42,7)
	rect(2,2,125,41,5)
	spr(192,4,6,15,4)
	
	rectfill(6,45,121,77,7)
	spr(64,6,46,15,4)
	cprint("press x to start",80,13)
end


function paint_squares()
	for square in all(pce_squares) do
		spr(square.spr,square.x,square.y)
	end
	
	for square in all(squares) do
		spr(square.spr,square.x,square.y)
	end
end

function stage()
	rectfill(96,0,128,128,5)
	
	for i=0,15 do
		spr(8,0,i*8)
		spr(8,88,i*8)
	end
	

	rectfill(96,10,128,27,7)
	rectfill(96,11,128,16,5)
	line(96,18,128,18,5)
	line(96,26,128,26,5)
	
	rectfill(99,4,123,14,7)
	rect(100,5,122,13,5)	
	print("score",102,7,5)
	print(tostr(score),112-(#tostr(score)*2),20,5)

		
	rectfill(99,41,123,58,7)
	rect(100,42,122,57,5)
	print("level",102,44,5)
	print(tostr(level),112-(#tostr(level)*2),51,5)

	rectfill(99,61,123,78,7)
	rect(100,62,122,77,5)
	print("lines",102,64,5)
	print(tostr(lines),112-(#tostr(lines)*2),71,5)

	rectfill(96,87,128,119,7)
	preview(
		pce_type[next_pce],
		next_pce
	)
end


function cprint(s,y,c)
	print(s,64-#s*2,y,c)
end


function cover_board()
	if over_y>0 then
		if t%1==0 then
			over_y-=8
			for i=1,10 do
				spr(9,0+i*8,over_y)
			end
		end
	elseif over_y==0 then
		wait=t+30
		over_y=-1
	elseif wait<t then
		state="gameover"
	end
end


function gameover()
	rectfill(8,0,88,128,7)
	rect(25,10,69,44,5)
	rect(26,11,68,43,13)
	print("game",48-(4*2),20,5)
	print("over",48-(4*2),30,5)
	
	print("please",30,60,5)
	print("try",36,70,5)
	print("again",42,80,5)
	spr(10,62,80)
	
	print("press x to continue",48-(19*2),105,5)

	if btn(5) then
		reset_game()
		state="start"
	end

end
-->8
-- move & collisions

function down()
	local speed=spd
	--soft drop
	if btn(3) then
		if not is_pressed then
			is_pressed=true
		end
	else
		is_pressed=false
		can_drop=true
	end
	
	if is_pressed and can_drop then
		speed=spd-spd+1
	else
		speed=spd
	end
	
	if t%speed==0 then
		--fix for spawning too low bug
		if on_floor() then
			stop_pce()
			spawn()
		else
			current_pce.y+=vel
			for square in all(pce_squares) do
				square.y+=vel
			end
		end
	end
end

function move()
	local move=8
	local cx=current_pce.x
	local cw=current_pce.w
	
	--move left
	if btnp(0) then
		for cs in all(pce_squares) do
			
			--collision with squares
			for s in all(squares) do
				if cs.y==s.y then
					if cs.x == s.x+8 then 
						move=0
					end
				end
			end
			
			--collision with the wall
			if cs.x<=lwall then
				move=0
			end
		end
		
		current_pce.x-=move
		for s in all(pce_squares) do
			s.x-=move
		end
	end
	
	--move rigth
	if btnp(1) then
		for cs in all(pce_squares) do
			
			--collision with squares
			for s in all(squares) do
				if cs.y==s.y then
					if cs.x+8 == s.x then 
						move=0
					end
				end
			end
			
			--collision with the wall
			if cs.x+8>=rwall then
				move=0
			end
		end
	
		current_pce.x+=move
		for s in all(pce_squares) do
			s.x+=move
		end
	end
		
	
	--rotate
	if btnp(2) then
		rotate(acurr)
	end
end


function on_floor()	
	for cp_sqr in all(pce_squares) do
		
		--collision with squares
		for sqr in all(squares) do
			if cp_sqr.y+8 == sqr.y and
				cp_sqr.x == sqr.x then
				return true
			end
		end
		
		--collision with floor
		if cp_sqr.y+8>=128 then
			return true
		end
	end
end


function stop_pce()
	for s in all(pce_squares) do
		add(squares,s)
		to_board(s.x,s.y)
	end
	
	if is_pressed then
		can_drop=false
	end
	
	pce_squares={}
	check_lines()
end
-->8
-- pieces

function init_current_pce()
	current_pce.x=piece_x
	current_pce.y=piece_y
end


function get_next()
	local n
	repeat
		n=flr(rnd(7))+1
	until n!=current_pce.type
	return n
end

function spawn()
	init_current_pce()
	
	current_pce.type=next_pce
	generate(
		pce_type[current_pce.type],
		current_pce.type
	)
	next_pce=get_next()
end


function generate(arr,_spr)
	pce_squares={}
	acurr=arr
	
	for row=1,#acurr do
		for col=1,#acurr[1] do
			if arr[row][col]==1 then
				local s={}
				s.x=current_pce.x+(col-1)*8
				s.y=current_pce.y+(row-1)*8
				s.spr=_spr
				add(pce_squares,s)
			end
		end
	end
end


function rotate(arr)
	local temp={}
	local buff_squares={}
	
	--rotate into temp
	local n=#arr+1
	for col=1,#arr[1] do
		temp[col]={}
		for row=1,#arr do
			temp[col][n-row]=arr[row][col]
		end
	end
	
	--add to buffer
	for row=1,#temp do
		for col=1,#temp[1] do
			if temp[row][col]==1 then
				local s={}
				s.x=current_pce.x+(col-1)*8
				s.y=current_pce.y+(row-1)*8
				add(buff_squares,s)
			end
		end
	end
	
	--check overlaping
	for bs in all(buff_squares) do
		if bs.x<lwall or
			bs.x>=rwall or
			bs.y>=128 then
			return false
		end
		for s in all(squares) do
			if bs.x==s.x and bs.y==s.y then
				return false
			end
		end
	end
	
	--re paint the piece
	pce_squares={}
	generate(temp,current_pce.type)
end


function preview(arr,_spr)
	local ofx=0
	local ofy=0
	if #arr[1]==3 then
		ofx=4
	elseif #arr[1]==2 then
		ofx=8
	elseif #arr[1]==4 then
		ofy=-4
	end
	
	for row=1,#arr do
		for col=1,#arr[1] do
			if arr[row][col]==1 then
				spr(
					_spr,
					96+ofx+(col-1)*8,
					96+ofy+(row-1)*8
				)
			end
		end
	end
end
-->8
--update

function update()
	--start screen
	if state=="start" then
		if btnp(5) then
			state="game"
			spawn()
		end
	
	--game screen
	elseif state=="game" then
		down()
		move()
	end
end
-->8
--arrays

acurr={}

ablock={
	{1,1},
	{1,1}
}

atee={
	{0,1,0},
	{1,1,1},
	{0,0,0}
}

aell={
	{0,0,1},
	{1,1,1},
	{0,0,0}
}

aelr={
	{1,0,0},
	{1,1,1},
	{0,0,0}
}

asl={
	{1,1,0},
	{0,1,1}
}

asr={
	{0,1,1},
	{1,1,0}
}

aline={
	{0,0,0,0},
	{1,1,1,1},
	{0,0,0,0}
}

pce_type={
	ablock,
	atee,
	aell,
	aelr,
	asl,
	asr,
	aline,
}
-->8
--board

function reset_board()
	for row=1,15 do
		board[row]={}
		for col=1,10 do
			board[row][col]=0
		end
	end
end


function to_board(x,y)
	local row
	local col
	
	row=y/8
	col=x/8
	
	if row<1 then
		state="cover"
	else
		board[row][col]=1
	end
end


function update_board()
	reset_board()
	for s in all(squares) do
		board[s.y/8][s.x/8]=1
	end
end


function check_lines()
	local l=0
	local r={}
	local remove={}
	
	--check completed lines
	for row=1,15 do
		r=board[row]
		if is_line(r) then
			l+=1
			add(remove,row)
		end 
	end
	
	if #remove>0 then
		--remove completed lines
		state="delete"
		for rem in all(remove) do
			for s in all(squares) do
				if s.y==rem*8 then
					add(del_squares,s)
					del(squares,s)
				end
			end
		end
		wait=t+30
		
		for s in all(squares) do
			if s.y<remove[1]*8 then
				--board[s.y/8][s.x/8]=0
				s.y+=8*#remove
				--board[s.y/8][s.x/8]=1
			end
		end
	
		update_board()
		score+=calc_points(l)
		lines+=l
		level=flr(lines/5)
		
	end
end


function is_line(arr)
	for a in all(arr) do
		if a==0 then
			return false
		end
	end
	return true
end


function calc_points(l)
	local p={40,100,300,1200}
	return p[l]*(level+1)
end
-->8
function reset_game()
	t=0
	spd=28
	lines=0
	score=0
	level=0
	is_pressed=false
	can_drop=true
	
	board={}
	over_y=128
	reset_board()
	
	pce_squares={}
	del_squares={}
	current_pce={}
	next_pce=get_next()
	squares={}
	
	wait=0
	init_current_pce()
end
__gfx__
0000000055555555555555555555555555555555555555555555555555555555d56dd56d55555555050500007777777700000000000000000000000000000000
000000005dddddd55dddddd55dddddd5577777755dddddd55dddddd557777775d5ddd5dd57777775565650007777777700000000000000000000000000000000
007007005d5555d55d7777d55d5555d5575555755dddddd55d5555d557555575d5ddd5dd57ddddd5566650007777777700000000000000000000000000000000
000770005d5775d55d7dd5d55d5775d5575555755dddddd55d5dd7d5575dd5755555555557ddddd5056500007777777700000000000000000000000000000000
000770005d5775d55d7dd5d55d5775d5575555755dddddd55d5dd7d5575dd5756dd56dd557ddddd5005000007777777700000000000000000000000000000000
007007005d5555d55d5555d55d5555d5575555755dddddd55d7777d557555575ddd5ddd557ddddd5000000007777777700000000000000000000000000000000
000000005dddddd55dddddd55dddddd5577777755dddddd55dddddd557777775ddd5ddd557ddddd5000000007777777700000000000000000000000000000000
00000000555555555555555555555555555555555555555555555555555555555555555555555555000000007777777700000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000d0000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddd000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00000000000000000000000
0000005000000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00000000000000000000000
0000055555555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddd00000000000000000000000
000005500000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd0000000000000000000000
000050500000050500000000000000000000000000000000000000000000000000000000000000000000000000000000000ddddddd0000000000000000000000
000050500000050500000000000000000000000000000000000000000000000000000000000000000565656565656500000ddddddd0000000000000000000000
000500500000050050000000000000000000000000000000000000000000000000000000000000000565656565656500000ddddddd0000000000000000000000
000500500000050050000000000000000000000000000000000000000000000000000000000000005d5d5d5d5d5d5666666dd777dd6666666000000000000000
005000500000050005000000000000000000000000000000000000000000000000000000000000005d5d5d5d5d5d566666ddddddddd666660000000000000000
050005550000555000500000000000000000000000000000000000000000000000000000000000005d5656565656566666ddd777ddd666660000000000000000
050005550000555000500000000000000000000000000000000000000000000000000000000000005d56565656565d6666ddddddddd666600000000000000000
500005550000555000050000000000000000000000000000000000000000000000000000000000005d5d565656565d6666dd77777dd666600000000000000000
500005550000555000050000000000000000000000000000000000000000000000000000000000005d5d565656565d666ddddddddddd66600000000000000000
500005550000555000055000000000000000000000000000000000000000000000000000000000005d5d565656565d566dd7777777dd66000000000000000000
500005550000555000050500000000000000000000000000000000000000000000000000000000005d5d56565d5d5d566ddddddddddd66000000000000000000
500005550000555000050050000000000000000000000000000000000000000000000000000000005d5d56565d5d5d566d777777777d66000000000000000000
500055550000555500050055000000000000000000000000000000000000000000000000000000005d5d56565d5d5d56ddddddddddddd6000000000000000000
500055550000555500050050550000000000000000000000000000000000000000000000000000005d5d5d5d5d5d5d56d77777777777d6000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
55555557555555575555555775555555755555555555775555555755555557555555577555555575555577777777755555557777557555555555557700000000
57777757577775575777755775777755775777777755775777775757777557577775577577775575777555777777757777557775577577777777557700000000
57777577577775577577755775777755777577777755775777757757777557757775577577775575777775577777757777557757557757777777557700000000
57775777577775577757755775777755777757777755775777577757777557775775577577775575777777557777757777557757755775777777557700000000
57775777577775577757755775777755777775777755775777577757777557775775577577775575777777757777757777557577755777577777557700000000
57757777577775577775755775777755777777577755775775777757777557777575577577775575777777755777757777557577775577577777557700000000
56657777566665577775655775666655777777756655775665777756666557777565577566665575666666655777756666557566666557756666557700000000
56577777566665577777555775666655777777775655775657777756666557777755577566665575666666655777756666557566666557775666557700000000
56577777566665577777555775666655777777777555775657777756666557777755577566665575666666655777756666557566666655775666557700000000
55777777566665577777755775666655777777757755775577777756666557777775577566665575666666655777756666557756666665577566557700000000
55777777566665577777755775666655777777557775775577777756666557777775577566665575666666655777756666557756666665577756557700000000
57777777566665577777775775666655777775557777775777777756666557777777577566665575666666655777756666557756666666557775557700000000
77777777566665577777777775666655777756557777777777777756666557777777777566665575666666557777756666557775666666655775557700000000
77777777566665577777777775666655777566557777777777777756666557777777777566665575666666557777756666557775666666665577557700000000
777777775dddd5577777777775dddd55775ddd55777777777777775dddd5577777777775dddd5575ddd55557777775dddd5577775dddddddd577757700000000
777777775dddd5577777777775dddd5575dddd55777777777777775dddd5577777777775dddd5575d5555577777775dddd55777775ddddddd557777700000000
777777775dddd5577777777775dddd55775ddd55777777777777775dddd5577777777775dddd557555577777777775dddd557757775ddddddd55777700000000
777777775dddd5577777777775dddd557775dd55777777777777775dddd5577777777775dddd557557777777777775dddd557755775dddddddd5577700000000
777777775dddd5577777777775dddd5577775d55777777777777775dddd5577777777775dddd5575d5777777777775dddd5577555775dddddddd557700000000
777777775dddd5577777777775dddd5577777555777777777777775dddd5577777777775dddd5575d5777777777775dddd55775d57775ddddddd557700000000
777777775dddd5577777777775dddd5577777755777577777777775dddd5577777777775dddd5575dd577777777775dddd55775d55775dddddddd55700000000
777777775dddd5577777777775dddd5577777775775577777777775dddd5577777777775dddd5575ddd57777777775dddd55775dd55775ddddddd55700000000
77777777555555577777777775555555777777777555777777777755555557777777777555555575555557777777755555557755555577555555555500000000
77777777555555577777777775555555777777775555777777777755555557777777777555555575555557777777755555557755555577555555555500000000
77777777555555577777777775555555777777755555777777777755555557777777777555555575555555777777755555557755555557755555555500000000
77777777555555577777777775555555777777555555777777777755555557777777777555555575555555577777755555557755555555775555555500000000
77777777555555577777777775555555777775555555777777777755555557777777777555555575555555557777755555557755555555777555555500000000
77777777555555577777777775555555777755555555777777777755555557777777777555555575555555557777755555557755555555577555555500000000
77777777555555577777777775555555777555555555777777777755555557777777777555555575555555555777755555557755555555557755555500000000
77777777555555577777777775555555775555555555777777777755555557777777777555555575555555555577755555557755555555555775555700000000
77777777555555577777777775555555755555555555777777777755555557777777777555555575555555555557755555557755555555555755557700000000
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777700000000
