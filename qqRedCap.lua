--[[
Description:
	_hr_x 	红包收到的 x 坐标
	_hr_y 	红包收到的 y 坐标
	_hr_c	红包收到的 rgb 颜色
	_cs 	颜色相似度
--]]

local g_version = 'v1.0.03'

local g_degree = 99;
local g_screenWidth, g_screenHeight;
local g_rectLeft, g_rectRight, g_rectTop, g_rectBottom;
local g_rectWidth, g_rectHeight;

local g_clWordInputX, g_clWordInputY, g_clWordInputColor;
local g_clRedCloseX, g_clRedCloseY;
local g_clTabelRedCloseValid;
local g_clickDelay;

local TIMEOUT_CLOSE, TIMEOUT_OPEN = 5, 20; -- 1s, 4s
local g_timeout, g_closeTimeout = 0, 0;

function appInit()
    local sz = require("sz");
    local json = sz.json;
    local jsonStr;
    local ret1, ret2, ret3;

    g_screenWidth, g_screenHeight = getScreenSize()
    if (g_screenWidth + g_screenHeight) == (640 + 1136) then
        -- iphone 5s
        g_rectLeft, g_rectRight, g_rectTop, g_rectBottom = 123, 398, 535, 864;
        g_rectWidth = g_rectRight - g_rectLeft;
        g_rectHeight = g_rectBottom - g_rectTop;

        g_clWordInputX, g_clWordInputY, g_clWordInputColor = 70, 420, 0xffedbf;
        --_ho_x, _ho_y, _ho_c = 320, 715, 0xddbc84;
        g_clRedCloseX, g_clRedCloseY = 554, 171;
        g_clTabelRedCloseValid = {
            {554, 171, 0x972438}, -- x
            {424, 949, 0xdf8274} -- >
        };
        g_degree = 99;
--[[
    elseif (g_screenWidth + g_screenHeight) == (1242 + 2208) then
        -- iphone 6 plus
        _ho_x, _ho_y, _ho_c = 620, 1330, 0xddbc84;
        g_clRedCloseX, g_clRedCloseY = 90, 130;
        g_clTableRedRcvValid = {
            {293,  535, 0xcf3a50},
            {293,  864, 0xc3304a},
        }
        g_clTabelRedCloseValid = {
            {620, 260, 0xd84e43},
            {620, 480, 0xfffaf5},
        };
        g_degree = 99;
--]]
    else
        error("您的设备分辨率不被支持");
    end

    local uiTable = {
        ["style"]   = "default",
        ["width"]   = g_screenWidth,
        ["height"]  = g_screenHeight,
        ["config"]  = "dlq_data2.dat",
        ["timer"]   = 360,

        views = {
            {
                ["type"] = "Label",
                ["text"] = "qq抢红包"..g_version,
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
    jsonStr = json.encode(uiTable);
    ret1, g_clickDelay, ret2, ret3 = showUI(jsonStr);
end

function xClick(...)
    touchDown(...)
    touchUp(...)
end

function isColor(x,y,c,s)
    local fl,abs = math.floor,math.abs
    s = fl(0xff*(100-s)*0.01)
    local r,g,b = fl(c/0x10000),fl(c%0x10000/0x100),fl(c%0x100)
    local rr,gg,bb = getColorRGB(x,y)
    if abs(r-rr)<s and abs(g-gg)<s and abs(b-bb)<s then
        return true
    end
end

function multiColor(arr,s)
    local fl,abs = math.floor,math.abs
    s = fl(0xff*(100-s)*0.01)
    keepScreen(true)
    for var = 1, #arr do
        local lr,lg,lb = getColorRGB(arr[var][1],arr[var][2])
        local r = fl(arr[var][3]/0x10000)
        local g = fl(arr[var][3]%0x10000/0x100)
        local b = fl(arr[var][3]%0x100)
        if abs(lr-r) > s or abs(lg-g) > s or abs(lb-b) > s then
            keepScreen(false)
            return false
        end
    end
    keepScreen(false)
    return true
end

-- the reference rect is 123,535 ~ 398,864
function handleRedReceived()
    local x, y;
    local rectBCX; -- bottom center x
    local rectBCY; -- bottom center y

    keepScreen(true);
    -- first check with passwd red, we pick the color at 260,590
    x, y = findMultiColorInRegionFuzzy(0xdf8173,
        "0|-55|0xcf3a50,0|274|0xc3304a,-137|0|0xc3304a,138|0|0xc3304a",
        95, 0, 0, g_screenWidth, g_screenHeight);
    --wLog("test", "pwd found red: x = "..x..", y = "..y);
    if x ~= -1 and y ~= -1 then
        rectBCX = x;
        rectBCY = y + (864 - 590);

        -- find white color in region, if found, the red has not opened
        x, y = findColorInRegionFuzzy(0xd87786, 100,
            rectBCX-(g_rectWidth/2), rectBCY-50, rectBCX+(g_rectWidth/2), rectBCY);
        if x ~= -1 and y ~= -1 then
            xClick(rectBCX, rectBCY-100);
            keepScreen(false);
            return true;
        end
        x, y = findColorInRegionFuzzy(0xe7acb7, 100,
            rectBCX-(g_rectWidth/2), rectBCY-50, rectBCX+(g_rectWidth/2), rectBCY);
        if x ~= -1 and y ~= -1 then
            xClick(rectBCX, rectBCY-100);
            keepScreen(false);
            return true;
        end

    end

    -- first check with normal red, we pick the color at 260,588
    x, y = findMultiColorInRegionFuzzy(0xd8746b,
        "0|-53|0xcf3a50,0|276|0xc3304a,-137|0|0xc3304a,138|0|0xc3304a",
        99, 0, 0, g_screenWidth, g_screenHeight);
    --wLog("test", "nrl found red: x = "..x..", y = "..y);
    if x ~= -1 and y ~= -1 then
        rectBCX = x;
        rectBCY = y + (864 - 588);

        -- find white color in region, if found, the red has not opened
        x, y = findColorInRegionFuzzy(0xd87786, 99,
            rectBCX-(g_rectWidth/2), rectBCY-50, rectBCX+(g_rectWidth/2), rectBCY);
        if x ~= -1 and y ~= -1 then
            xClick(rectBCX, rectBCY-100);
            keepScreen(false);
            return true;
        end
        x, y = findColorInRegionFuzzy(0xe7acb7, 99,
            rectBCX-(g_rectWidth/2), rectBCY-50, rectBCX+(g_rectWidth/2), rectBCY);
        if x ~= -1 and y ~= -1 then
            xClick(rectBCX, rectBCY-100);
            keepScreen(false);
            return true;
        end
    end

    keepScreen(false);
    return false;
end

function handleRedOpen()

    if isColor(g_clWordInputX, g_clWordInputY, g_clWordInputColor, g_degree) then
        if (g_clickDelay == "0") then
            toast("程序延时中,请勿手点红包", 1);
            mSleep(math.random(1500,3000));
        end

        xClick(g_clWordInputX, g_clWordInputY); -- click on word
        xClick(555, 1095); -- click on return button
        return true;
    end

    return false;
end

function handleRedClose()
    if multiColor(g_clTabelRedCloseValid, g_degree) then
        --wLog("test", "close the window");
        xClick(g_clRedCloseX, g_clRedCloseY);
        --mSleep(1000); -- wait close finish
        return true;
    end
    --wLog("test", "not found the color");
    return false;
end

local SWITCH_METATABLE = {
    __index = function(t, k)
        return rawget(t, "__default")
    end,
}

function switchGenerator(tbl)
    tbl = tbl or {}
    setmetatable(tbl, SWITCH_METATABLE)
    return function(case)
        return tbl[case]()
    end, tbl
end

local STATE_IDLE, STATE_RCVED = 0, 1;
local g_state = STATE_IDLE;

function handleDefault()
    wLog("test", "call handleDefault");
end

function handleStateIdle()
    if (handleRedReceived() == true) then
        g_state = STATE_RCVED;
        g_timeout = 0;
        g_closeTimeout = TIMEOUT_CLOSE;
        wLog("test", "handleStateIdle: state switch to "..g_state);
    end
end

function handleStateReceived()
    if isColor(g_clWordInputX, g_clWordInputY, g_clWordInputColor, g_degree) then
        g_closeTimeout = g_closeTimeout + TIMEOUT_OPEN;
        wLog("test", "handleStateReceived: timeout change to "..g_closeTimeout);
        if (g_clickDelay == "0") then
            toast("程序延时中,请勿手点红包", 1);
            mSleep(math.random(1500,3000));
        end

        xClick(g_clWordInputX, g_clWordInputY); -- click on word
        xClick(555, 1095); -- click on return button
    end

    if (handleRedClose() == true) then
        g_state = STATE_IDLE;
        wLog("test", "handleStateReceived: state switch to "..g_state);
    end
end

local switchStateFunc, tblStateMachine = switchGenerator({
        [STATE_IDLE] = handleStateIdle,
        [STATE_RCVED] = handleStateReceived,
        __default = handleDefault,
    });


init(0);
mSleep(1000);

appInit();
initLog("test", 0);

while true do
    -- prevent from no chance to click on the close window
    if (g_state == STATE_RCVED) and (g_timeout > g_closeTimeout) then
        g_timeout = 0;
        g_state = STATE_IDLE;
        wLog("test", "Timeout : state switch to "..g_state);
    else
        g_timeout = g_timeout + 1;
    end

    switchStateFunc(g_state);
	mSleep(200);
end


