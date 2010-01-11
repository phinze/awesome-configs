-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
-- Widget Library
require("vicious")
-- Dynamic Tagging
require("shifty")

-- require("strict")
require("dbg")

--{{{ functions / taginfo
function ti()
  local t = awful.tag.selected()
  local v = ""
 
  v = v .. "<span font_desc=\"Verdana Bold 20\">" .. t.name .. "</span>\n"
  v = v .. tostring(t) .. "\n\n"
  v = v .. "clients: " .. #t:clients() .. "\n\n"
 
  local i = 1
  for op, val in pairs(awful.tag.getdata(t)) do
    if op == "layout" then val = awful.layout.getname(val) end
    if op == "keys" then val = '#' .. #val end
    v = v .. string.format("%2s: %-12s = %s\n", i, op, tostring(val))
    i = i + 1
  end
 
  naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10 }
end
--}}}

--{{{ Show paste
function show_paste()
  local paste = selection()
  paste = naughty.notify({
      text = paste,
      timeout = 6,
      width = 300,
  })
end
--}}}

--{{{ functions / clientinfo
function ci()
  local v = ""

  -- object
  local c = client.focus
  v = v .. tostring(c)

  -- geometry
  local cc = c:geometry()
  local signx = cc.x >= 0 and "+"
  local signy = cc.y >= 0 and "+"
  v = v .. " @ " .. cc.width .. 'x' .. cc.height .. signx .. cc.x .. signy .. cc.y .. "\n\n"

  local inf = {
    "name", "icon_name", "type", "class", "role", "instance", "pid",
    "icon_name", "skip_taskbar", "id", "group_id", "leader_id", "machine",
    "screen", "hide", "minimize", "size_hints_honor", "titlebar", "urgent",
    "focus", "opacity", "ontop", "above", "below", "fullscreen", "transient_for"
   }

  for i = 1, #inf do
    v =  v .. string.format("%2s: %-16s = %s\n", i, inf[i], tostring(c[inf[i]]))
  end

  naughty.notify{ text = v:sub(1,#v-1), timeout = 0, margin = 10 }
end
--}}}

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/default/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "/home/phinze/bin/urxvtc"
browser = "firefox"
editor = "vim"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
modkey = "Mod4"

if screen.count() == 2 then LCD = 2 else LCD = 1 end

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
{
  awful.layout.suit.tile, -- default layout
  awful.layout.suit.tile.bottom,
  awful.layout.suit.floating
}
-- }}}

-- {{{ Shifty
shifty.config.defaults = {
  layout = awful.layout.suit.tile, 
  floatBars = true,
  run = function(tag)
    naughty.notify({ text = "Shifty Created "..
      (awful.tag.getproperty(tag,"position") or shifty.tag2index(mouse.screen,tag)).." : "..
      (tag.name or "foo")
    })
  end,
  guess_name = true,
  persist = false,
  exclusive = true,
  guess_position = true,
  remember_index = true,
  ncol = 1,
  mwfact = 0.5,
  nopopup = true
}
shifty.config.tags = {
    ["1:term"]  = { position = 1, init = true },
    ["2:www"]  =  { position = 2, exclusive = false, nopopup = true },
    ["3:code"] =  { persist = true, position = 3, },
    ["4:comm"] =  { position = 4 },
    ["5:music"] =  { position = 5 },
    ["6:mail"] =  { position = 6 },
    ["7:irc"] =  { position = 6 },
}

shifty.config.apps = {
  { match = {"urxvt"                          }, tag = "1:term",  },
  { match = {"Shiretoko.*", ".* - Vimperator" }, tag = "2:www"    },
  { match = {"chat"                           }, tag = {"7:irc",  "4:comm", "2:www"},  },
  { match = {"mail"                           }, tag = {"6:mail", "4:comm", "2:www"},  },
  { match = {"pandora"                        }, tag = "5:music", },
  { match = {"term:.*"                        }, tag = "1:term",  },
  { match = {"work", "tests", "testing"       }, tag = "3:code",  },
  { match = { "" }, honorsizehints = true,
    buttons = {
      awful.button({ },        1, function (c) client.focus = c; c:raise() end),
      awful.button({ modkey }, 1, function (c) awful.mouse.client.move() end),
      awful.button({ modkey }, 3, function (c) awful.mouse.client.resize() end), 
    }
  }
}

-- }}}

-- {{{ Wibox
-- Create a systray
mysystray = widget({ type = "systray" })

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, awful.tag.viewnext),
                    awful.button({ }, 5, awful.tag.viewprev)
                    )
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

for s = 1, screen.count() do
  -- Create a promptbox for each screen
  mypromptbox[s] = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  mylayoutbox[s] = awful.widget.layoutbox(s)
  -- Create a taglist widget
  mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

  -- Create a tasklist widget
  mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

  -- {{{ Date widget
  datewidget = widget({ type = 'textbox' })
  vicious.register(datewidget, vicious.widgets.date, ' <span color="white">NOW:</span> %a, %b %d, %I:%M%P')
  -- }}}

  -- {{{ Battery percentage and state indicator
  --   - example output +95% or -95% when discharging
  batwidget = widget({ type = "textbox", name = "batwidget", align = "right", width = 100 })
  function get_batstate()
      local filedescriptor = io.popen('bat')
      local value = filedescriptor:read()
      filedescriptor:close()
      return {value}
  end
  vicious.register(batwidget, get_batstate, ' <span color="white">BAT:</span> $1% ', 60)
  -- }}}

  -- {{{ Volume level
  volwidget = widget({ type = "textbox" })
  -- Enable caching
  -- vicious.enable_caching(vicious.widgets.volume)
  -- Register widgets
  vicious.register(volwidget, vicious.widgets.volume, ' <span color="white">VOL:</span> $1%', 60, "PCM")
  -- }}}

  -- {{{ CPU Usage Graph
	cpuwidget = awful.widget.graph()
	cpuwidget:set_width(50)
	cpuwidget:set_background_color('#494B4F')
	cpuwidget:set_color('#FF5656')
	cpuwidget:set_gradient_colors({ '#FF5656', '#88A175', '#AECF96' })
	vicious.register(cpuwidget, vicious.widgets.cpu, '$2', 3)
  -- }}}
    
  -- {{{ Uptime
	uptimewidget = widget({ type = 'textbox' })
	vicious.register(uptimewidget, vicious.widgets.uptime,
		function (widget, args)
		  return string.format(' <span color="white">UP:</span> %dd %dh %dm ', args[2], args[3], args[4])
		end, 61)
  -- }}}

  -- Create the wibox
  mywibox[s] = awful.wibox({ position = "top", screen = s })

  -- Create a table with widgets that go to the right
  right_aligned = {
      layout = awful.widget.layout.horizontal.rightleft
  }
  -- widgets that that only go on main screen
  if s == 1 then
    table.insert(right_aligned, mysystray)
    table.insert(right_aligned, batwidget) 
    table.insert(right_aligned, volwidget) 
    table.insert(right_aligned, memwidget)
    table.insert(right_aligned, uptimewidget)
    table.insert(right_aligned, cpuwidget)
  end
  table.insert(right_aligned, datewidget)
  table.insert(right_aligned, mylayoutbox[s])

  -- Add widgets to the wibox - order matters
  mywibox[s].widgets = {
      mytaglist[s],
      mypromptbox[s],
      right_aligned,
      mytasklist[s],
      layout = awful.widget.layout.horizontal.leftright,
      height = mywibox[s].height
  }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev)
))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore),
 
    awful.key({ modkey            }, "t", function() shifty.add({ rel_index = 1 }) end, nil, "new tag"),
    awful.key({ modkey, "Shift" }, "t", function() shifty.add({ rel_index = 1, nopopup = true }) end, nil, "new tag in bg"),

    awful.key({ modkey            }, "n",       shifty.send_next),          -- move client to next tag
    awful.key({ modkey, "Shift"   }, "n",       shifty.send_prev),          -- move client to prev tag
    awful.key({ modkey, "Control" }, "n",       function ()                 -- move a tag to next screen
        local ts = awful.tag.selected()
        awful.tag.history.restore(ts.screen,1)
        shifty.set(ts,{ screen = awful.util.cycle(screen.count(), ts.screen +1)})
        awful.tag.viewonly(ts)
        mouse.screen = ts.screen

        if #ts:clients() > 0 then
            local c = ts:clients()[1]
            client.focus = c
            c:raise()
        end
        
    end),
    awful.key({ modkey, "Shift"   }, "r", shifty.rename, nil, "tag rename"),
    awful.key({ modkey            }, "w", shifty.del, nil, "tag delete"),

    awful.key({ modkey            }, 'i', ti, nil, "tag info"),
    awful.key({ modkey, "Shift"   }, "i", ci, nil, "client info"),

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

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey,           }, "h", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey,           }, "l", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit),

    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incmwfact( 0.05)    end),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incmwfact(-0.05)    end),
    awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

    awful.key({ modkey,           }, "p", function () show_paste() end, nil, "Show paste"),

    -- Prompt
    awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end),

    -- {{{ bindings / global / prompts / tagjump
    awful.key({ modkey }, "/", function ()
      wi = mypromptbox[mouse.screen].widget
      --wi.bg_image = image("/home/koniu/.config/awesome/icons/arrow.png")

      awful.prompt.run({
          fg_cursor = "#DDFF00", bg_cursor=beautiful.bg_normal, ul_cursor = "single",
          prompt = "» ", text = " ", selectall = true, autoexec = 1
        },
        wi,
        function(n) local t = shifty.name2tag(n); if t then awful.tag.viewonly(t) end end,
        function (cmd, cur_pos, ncomp, matches) return shifty.completion(cmd, cur_pos, ncomp, { "existing" }) end,
        os.getenv("HOME") .. "/.cache/awesome/tagjump",
        nil,
        function() wi.bg_image = nil; wi.text = "" end)
    end, nil, "jump to tag")
    -- }}}
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        )
)

-- Compute the maximum number of digit we need, limited to 9
-- keynumber = 0
-- for s = 1, screen.count() do
--    keynumber = math.min(9, math.max(#tags[s], keynumber));
-- end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
-- for i = 1, keynumber do
--     globalkeys = awful.util.table.join(globalkeys,
--         awful.key({ modkey }, "#" .. i + 9,
--                   function ()
--                         local screen = mouse.screen
--                         if tags[screen][i] then
--                             awful.tag.viewonly(tags[screen][i])
--                         end
--                   end),
--         awful.key({ modkey, "Control" }, "#" .. i + 9,
--                   function ()
--                       local screen = mouse.screen
--                       if tags[screen][i] then
--                           awful.tag.viewtoggle(tags[screen][i])
--                       end
--                   end),
--         awful.key({ modkey, "Shift" }, "#" .. i + 9,
--                   function ()
--                       if client.focus and tags[client.focus.screen][i] then
--                           awful.client.movetotag(tags[client.focus.screen][i])
--                       end
--                   end),
--         awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
--                   function ()
--                       if client.focus and tags[client.focus.screen][i] then
--                           awful.client.toggletag(tags[client.focus.screen][i])
--                       end
--                   end))
-- end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- {{{ bindings / global / shifty.getpos
for i=0, ( shifty.config.maxtags or 9 ) do
  globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey }, i,
  function ()
    local t = awful.tag.viewonly(shifty.getpos(i))
  end))
  globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Control" }, i,
  function ()
    local t = shifty.getpos(i)
    t.selected = not t.selected
  end))
  globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Control", "Shift" }, i,
  function ()
    if client.focus then
      awful.client.toggletag(shifty.getpos(i))
    end
  end))
  -- move clients to other tags
  globalkeys = awful.util.table.join(globalkeys, awful.key({ modkey, "Shift" }, i,
    function ()
      if client.focus then
        t = shifty.getpos(i)
        awful.client.movetotag(t)
        awful.tag.viewonly(t)
      end
    end))
end

-- }}}
-- Set keys
root.keys(globalkeys)
shifty.config.clientkeys = clientkeys
shifty.config.globalkeys = globalkeys
-- }}}

-- {{{ Rules
awful.rules.rules = {
    -- All clients will match this rule.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = true,
                     keys = clientkeys,
                     buttons = clientbuttons } },
    { rule = { class = "MPlayer" },
      properties = { floating = true } },
    { rule = { class = "pinentry" },
      properties = { floating = true } },
    { rule = { class = "gimp" },
      properties = { floating = true } },
    { rule = { class = "Xephyr" },
      properties = { focus = false } },
    -- Set Firefox to always map on tags number 2 of screen 1.
    -- { rule = { class = "Firefox" },
    --   properties = { tag = tags[1][2] } },
}
-- }}}

shifty.taglist = mytaglist
shifty.init()

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
    -- Enable sloppy focus
    c:add_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

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
end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- vim: foldmethod=marker:filetype=lua:expandtab:shiftwidth=2:tabstop=2:softtabstop=2:encoding=utf-8:textwidth=80
