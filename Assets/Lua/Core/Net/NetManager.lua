---
---                 ColaFramework
--- Copyright © 2018-2049 ColaFramework 马三小伙儿
---                Lua端Network管理器
---

local sproto = require "3rd/sproto/sproto"
local core = require "sproto.core"
local Protocol = require("Protocols.Protocol")

local NetManager = {}
local Socket = nil
local listeners = {}
local sprotoCoder = nil
local SPROTO_BYTES_PATH = "SprotoBytes/sproto.bytes"
local code2ProtoNameMap = {}  -- code 到 ProtoName的映射关系
local DUMMY_MSG = {}

local OnConnectedCallback = nil

--- NetManager的初始化
function NetManager.Initialize()
    Socket = SocketManager.Instance
    local sprotoBytes = Common_Utils.LoadTextWithBytes(SPROTO_BYTES_PATH)
    sprotoCoder = sproto.new(sprotoBytes)

    for k, v in pairs(Protocol) do
        code2ProtoNameMap[v] = k
    end

    Socket.OnConnected = NetManager.OnConnected
    Socket.OnReConnected = NetManager.OnReConnected
    Socket.OnClose = NetManager.OnClosed
    Socket.OnFailed = NetManager.OnFailed
    Socket.OnTimeOut = NetManager.OnTimeOut
    NetMessageCenter.Instance.OnMessage = NetManager.OnMessage
    -- TODO:配置网络加密等
end

--- NetManager尝试连接服务器
function NetManager.Connect(ip, port, callback)
    print("-------->try to connect:", ip, port)
    OnConnectedCallback = callback
end

--- 监听网络协议
function NetManager.Register(code, callback)
    if code and code > 0 then
        if nil ~= listeners[code] then
            error("repeat register net event! code is: ", code2ProtoNameMap[code])
            return
        end
        if nil == callback then
            error("register net event callback is nil! code is: ", code2ProtoNameMap[code])
            return
        end
        listeners[code] = callback
    end
end

--- 取消监听网络协议
function NetManager.UnRegister(code)
    listeners[code] = nil
end

--- 取消监听所有的网络协议
function NetManager.UnRegisterAll()
    listeners = {}
end

--- 关闭网络连接
function NetManager.Close(callback)

end

--- 在这里真正去处理网络消息
local function HandleNetMessage(code, msg)

end

--- 处理C#端传到Lua端的消息
function NetManager.OnMessage(code, byteMsg)
    if nil ~= code2ProtoNameMap[code] then
        local msg = sprotoCoder:decode(code2ProtoNameMap[code], byteMsg)
        xpcall(HandleNetMessage, PCALL_ERROR_FUNCTION, code, msg)
    else
        error("NetManager protocol code: ", code, " is not define in Protocol!")
    end
end

--- 处理Socket成功连接服务器
function NetManager.OnConnected()
    if nil ~= OnConnectedCallback then
        OnConnectedCallback()
    end
end

--- 处理网络重连
function NetManager.OnReConnected()

end

--- 处理网络关闭
function NetManager.OnClosed()

end

--- 连接服务器失败
function NetManager.OnFailed()

end

--- 连接服务器超时
function NetManager.OnTimeOut()

end

function NetManager.RequestSproto(code, msg)
    local byteMsg = sprotoCoder:encode(code2ProtoNameMap[code], nil ~= msg and msg or DUMMY_MSG)
    Socket:SendMsg(code, byteMsg)
end

return NetManager