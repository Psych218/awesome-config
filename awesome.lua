require("awful")
require("awful.autofocus")
require("awful.rules")
require("beautiful")
require("naughty")
require("vicious")
require("rodentbane")


-- Переменные (для использования в конфиге)
awehome = awful.util.getdir("config") .. "/"
username = os.getenv("USER")
terminal = "urxvt"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor
modkey = "Mod4"
browser = "uzbl-browser"

-- тема
beautiful.init(awehome .. "qliphoth/theme.lua")

layouts = {
            awful.layout.suit.floating, --1
            awful.layout.suit.tile, --2 
            awful.layout.suit.max, --3
            awful.layout.suit.max.fullscreen, --4
          }


tags = {}
tags[1] = awful.tag({ "c", "b", "o", "m", "g", "t" }, 1, layouts[3])
awful.layout.set(layouts[2], tags[1][5])


naughty.config.default_preset.position         = "bottom_right"
naughty.config.default_preset.margin           = 4
naughty.config.default_preset.gap              = 1
naughty.config.default_preset.border_width     = 1


-- МЕНЮ {{{
mymainmenu = awful.menu({ items = { 
                                    { "terminal", terminal },
                                    { "restart", awesome.restart },
                                    { "quit", awesome.quit },
                                  }
                        })
mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon), menu = mymainmenu })
--- МЕНЮ }}}



mytimer3 = timer({ timeout = 3 })
mytimer2 = timer({ timeout = 2 })
mytimer1800 = timer({ timeout = 1800 })
mytimer600 = timer({ timeout = 600 })

-----------------------------
-- ВИДЖЕТЫ ------------------
-----------------------------

-- Splitter (разделитель)
sp = widget({ type = "textbox" })
sp.text = " | "

-- Память
memic  = widget({ type = "imagebox", align = "right" })
memic.image  = image( beautiful.memory_icon )
memwidget = widget({ type = "textbox" })
function memInfo()
    local mem = {}
    mem.free = 0
    for line in io.lines("/proc/meminfo") do
        for k, v in string.gmatch(line, "([%a]+):[%s]+([%d]+).+") do
            if     k == "MemTotal"  then mem.total = v
            elseif k == "MemFree" or k == "Buffers" or k == "Cached"  then mem.free = v+mem.free
            end 
        end 
    end 
    memwidget.text = " " .. 100-math.floor(mem.free / mem.total * 100) .. "%"
end
memInfo()
--awful.hooks.timer.register(3, function() memInfo() end)
mytimer3:add_signal("timeout", function() memInfo() end)

-- Процессор
cpuic  = widget({ type = "imagebox", align = "right" })
cpuic.image  = image( beautiful.cpu_icon )
cpuwidget = widget({ type = "textbox" })
function cpuInfo()
   for line in io.lines("/proc/stat") do
       local cpu, newjiffies = string.match(line, "(cpu)\ +(%d+)")
       if cpu and newjiffies then
           if not jiffies then
               jiffies = newjiffies
           end
           cpuwidget.text = " " .. string.format("%02d", (newjiffies-jiffies)/4) .. "% "
           jiffies = newjiffies
       end
   end
   end
--awful.hooks.timer.register(2, function() cpuInfo() end)
mytimer2:add_signal("timeout", function() cpuInfo() end)



-- Громкость
volic  = widget({ type = "imagebox", align = "right" })
volic.image  = image( beautiful.volume_icon )
volwidget = widget({ type = "textbox" })
function volInfo()
    local f = io.popen("amixer get Master")
    local mixer = f:read("*all")
    f:close()
    local volu, mute = string.match(mixer, "([%d]+)%%.*%[([%l]*)")
    if volu == nil then
       volu = 0
       mute = "off"
    end 
    if mute == "" and volu == "0" or mute == "off" then
       mute = "on"
    else
       mute = "off"
    end
    volu = tonumber(volu)
    if volu < 40 then volic.image  = image( beautiful.vollow_icon ) end
    if volu > 39 and volu < 65 then volic.image  = image( beautiful.volmed_icon ) end
    if volu > 64 then volic.image  = image( beautiful.volhigh_icon ) end
    if mute == "on" then volic.image  = image( beautiful.mute_icon ) end
    volwidget.text = volu .. "%"
end
--awful.hooks.timer.register(2, function() volInfo() end)
mytimer2:add_signal("timeout", function() volInfo() end)
volic:buttons(awful.util.table.join(
    awful.button({ }, 1, function() awful.util.spawn("amixer -q set Master toggle") volInfo() end),
    awful.button({ }, 3, function() awful.util.spawn(terminal .. " -e alsamixer") end),
    awful.button({ }, 4, function() awful.util.spawn("amixer set Master 2dB+") volInfo() end),
    awful.button({ }, 5, function() awful.util.spawn("amixer set Master 2dB-") volInfo() end)
))



-- Джаббер
chic  = widget({ type = "imagebox", align = "right" })
chic.image  = image( beautiful.chat_icon )
chwidget = widget({ type = "textbox" })
function chInfo()
    local f = io.popen("cat .mcabber/mcabber.state | wc -l")
    local n = f:read("*all")
    f:close()
    if n == "0\n" then nn = "0"
    else nn = '<span color="#FF0000">'.. n ..'</span>'
    end
    chwidget.text = " ".. nn
end
--awful.hooks.timer.register(2, function() chInfo() end)
mytimer2:add_signal("timeout", function() chInfo() end)


-- Место на дисках
fsic  = widget({ type = "imagebox", align = "right" })
fsic.image  = image( beautiful.disk_icon )
fswidget = widget({type = "textbox", name = "fswidget", align = "right" })
tmpfs = 0
function fsInfo()
   tmpfs = tmpfs+1
   if tmpfs > 2 then tmpfs = 0 end
   local mountp = ""
   if tmpfs == 0 then mountp = "/dev/sda4" n = "h" end
   if tmpfs == 1 then mountp = "/dev/sdb"  n = "m" end
   if tmpfs == 2 then mountp = "ab396d31-58e6-4196-a383-07a0c00fb3dc" n = "/" end
   local f = io.popen('df -kP | grep -e '.. mountp)
   local ff = f:read()
   local u,a,p = string.match(ff, "([%d]+)[%D]+([%d]+)[%D]+([%d]+)%%")
   a = a / 1048576
   fswidget.text = n .. ": " .. string.format("%.1f",a) .. "Gb"
   f:close()
end
fsInfo()
--awful.hooks.timer.register(3, function() fsInfo() end)
mytimer3:add_signal("timeout", function() fsInfo() end)



-- Сменяем обоину
num = 0
function wpchange()
    if num > 3 then num = 0 end
    num = num+1
    awful.util.spawn("awsetbg -c " .. beautiful.path .. "bg0" .. num .. ".jpg")
end
--awful.hooks.timer.register(1800, function() wpchange() end)
mytimer1800:add_signal("timeout", function() wpchange() end)


--Активность сети
netupic = widget({ type = "imagebox", align = "right" })
netupic.image  = image( beautiful.upload_icon )
netdownic = widget({ type = "imagebox", align = "right" })
netdownic.image  = image( beautiful.download_icon )
netwidget = widget({ type = "textbox" })
vicious.register(netwidget, vicious.widgets.net, " ${eth0 down_mb} | ${eth0 up_mb} ")

-- Почта
mailic = widget({ type = "imagebox", align = "right" })
mailic.image  = image( beautiful.mail_icon )
mailwidget = widget({ type = "textbox" })
vicious.register(mailwidget, vicious.widgets.mboxc, " $3", 10, {"/var/mail/" .. username})



-- Часы
clockic  = widget({ type = "imagebox", align = "right" })
clockic.image  = image( beautiful.time_icon )
mytextclock = awful.widget.textclock({ align = "right" })
local calendar = nil
local offset = 0
function remove_calendar()
    if calendar ~= nil then
        naughty.destroy(calendar)
        calendar = nil
        offset = 0
    end
end
function add_calendar(inc_offset)
    local save_offset = offset
    remove_calendar()
    offset = save_offset + inc_offset
    local datespec = os.date("*t")
    datespec = datespec.year * 12 + datespec.month - 1 + offset
    datespec = (datespec % 12 + 1) .. " " .. math.floor(datespec / 12)
    local cal = awful.util.pread("cal -m " .. datespec)
    cal = string.gsub(cal, "^%s*(.-)%s*$", "%1")
    calendar = naughty.notify({
        text = string.format(os.date("%a, %d %B %Y") .. "\n\n" .. cal),
        timeout = 0, hover_timeout = 0.5
    })
end
clockic:buttons(awful.util.table.join(
    awful.button({ }, 1, function() add_calendar(0) end),
    awful.button({ }, 3, remove_calendar),
    awful.button({ }, 4, function() add_calendar(-1) end),
    awful.button({ }, 5, function() add_calendar(1) end)
))

 
-- Трэй
mysystray = widget({ type = "systray" })

-- Виджет показывает песню
music = widget({ type = "imagebox", align = "right" })
music.image  = image( beautiful.music_icon )
muswidget = widget({type = "textbox", name = "muswidget", align = "right" })
-- local f = io.popen("mocp -Q'%a - %t' || echo STOPPED | "..awehome.."dbunand")
--awful.hooks.timer.register(2, function()
mytimer2:add_signal("timeout", function()
    local f = io.popen("deadbeef --nowplaying '%a - %t' | "..awehome.."dbunand")
    muswidget.text = " " .. f:read()
    f:close()
end)

-- Погода и луна
weaic = widget({ type = "imagebox", align = "right" })
moonic = widget({ type = "imagebox", align = "right" })
weawidget = widget({type = "textbox", name = "weawidget", align = "right" })
function wInfo()
     local f = io.popen(awehome .. 'conkyForecast.py --location=RSXX0063 --datatype=HT')
     local i = io.popen(awehome .. 'conkyForecast.py --location=RSXX0063 --datatype=WI')
     local m = io.popen(awehome .. 'conkyForecast.py --location=RSXX0063 --datatype=MI')
     weaic.image = image ( i:read() )
     moonic.image = image ( m:read() )
     weawidget.text = " " ..f:read()
     f:close()
     i:close()
     m:close()
end
wInfo()
--awful.hooks.timer.register(600, function()  wInfo() end)
mytimer600:add_signal("timeout", function() wInfo() end)
weaic:buttons(awful.util.table.join(
    awful.button({ }, 1, function() awful.util.spawn(browser .. " http://pogoda.yandex.ru/") volInfo() end)
))
moonic:buttons(awful.util.table.join(
    awful.button({ }, 1, function() awful.util.spawn(browser .. " http://www.astrosystem.ru/AstroSystem/Main/Prognoz/MoonTransits") volInfo() end)
))

-- Тэги
mytaglist = awful.widget.taglist(1,
                                 awful.widget.taglist.label.all,
                                 awful.util.table.join(
                                                      awful.button({ }, 1, awful.tag.viewonly),
                                                      awful.button({ modkey }, 1, awful.client.movetotag),
                                                      awful.button({ }, 3, awful.tag.viewtoggle),
                                                      awful.button({ modkey }, 3, awful.client.toggletag),
                                                      awful.button({ }, 4, awful.tag.viewnext),
                                                      awful.button({ }, 5, awful.tag.viewprev)))

-- виджет "панель задач"
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if not c:isvisible() then
                                                  awful.tag.viewonly(c:tags()[1])
                                              end
                                              client.focus = c
                                              c:raise()
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))
mytasklist = awful.widget.tasklist(function(c)
                                              return awful.widget.tasklist.label.currenttags(c, 1)
                                          end, mytasklist.buttons)

-- виджет для ввода
mypromptbox = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })

-- Виджет для переключения (отображения) лэйаута
mylayoutbox = awful.widget.layoutbox(1)
mylayoutbox:buttons(awful.util.table.join(
                       awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                       awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                       awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                       awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))


mytimer3:start()
mytimer2:start()
mytimer1800:start()
mytimer600:start()
---------------------------
-- ПАНЕЛИ------------------
---------------------------
mywibox = awful.wibox({ position = "bottom", screen = 1 })
mytb = awful.wibox({ position = "top", screen = 1 })

-- нижняя панель
mywibox.widgets = {
    {
        -- виджеты нижней панели (слева-направо)
        mytaglist,
        mypromptbox, sp,
        moonic, sp,
        weaic, weawidget, sp, 
        memic, memwidget, sp,
        cpuic, cpuwidget, sp,
        mailic, mailwidget, sp,
        chic, chwidget, sp,
        volic, volwidget, sp,
        netdownic, netwidget, netupic, sp,
        fsic, fswidget,
        layout = awful.widget.layout.horizontal.leftright,
    },
    -- виджеты нижней панели (справа-налево)
    mytextclock, clockic, sp,
--    dbwidget, dbic,
    muswidget,music,
    layout = awful.widget.layout.horizontal.rightleft,
}

-- верхняя панель
mytb.widgets = {
    {
        -- виджеты верхней панели (слева-направо)
--        mylauncher,
        mylayoutbox,
        layout = awful.widget.layout.horizontal.leftright,
    },
    -- виджеты верхней панели (справа-налево)
    mysystray,
    mytasklist,
    s == 1 and mysystray or nil,
    layout = awful.widget.layout.horizontal.rightleft,
}


---------------------------------
-- КНОПКИ МЫШИ НА РАБОЧЕМ СТОЛЕ--
---------------------------------

root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))


---------------------------------
-- КЛАВИАТУРА--------------------
---------------------------------

globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

    awful.key({ modkey,           }, "j",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "k",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey,           }, "w", function () mymainmenu:show(true)        end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    awful.key({ modkey, "Control", "Mod1"}, "l", function () awful.util.spawn("xscreensaver-command -lock") end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey,           }, "F1", function () awful.util.spawn(terminal .. " -pe tabbed") end),
    awful.key({ modkey,           }, "F2", function () awful.util.spawn("uzbl-browser") end),
    awful.key({ modkey,           }, "F4", function () awful.util.spawn("deadbeef") end),
    awful.key({ modkey,           }, "F5", function () awful.util.spawn("gimp") end),
    
    awful.key({"" }, "XF86AudioRaiseVolume", function () awful.util.spawn("amixer set Master 2dB+") end),
    awful.key({"" }, "XF86AudioLowerVolume", function () awful.util.spawn("amixer set Master 2dB-") end),
    awful.key({"" }, "XF86AudioMute", function () awful.util.spawn("amixer -q set Master toggle") end),

     awful.key({modkey,  }, "XF86AudioPlay", function () awful.util.spawn("deadbeef --play") end),
     awful.key({"" }, "XF86AudioPlay", function () awful.util.spawn("deadbeef --pause") end),
     awful.key({"" }, "XF86AudioStop", function () awful.util.spawn("deadbeef --stop") end),
     awful.key({"" }, "XF86AudioPrev", function () awful.util.spawn("deadbeef --prev") end),
     awful.key({"" }, "XF86AudioNext", function () awful.util.spawn("deadbeef --next") end),
--     awful.key({modkey, }, "XF86AudioPlay", function () awful.util.spawn(terminal .. " -e mocp") end),
--     awful.key({"" }, "XF86AudioPlay", function () awful.util.spawn("mocp -G") end),
--     awful.key({"" }, "XF86AudioStop", function () awful.util.spawn("mocp -s") end),
--     awful.key({"" }, "XF86AudioPrev", function () awful.util.spawn("mocp -r") end),
--     awful.key({"" }, "XF86AudioNext", function () awful.util.spawn("mocp -f") end),

    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),
    awful.key({ modkey,           }, "q", function ()rodentbane.start() end),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox.widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
    
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)

)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        if tags[screen][i] then
                            awful.tag.viewonly(tags[screen][i])
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      if tags[screen][i] then
                          awful.tag.viewtoggle(tags[screen][i])
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.movetotag(tags[client.focus.screen][i])
                      end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      if client.focus and tags[client.focus.screen][i] then
                          awful.client.toggletag(tags[client.focus.screen][i])
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)




-----------------------------------
-- Правила для окошек--------------
-----------------------------------

awful.rules.rules = {
    -- Правило для всех окон (далее можно переопределить для конкретных)
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     tag = tags[1][3] } },
    -- Правила для разных приложений
    { rule = { class = "MPlayer" },  properties = { floating = true } },
    { rule = { class = "Namoroka" }, properties = { tag = tags[1][2] } },
    { rule = { class = "Firefox" }, properties = { tag = tags[1][2] } },
    { rule = { class = "Uzbl-core" }, properties = { tag = tags[1][2] } },
    { rule = { class = "URxvt" }, properties = { tag = tags[1][1] } },
    { rule = { class = "Deadbeef" }, properties = { tag = tags[1][4] } },
    { rule = { class = "Gimp" }, properties = { tag = tags[1][5] } },
    { rule = { role = "gimp-toolbox" }, properties = { floating = false } }, -- окошко инструментов гимпа встаёт в тайлинг
    
}





-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)

    if not startup then
        -- Set the windows at the slave,
        -- i.e. put it at the end of others instead of setting it master.
        -- awful.client.setslave(c)

        -- Put windows in a smart way, only if they does not set an initial position.
        if not c.size_hints.user_position and not c.size_hints.program_position then
            awful.placement.no_overlap(c)
            awful.placement.no_offscreen(c)
        end
    end

    -- Эта строчка, чтобы между терминалами не было пространства
    c.size_hints_honor = false

end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)



---------------------
-- Автозапуск--------
---------------------

--autorunApps = { 
--  "killall unclutter",
--  "unclutter -idle 3",
--}
--for app = 1, #autorunApps do
--   awful.util.spawn(autorunApps[app])
--end
