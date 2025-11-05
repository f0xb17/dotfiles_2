pcall(require, "luarocks.loader")

local gears = require("gears")
local awful = require("awful")
              require("awful.autofocus")
local beautiful = require("beautiful")
local naugthy = require("naughty")
local hotkeys_popup = require("awful.hotkeys_popup")
local menubar = require("menubar")
local wibox = require("wibox")

if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Error during startup!",
        text = awesome.startup_errors})
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Something went wrong!",
            text = tostring(err)})
        in_error = false
    end)
end

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.useless_gap = 15

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then
            wallpaper = wallpaper(s)
        end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

screen.connect_signal("property:geometry", set_wallpaper)

awful.layout.layouts = {
    awful.layout.suit.spiral.dwindle
}

local taglist_buttons = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end)
)

awful.screen.connect_for_each_screen(function (s)
    set_wallpaper(s)
    awful.tag({ "1", "2", "3", "4", "5" }, s, awful.layout.layouts[1])

    s.mytaglist = awful.widget.taglist {
        screen = s,
        filter = awful.widget.taglist.filter.all,
        buttons = taglist_buttons
    }

    s.mywibox = awful.wibar({ position = "top", screen = s })
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            s.mytaglist
        },
        s.mytasklist,
        {
            layout = wibox.layout.fixed.horizontal,
            wibox.widget.systray()
        }
    }
end)

modkey = "Mod4"

globalkeys = gears.table.join(
    awful.key({ modkey, }, "s", hotkeys_popup.show_help,
              {description="show help", group="awesome"}),
    awful.key({ modkey, }, "Return", function () awful.spawn(terminal) end,
              {description="open a terminal window", group="launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              {description="reload awesome", group="awesome"}),
    awful.key({ modkey, "Shift" }, "q", awesome.quit,
              {description="quit awesome", group="awesome"}),
    awful.key({ modkey, }, "r", function () awful.spawn("rofi -show drun") end,
              {description="open rofi", group="launcher"}),
    awful.key({ modkey, }, "q", 
        function ()
            if client.focus then
                client.focus:kill()
            end
        end, 
    {description="close focused client", group="launcher"})
)

for i = 1, 5 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey, }, "#" .. i + 9,
            function ()
                local screen = awful.screen.focused()
                local tag = screen.tags[i]
                if tag then
                    tag:view_only()
                end
            end,
        {description = "view tag #"..i, group = "tag"}),
        awful.key({ modkey, "Shift"}, "#" .. i + 9,
            function ()
                if client.focus then
                    if client.focus then
                        local tag = client.focus.screen.tags[i]
                        if tag then
                            client.focus:move_to_tag(tag)
                        end
                    end
                end
            end,
        {description = "move focused client to tag #"..i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
    end),
    awful.button({ modkey }, 1, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function (c)
        c:emit_signal("request::activate", "mouse_click", {raise = true})
        awful.mouse.client.resize(c)
    end)
)

root.keys(globalkeys)

awful.rules.rules = {
    {
        rule = { },
        properties = 
        {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus = awful.client.focus.filter,
            raise = true,
            keys = clientkeys,
            buttons = clientbuttons,
            screen = awful.screen.preferred,
            placement = awful.placement.no_overlap+awful.placement.no_offscreen
        }
    },
    {
        rule_any = 
        {
            instance = {},
            class = {},
            name = {},
            role = {},
        },
        properties = { floating = true }
    },
    {
        rule_any = { type = { "normal", "dialog" } },
        properties = { titlebars_enabled = true, placement = awful.placement.centered }
    }
}

client.connect_signal("manage", function (c)
    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
