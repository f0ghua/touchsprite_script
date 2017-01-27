--[[
Description:
	_hr_x 	红包收到的 x 坐标
	_hr_y 	红包收到的 y 坐标
	_hr_c	红包收到的 rgb 颜色
	_cs 	颜色相似度
--]]

local version = 'v1.0.01'
local _hr_x, _hr_y, _hr_c, _ho_x, _ho_y, _ho_c, _hc_x, _hc_y, _hc_c, _cs;
local _hi_x, _hi_y, _hi_c;
local g_t_table;
local r, processing = false, 0;
local g_function_enable;

function file_exists(path)
    local f = io.open(file_name, "r")
    return f ~= nil and f:close()
end

function read_serial_from_file(path)
    local file = io.open(path,"r");
    local serial = nil;

    if file then
        serial = file:read("*line");
    end

    return serial;
end

function write_serial_to_file(path, serial)
    local file = io.open(path,"w");

    if file then
        rc = file:write(serial);
    end

    return rc;
end

function sn_ui_get()
    local sz = require("sz")
    local json = sz.json
    local w,h = getScreenSize();
    MyTable = {
        ["style"] = "default",
        ["width"] = w,
        ["height"] = h,
        ["config"] = "dlq_data1.dat",
        ["timer"] = 300,
        views = {
            {
                ["type"] = "Label",
                ["text"] = "授权码设置",
                ["size"] = 25,
                ["align"] = "center",
                ["color"] = "0,0,255",
            },
            {
                ["type"] = "Edit",
                ["prompt"] = "请输入授权码",
                ["text"] = "",
            },
        }
    }
    local MyJsonString = json.encode(MyTable);
    local ret, input = showUI(MyJsonString);

    return input;
end

function serial_validate()
    local sz = require("sz");
    local key = "da0ye\'sdlq";
    local str = sz.system.serialnumber()..key;
    local cfg_file = "/var/mobile/Media/TouchSprite/config/dlq_sn.cfg";
    local sn_stored = read_serial_from_file(cfg_file);
    local sn_valid = string.sub(str:md5(), 17, 32);

    -- dialog('str = "'..str..'", sn = "'..sn_valid..'"', 0);
    -- dba9c0f94d5a351e 63c65e32f81328a9

    if (sn_stored) and (sn_stored == sn_valid) then
        return true;
    end

    input = sn_ui_get();
    -- dialog(input);
    if (input ~= "") and (input == sn_valid) then
        write_serial_to_file(cfg_file, input);
        return true;
    end

--[[
    dialog('"'..str..'" 的 16 进制编码为: <'..str:tohex()..'>', 0)
    dialog('<'..str:tohex()..'> 转换成明文为: "'..str:tohex():fromhex()..'"', 0)
    dialog('"'..str..'" 的 MD5 值是: '..str:md5(), 0)

    local sn = string.sub(str:md5(), 17, 32);
    dialog('MD5截取后为: "'..sn..'"', 0)
--]]
    lua_exit();

end

function p_init()
    local w, h;
    local sz = require("sz");
    local json = sz.json;
    local json_str;
    local ret1, ret2, ret3;

    w,h = getScreenSize()
    if (w+h) == (640+1136) then
        -- iphone 5s
        _hr_x, _hr_y, _hr_c = 260, 860, 0xc3304a;
        _hi_x, _hi_y, _hi_c = 70, 420, 0xffedbf;
        _ho_x, _ho_y, _ho_c = 320, 715, 0xddbc84;
        _hc_x, _hc_y = 555, 170;
        g_t_table = {
            {571,  146, 0xcf3a50},
            {424,  949, 0xdf8274},
        };
        _cs = 99;
    elseif (w+h) == (1242+2208) then
        -- iphone 6 plus
        _hr_x, _hr_y, _hr_c = 215, 1900, 0xfa9d3b;
        _ho_x, _ho_y, _ho_c = 620, 1330, 0xddbc84;
        _hc_x, _hc_y = 90, 130;
        g_t_table = {
            {620, 260, 0xd84e43},
            {620, 480, 0xfffaf5},
        };
        _cs = 99;
    else
        error("您的设备分辨率不被支持");
    end

    ui_table = {
        ["style"]   = "default",
        ["width"]   = w,
        ["height"]  = h,
        ["config"]  = "dlq_data2.dat",
        ["timer"]   = 360,

        views = {
            {
                ["type"] = "Label",
                ["text"] = "微信抢红包"..version,
                ["size"] = 18,
                ["align"] = "center",
                ["color"] = "0,0,255",
            },
            {
                ["type"] = "RadioGroup",
                ["list"] = "延时,秒抢",
                ["select"] = "1",
            },
--[[
            {
                ["type"] = "Label",
                ["text"] = "操作方法: 运行选择躲避地雷-开启, 提示成功避雷针开启成功后, 打开多开小号再打开大号提示获取小号成功即可正常抢包!",
                ["size"] = 22,
                ["align"] = "left",
                ["color"] = "255,0,0",
            },
--]]
        }
    }
    json_str = json.encode(ui_table);
    ret1, g_function_enable, ret2, ret3 = showUI(json_str);
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

function handle_hongbao_received()
	if _is_color(_hr_x, _hr_y, _hr_c, _cs) then
		_click(_hr_x, _hr_y);
		return true
	else
		return false
	end
end

function handle_hongbao_open()
	if _is_color(_ho_x, _ho_y, _ho_c, _cs) then
        if (g_function_enable == "0") then
            toast("程序延时中,请勿手点红包", 1);
            mSleep(math.random(1000,2000));
            _click(_ho_x, _ho_y);
        else
            _click(_ho_x, _ho_y);
        end

		return true
    else
        if _is_color(_hi_x, _hi_y, _hi_c, _cs) then
            if (g_function_enable == "0") then
                toast("程序延时中,请勿手点红包", 1);
                mSleep(math.random(1000,3000));
                _click(_hi_x, _hi_y);
            else
                _click(_hi_x, _hi_y);
            end

            _click(555, 1095);
        else
            return false
        end
	end
end

function handle_hongbao_close()
	if _multi_color(g_t_table, _cs) then
		_click(_hc_x, _hc_y);
--[[
        if ((g_function_enable == "0") and (succ_flag == 1)) then
            dialog("躲避成功", 3);
        end
--]]
        mSleep(1000); -- wait close finish
        return true;
	end

    return false;
end


init(0);
mSleep(1000);

--[[
serial_validate();

current_time = os.time();
expire_time = os.time{year=2016, month=7, day=10, hour=0};
-- dialog("c = "..current_time..", e = "..expire_time);
if (current_time > expire_time) then
    lua_exit();
end
--]]

p_init();

while true do

    r = handle_hongbao_received();
    if r == true then
		--mSleep(500);
    end

    r = handle_hongbao_open();
    if r == true then
		--touchDown()
        mSleep(500);
        succ_flag = 1;
    end

    r = handle_hongbao_close();
    if r == true then
        succ_flag = 0;
    end

	mSleep(200);
end


