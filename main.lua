require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "layout"
import "android.net.Uri"
import "android.content.Intent"
import "cjson"

--activity.ActionBar.hide()
activity.setContentView(loadlayout(layout))
activity.setTheme(android.R.style.Theme_DeviceDefault_Light)--设置md主题

activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS).setStatusBarColor(0xffffffff);

if Build.VERSION.SDK >= 23 then
  activity.getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR);
end
--导入全屏布局
if Build.VERSION.SDK_INT >= 19 then
  activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS);
end
activity.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
function 全屏()
  window = activity.getWindow();
  window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN|View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN);
  window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
  xpcall(function()
    lp = window.getAttributes();
    lp.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
    window.setAttributes(lp);
  end,
  function(e)
  end)
end
全屏()

function 水珠动画(view,time)
  import "android.animation.ObjectAnimator"
  ObjectAnimator().ofFloat(view,"scaleX",{1,.8,1.1,.9,1}).setDuration(time).start()
  ObjectAnimator().ofFloat(view,"scaleY",{1,.8,1.1,.9,1}).setDuration(time).start()
end

function print(str)
  tip_layout={
    LinearLayout;
    {
      CardView;
      layout_height="wrap";
      layout_width="wrap";
      radius=39;
      elevation=0;
      CardBackgroundColor=0xffF1F0FA;
      layout_margin="20dp";
      layout_marginBottom="50dp";
      {
        LinearLayout;
        layout_height="fill";
        layout_width="fill";
        paddingLeft="15dp";
        paddingRight="15dp";
        paddingTop="15dp";
        paddingBottom="15dp";
        {
          TextView;
          id="text";
          textColor=0xff000000;
          textSize="12sp";
        };
      };
    };
  };
  local toast=Toast.makeText(activity,"t",Toast.LENGTH_SHORT).setView(loadlayout(tip_layout))
  text.Text=tostring(str)
  toast.show()
end

function putData(name,key,value)--写入缓存
  this.getApplicationContext().getSharedPreferences(name,0).edit().putString(key,value).apply()--3255-2732
  return true
end

function getData(name,key)--查询缓存
  local data=this.getApplicationContext().getSharedPreferences(name,0).getString(key,nil)
  return data
end


--RC4加解密算法(lua实现)
local minicrypto = {}
local table_insert = table.insert
local table_concat = table.concat
local math_modf = math.modf
local string_char = string.char

local function numberToBinStr(x)
  local ret = {}
  while x ~= 1 and x ~= 0 do
    table_insert(ret, 1, x % 2)
    x = math_modf(x / 2)
  end
  table_insert(ret, 1, x)
  for i = 1, 8 - #ret do
    table_insert(ret, 1, 0)
  end
  return table_concat(ret)
end

local function computeBinaryKey(str)
  local t = {}
  for i = #str, 1, -1 do
    table_insert(t, numberToBinStr(str:byte(i,i)))
  end
  return table_concat(t)
end

local binaryKeys = setmetatable({}, {__mode = "k"})

local function binaryKey(key)
  local v = binaryKeys[key]
  if v == nil then
    v = computeBinaryKey(key)
    binaryKeys[key] = v
  end
  return v
end

local function initialize_state(key)
  local S = {}
  for i = 0, 255 do
    S[i] = i
  end
  key = binaryKey(key)

  local j = 0
  for i = 0, 255 do
    local idx = (i % #key) + 1
    j = (j + S[i] + tonumber(key:sub(idx, idx))) % 256
    S[i], S[j] = S[j], S[i]
  end
  S.i = 0
  S.j = 0
  return S
end

local function encrypt_one(state, byt)
  state.i = (state.i + 1) % 256
  state.j = (state.j + state[state.i]) % 256
  state[state.i], state[state.j] = state[state.j], state[state.i]
  local K = state[(state[state.i] + state[state.j]) % 256]
  return K ~ byt
end

function minicrypto.encrypt(text, key)
  local state = initialize_state(key)
  local encrypted = {}
  for i = 1, #text do
    encrypted[i] = ("%02X"):format(encrypt_one(state, text:byte(i,i)))
  end
  return table_concat(encrypted)
end

function minicrypto.decrypt(text, key)
  local state = initialize_state(key)
  local decrypted = {}
  for i = 1, #text, 2 do
    table_insert(decrypted, string_char(encrypt_one(state, tonumber(text:sub(i, i + 1), 16))))
  end
  return table_concat(decrypted)
end



import "android.provider.Settings$Secure"
local androidID=Secure.getString(activity.getContentResolver(), Secure.ANDROID_ID)
local ownID="by.Mist"..androidID

import "java.io.*"
local _file,_err=io.open("/sdcard/Android/lastKey")
if _err~=nil then
  io.open("/sdcard/Android/lastKey", 'w')
end

function addDate(date)
  local _default = {years=0, months=0, days=0, hours=0, minutes=0, seconds=0}
  setmetatable(date, {__index = _default})
  local _year, _month, _day, _hour, _minute, _second = date["time"]:match("(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)%D(%d+)")
  local newDate = os.time({
    year = _year + date["years"],
    month = _month + date["months"],
    day = _day + date["days"],
    hour = _hour + date["hours"],
    min = _minute + date["minutes"],
    sec = _second + date["seconds"]
  }) + 0 * 24 * 3600
  return os.date("%Y-%m-%d %H:%M:%S", newDate)
end

--[[
--这里是生成授权码的例子
function 生成授权码(date,ownID)
  local userId=ownID:match("by.Mist(.+)")
  return "by.Mist"..minicrypto.encrypt( userId .. "_ {\""..date["type"].."\":" .. date["number"] .." }", ownID)
end
local tempDate={
  ["type"]="days",
  ["number"]=1
}
key.setText(生成授权码(tempDate,ownID))
]]


function 检测授权信息自动登录()
  local keyValidate = getData("key_validate",ownID)
  if (keyValidate == nil or keyValidate == "0") then
    putData("key_validate", ownID, "0")
   else
    local decDate = minicrypto.decrypt(keyValidate, ownID)
    local decDateTab = cjson.decode(decDate)
    local overTime = decDateTab["overTime"]
    local currentTime = os.date("%Y-%m-%d %H:%M:%S")

    if (overTime <= currentTime) then
      print("授权时间已过期.")
     elseif (overTime >= currentTime) then
      print("授权获取成功，到期时间:"..overTime)
      decDateTab["overTime"] = overTime
      local encDateTab = minicrypto.encrypt(cjson.encode(decDateTab), ownID)
      putData("key_validate", ownID, encDateTab)

      activity.newActivity("MainActivity",{828258})
      activity.finish()
    end
  end
end
检测授权信息自动登录()

-- 读取文件的每一行
function read_lines(filename)
  local lines = {}
  for line in io.lines(filename) do
    table.insert(lines, line)
  end
  return lines
end

function findStringInTable(str, tbl)
  for key, value in pairs(tbl) do
    if type(value) == "string" and value == str then
      return true
     elseif type(value) == "table" then
      if findStringInTable(str, value) then
        return true
      end
    end
  end
  return false
end
--[[
Powered by Cx330(Mist)
任何形式的二改，转载请留名！
]]
单码登录.onClick=function()
  local keyText = key.text
  local LastKeyPath = "/sdcard/Android/lastKey"
  local lines = read_lines(LastKeyPath)

  if #keyText == 0 then
    print("授权码不能为空.")
   else
    local _Key = keyText:match("by.Mist(.+)")
    local status, decKey = pcall(minicrypto.decrypt, _Key, ownID)

    if status then
      local userData, DateTab = decKey:match("(.+)_(.+)")
      local status, decDateTab = pcall(function() return cjson.decode(DateTab) end)

      if status then
        decDateTab["time"] = os.date("%Y-%m-%d %H:%M:%S")

        if userData == androidID then
          local overTime = addDate(decDateTab)

          if overTime <= os.date("%Y-%m-%d %H:%M:%S") then
            print("授权时间已过期.")
           elseif overTime >= os.date("%Y-%m-%d %H:%M:%S") then
            local key_validate = getData("key_validate", ownID)

            if key_validate == nil or key_validate == "0" then
              if findStringInTable(keyText, lines) then
                print("授权码已被使用.")
               else
                print("授权获取成功，到期时间:" .. overTime)
                decDateTab["overTime"] = overTime
                local encDateTab = minicrypto.encrypt(cjson.encode(decDateTab), ownID)
                putData("key_validate", ownID, encDateTab)
                io.open(LastKeyPath, "a+"):write(keyText .. "\n"):close()
                activity.newActivity("MainActivity", { 828258 })
                activity.finish()
              end
             else
              local decDate = minicrypto.decrypt(key_validate, ownID)
              local decDateTab = cjson.decode(decDate)
              local overTime = decDateTab["overTime"]

              if overTime <= os.date("%Y-%m-%d %H:%M:%S") then
                print("授权时间已过期.")
               elseif overTime >= os.date("%Y-%m-%d %H:%M:%S") then
                if findStringInTable(keyText, lines) then
                  print("授权码已被使用.")
                 else
                  print("授权获取成功，到期时间:" .. overTime)
                  decDateTab["overTime"] = overTime
                  local encDateTab = minicrypto.encrypt(cjson.encode(decDateTab), ownID)
                  putData("key_validate", ownID, encDateTab)
                  io.open(LastKeyPath, "a+"):write(keyText .. "\n"):close()
                  activity.newActivity("MainActivity", { 828258 })
                  activity.finish()
                end
               else
                print("授权时间已过期.")
              end
            end
          end
         else
          print("授权码错误.")
        end
       else
        print("授权时间数据解析错误.")
      end
     else
      print("授权码解析错误.")
    end
  end
end

联系作者.onClick=function()
  水珠动画(联系作者,180)
  local url="mqqwpa://im/chat?chat_type=wpa&uin=2590291292"
  activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
end

解绑卡密.onClick=function()
  水珠动画(解绑卡密,180)
  putData("key_validate", ownID, "0")

  print("解绑成功已消除记录")
end

使用帮助.onClick=function()
  水珠动画(使用帮助,180)
  AlertDialog.Builder(this).setTitle("使用帮助")
  .setMessage("\r\r\r\r点击下方按钮复制你的编码，而后点击软件底部的联系作者获取授权码，获取完毕后输入授权码登录即可.\n\n用户编码:"..ownID)
  .setPositiveButton("复制编码",function()
    import "android.content.Context"
    activity.getSystemService(Context.CLIPBOARD_SERVICE).setText(ownID)
    print("已复制")
  end)
  .show();
end
