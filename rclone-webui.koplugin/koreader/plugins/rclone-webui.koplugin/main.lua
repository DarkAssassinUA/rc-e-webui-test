local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local NetworkMgr = require("ui/network/manager")
local _ = require("gettext")

-- Название плагина в системе KOReader
local RcloneManager = WidgetContainer:extend {
    name = "rclone web-ui",
    is_doc_only = false,
}

-- Правильный путь к папке плагина KOReader на Kindle
local PLUGIN_PATH = "/mnt/us/koreader/plugins/rclone-webui.koplugin/"

function RcloneManager:init()
    self.ui.menu:registerToMainMenu(self)
end

-- Проверка статуса Wi-Fi
local function is_wifi_enabled()
    local f = io.popen("lipc-get-prop com.lab126.cmd wirelessEnable")
    if not f then return "0" end
    local result = f:read("*a")
    f:close()
    return result:gsub("%s+", "")
end

-- Кнопка 1: ЗАПУСК
local function start_server()
    if is_wifi_enabled() == "0" then
        UIManager:show(InfoMessage:new {
            text = _("Wi-Fi выключен. Включите Wi-Fi для запуска сервера."),
            timeout = 4
        })
        return
    end

    -- Переходим в папку плагина и запускаем сервер в фоне (&)
    os.execute("cd " .. PLUGIN_PATH .. " && ./kindle_manager &")

    -- Получаем локальный IP адрес
    local f = io.popen("ip route get 1 | awk '{print $7}'")
    local ip = f:read("*l")
    f:close()

    -- Показываем всплывающее уведомление на 5 секунд
    UIManager:show(InfoMessage:new {
        text = _("Сервер запущен!\nАдрес: http://" .. (ip or "IP_не_найден") .. ":8080"),
        timeout = 5
    })
end

-- Кнопка 2: ОСТАНОВКА
local function stop_server()
    -- Убиваем процесс сервера
    os.execute("killall kindle_manager")
    
    UIManager:show(InfoMessage:new {
        text = _("Сервер Rclone остановлен."),
        timeout = 3
    })
end

-- Добавляем кнопки в меню
function RcloneManager:addToMainMenu(menu_items)
    menu_items.rclone_manager = {
        text = _("Rclone Web-UI"),
        keep_menu_open = true,
        sub_item_table = {
            {
                text = _("▶ Запустить сервер"),
                keep_menu_open = true,
                callback = function()
                    NetworkMgr:runWhenOnline(function() start_server() end)
                end
            },
            {
                text = _("⏹ Остановить сервер"),
                keep_menu_open = true,
                callback = function() return stop_server() end,
            },
        }
    }
end

return RcloneManager