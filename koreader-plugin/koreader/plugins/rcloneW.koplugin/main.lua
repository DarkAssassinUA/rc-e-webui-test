local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local TextViewer = require("ui/widget/textviewer")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local NetworkMgr = require("ui/network/manager")
local _ = require("gettext")
local ffiutil = require("ffi/util")
local T = ffiutil.template
local QRWidget = require("ui/widget/qrwidget")

local rcloneW = WidgetContainer:extend {
    name = "rcloneW",
    is_doc_only = false,
}

function rcloneW:init()
    self.ui.menu:registerToMainMenu(self)
end

local function is_wifi_enabled()
    local f = io.popen("lipc-get-prop com.lab126.cmd wirelessEnable")
    if not f then return false end
    local result = f:read("*a")
    f:close()
    return tonumber(result)
end

local function launch_web_config()
    if is_wifi_enabled() == 0 then
        UIManager:show(InfoMessage:new {
            text = _("Wi-Fi выключен. Пожалуйста, включите Wi-Fi и повторите попытку."),
            timeout = 4
        })
        return
    end

    -- Запускаем web-ui
    os.execute("cd /mnt/us/extensions/rcloneW && ./web-ui &")

    local ip = io.popen("ip route get 1 | awk '{print $7}'"):read("*l")
    local url = "http://" .. ip .. ":8880"
    
    local qr_image = QRWidget:new {
        text = url,
        width = 350,
        height = 350,
        scale_factor = 1
    }

    local infomessage = InfoMessage:new {
        text = _("Отсканируй QRCode для веб-интерфейса или перейди по ссылке: \n\n" .. url .. "\n\nСервер (web-ui) работает, пока открыто это сообщение."),
        image = qr_image.image,
        alignment = "right",
        -- При закрытии окна выполняем скрипт остановки
        dismiss_callback = function() os.execute("cd /mnt/us/extensions/rcloneW && ./web_stop.sh") end
    }

    UIManager:show(infomessage)
end

-- Функция для ручной остановки сервера через меню
local function stop_web_server()
    os.execute("cd /mnt/us/extensions/rcloneW && ./web_stop.sh")
    UIManager:show(InfoMessage:new {
        text = _("Web-UI сервер остановлен."),
        timeout = 3
    })
end

function rcloneW:addToMainMenu(menu_items)
    menu_items.rclone_web_action = {
        text = _("RcloneW"),
        keep_menu_open = true,
        sub_item_table = {
            {
                text = _("Запустить Web-UI сервер"),
                keep_menu_open = true,
                callback = function() 
                    NetworkMgr:runWhenOnline(function() launch_web_config() end) 
                end,
            },
            {
                text = _("Остановить Web-UI сервер"),
                keep_menu_open = true,
                callback = function() stop_web_server() end,
            },
        }
    }
end

return rcloneW