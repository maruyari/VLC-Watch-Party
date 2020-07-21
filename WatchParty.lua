--
-- User: rutvora
--

MAX_LEN = 2048
name = ""
room = ""
debug = true

function log(message)
    if debug then
        vlc.msg.info(message)
    end
end

--Because the inbuilt trim funciton crashes for some reason
function trim(str)
    return string.gsub(str, "^%s*(.-)%s*$", "%1")
end

function descriptor()
    return {
        title = "Watch Party";
        version = "0.1";
        author = "Rut Vora & Tanya Prasad";
        capabilities = {}
    }
end

function activate()
    -- Function will not complete if the server isn't running
    localConnection = vlc.net.connect_tcp("localhost", "8000")
    local dialog = vlc.dialog("Watch Party")
    chat = dialog:add_html([[<h3> Commands </h3> <br>
                                <b> Set/change name: </b> \name YOUR-NAME <br>
                                <b> Join/Create room: </b> \room ROOM-NAME <br>
                                <b> Play: </b> \play <br>
                                <b> Pause: </b> \pause <br>
                                <b> Stop: </b> \stop <br>
                                <b> Else: </b> Send message to room ]], 1, 1, 5, 5)
    input = dialog:add_text_input("", 1, 6, 4, 1)
    dialog:add_button("Send", send, 5, 6, 1, 1)
    dialog:show()
    --    pollfds = {}
    --    pollfds[localConnection] = vlc.net.POLLIN
    --    vlc.net.poll(pollfds)
    --    local response = vlc.net.recv(localConnection, MAX_LEN) --Because message will never exceed 2048
end

function updateChat(str)
    chat:set_text(chat:get_text() .. "<br>" .. str)
end

function split_words(input_text)
    local words = {}
    local count = 0
    for w in (input_text .. ' '):gmatch("([^ ]* )") do
        table.insert(words, w)
        count = count + 1
    end
    -- Because calling trim in the loop above, while inserting has some issues
    for index, value in ipairs(words) do
        words[index] = trim(value)
    end
    return words, count
end

function change_user(words, count)
    local set_name = ""
    for i = 2, count, 1 do
        set_name = set_name .. words[i] .. ' '
    end
    name = trim(set_name)
    updateChat("You changed your name to " .. name)
    input:set_text("")
end

function join_room(words, count)
    local set_room = ""
    for i = 2, count, 1 do
        set_room = set_room .. words[i] .. ' '
    end
    room = trim(set_room)
    updateChat("You joined " .. room)
    input:set_text("")
end

function play()
    if vlc.playlist.status() ~= "playing" then
        vlc.playlist.play()
        updateChat("You started playing")
    end
    input:set_text("")
end

function pause()
    if vlc.playlist.status() == "playing" then
        vlc.playlist.pause()
        updateChat("You paused")
    end
    input:set_text("")
end

function stop()
    vlc.playlist.stop()
    updateChat("You stopped the video")
    input:set_text("")
end

function process_commands(input_text)
    local words, count = split_words(input_text)
    if words[1] == "\\name" then
        change_user(words, count)
        return
    elseif words[1] == "\\room" then
        join_room(words, count)
        return
    end
    if name == "" then
        updateChat("You haven't set your name. Set it using \\name YOUR-NAME")
    end
    if room == "" then
        updateChat("No room set. Join or create one with \\room ROOM-NAME (no spaces)")
    end
    if name == "" or room == "" then
        return
    end
    if words[1] == "\\play" then
        play()
        return
    elseif words[1] == "\\pause" then
        pause()
        return
    elseif words[1] == "\\stop" then
        stop()
        return
    else
        updateChat("Invalid command")
        input:set_text("")
    end
end

function send()
    local input_text = input:get_text()
    input_text = trim(input_text)
    --    vlc.net.send(localConnection, input_text .. '\r') --Using \r as end of message
    if input_text:sub(1, 1) == '\\' then
        process_commands(input_text)
    end
    if name == "" then
        updateChat("You haven't set your name. Set it using \\name YOUR-NAME")
        return
    end
end

function deactivate()
    vlc.net.close(localConnection)
end

function close()
    vlc.deactivate()
end
