--[[
Description:

--]]

local LOG_FILE_NAME = "ts";
local POINT_NUM_PERLINE = 20;
local QIZI_IMAGE_WIDTH = 32;	-- image used to serach
local QIZI_IMAGE_MAX_WIDTH = 50;	-- full image max width
local version = 'v1.0.01'
local _screen_w, _screen_h;
local _ht_x, _ht_y, _ht_c, _hb_x, _hb_y, _hb_c, _cs;
local r, processing = false, 0;

function p_init()
    local sz = require("sz");
    local json = sz.json;
    local json_str;
    local ret1, ret2, ret3;

    _screen_w,_screen_h = getScreenSize();
    if (_screen_w+_screen_h) == (640+1136) then
        -- iphone 5s
        _ht_x, _ht_y = 0, 0;
        _hb_x, _hb_y = 0, 1135;
    elseif (_screen_w+_screen_h) == (1242+2208) then
        -- iphone 6 plus
    else
        error("您的设备分辨率不被支持");
    end
end

function _click(...)
    touchDown(...)
    touchUp(...)
end

function _is_color(x, y, c, s)
    local fl,abs = math.floor,math.abs
    s = fl(0xff*(100-s)*0.01)
    local r,g,b = fl(c/0x10000),fl(c%0x10000/0x100),fl(c%0x100)
    local rr,gg,bb = getColorRGB(x,y)
    if abs(r-rr)<s and abs(g-gg)<s and abs(b-bb)<s then
        return true
    end
	return false;
end

function _is_color_rgb(x, y, r, g, b, d_r, d_g, d_b)
    local abs = math.abs
    local rr,gg,bb = getColorRGB(x,y)
    if abs(r-rr)<=d_r and abs(g-gg)<=d_g and abs(b-bb)<=d_b then
        return true;
    end
	return false;
end

function _check_pos(x,y,c,cs)
    if _is_color(x,y,c,cs) then
        _click(x,y)
    end
end

function _multi_color(array,s)
    s = math.floor(0xff*(100-s)*0.01)
    keepScreen(true)
    for var = 1, #array do
        local lr,lg,lb = getColorRGB(array[var][1],array[var][2])
        local r = math.floor(array[var][3]/0x10000)
        local g = math.floor(array[var][3]%0x10000/0x100)
        local b = math.floor(array[var][3]%0x100)
        if math.abs(lr-r) > s or math.abs(lg-g) > s or math.abs(lb-b) > s then
            keepScreen(false)
            return false
        end
    end
    keepScreen(false)
    return true
end

function _xprintf(s, ...)
	-- return toast(s:format(...));
	return wLog(LOG_FILE_NAME, s:format(...));
end

init(0);
mSleep(1000);

--[[

--]]

p_init();
initLog(LOG_FILE_NAME, 0);

local x1, y1, x2, y2, x3, y3;
local c1, c2, c3;

r1, g1, b1 = getColorRGB(_ht_x, _ht_y);

x2, y2 = _hb_x, _hb_y;
x3, y3 = _hb_x+(_screen_w/2), _hb_y;
c2 = getColor(x2, y2);
c3 = getColor(x3, y3);
while (c2 ~= c3) do
    x2 = x2 + 10;
    x3 = x3 + 10;
    c2 = getColor(x2, y2);
    c3 = getColor(x3, y3);
end
--wLog("test", "x2 = "..x2..", y2 = "..y2..", c2 = "..c2);

local x_qz, y_qz = findImage("qizi.png", 0, 0, _screen_w, _screen_h);
if x_qz ~= -1 and y_qz ~= -1 then
	_xprintf("image %d, %d", x_qz, y_qz);
else
    toast('picture is not found!');        
end

local x_qzC = x_qz + QIZI_IMAGE_WIDTH/2;
local x_from, x_to;
if x_qz < _screen_w/2 then
	x_from, x_to = 320, 550;
else
	x_from, x_to = 150, 320;
end

r2, g2, b2 = getColorRGB(x2, y2);
c_r = (r2 + r1)/2;
c_g = (g2 + g1)/2;
c_b = (b2 + b1)/2;

d_r = math.abs((r2 - r1)/2);
d_g = math.abs((g2 - g1)/2);
d_b = math.abs((b2 - b1)/2);

local x_block_c, y_block_c;

-- first scan, to find the block for next step
local y_1stScan;
for y = 400, 550 do
	local bk = false;
	for x = 0, _screen_w-1, (_screen_w)/10 do
		-- we should skip the x area which in qizi image, since the image maybe higher than block
		if math.abs(x - x_qzC)>QIZI_IMAGE_MAX_WIDTH/2 and _is_color_rgb(x, y, c_r, c_g, c_b, d_r, d_g, d_b)~=true then
			_xprintf("found point y = %d", y);
			y_1stScan = y;
			bk = true;
			break;
		end
	end	
	if bk == true then
		break;
	end
end

-- second scan, to find the top left point of the block
for y = y_1stScan-5, y_1stScan+5 do
	local bk = false;
	for x = 0, _screen_w-1, 3 do
		if math.abs(x - x_qzC)>QIZI_IMAGE_MAX_WIDTH/2 and _is_color_rgb(x, y, c_r, c_g, c_b, d_r, d_g, d_b)~=true then
			_xprintf("found point x = %d, y = %d", x, y);
			x_block_c, y_block_c = x, y;
			bk = true;
			break;
		end
	end	
	if bk == true then
		break;
	end
end

-- third scan, to find the top center point of the block
local x;
x = x_block_c;
x1 = x;
while _is_color_rgb(x, y_block_c, c_r, c_g, c_b, d_r, d_g, d_b)~=true do
	x = x + 1;
end
x_block_c = math.floor((x+x1)/2);
_xprintf("x = %d, x1 = %d, x_block_c = %d", x, x1, x_block_c);

-- lua_exit(); 

local len = math.abs(x_qzC - x_block_c)/math.sqrt(3)*2;
_xprintf("len, x_qzC, x_blockC = %d, %d, %d", len, x_qzC, x_block_c);

touchDown(x_qzC, y_qz);
mSleep(len*2.35);
touchUp(x_qzC, y_qz);







