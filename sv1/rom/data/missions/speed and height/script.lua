g_cmd = '?widget'
g_spd_unit_tbl = {
    ['km/h'] = 216,
    ['kph'] = 216,
    ['kmph'] = 216,
    ['km/hr'] = 216,

    ['m/s'] = 60,
    ['mps'] = 60,

    ['kt'] = 216000.0/1852.0,
    ['kn'] = 216000.0/1852.0,
}
g_alt_unit_tbl = {
    ['m'] = 1,
    ['ft'] = 1.0/0.3048,
}
g_userdata = {}
g_usertemp = {}
g_uim = nil

function onCustomCommand(full_message, user_peer_id, is_admin, is_auth, cmd, ...)
    if cmd ~= g_cmd then
        return
    end

    local args = {}
    for _, s in ipairs({...}) do
        if s ~= '' then
            table.insert(args, s)
        end
    end

    if #args <= 0 or args[1] == 'help' then
        execHelp(user_peer_id, is_admin, is_auth, args)
    elseif args[1] == 'on' then
        execOn(user_peer_id, is_admin, is_auth, args)
    elseif args[1] == 'off' then
        execOff(user_peer_id, is_admin, is_auth, args)
    elseif args[1] == 'spdofs' then
        execSpdOfs(user_peer_id, is_admin, is_auth, args)
    elseif args[1] == 'altofs' then
        execAltOfs(user_peer_id, is_admin, is_auth, args)
    elseif args[1] == 'spdunit' then
        execSpdUnit(user_peer_id, is_admin, is_auth, args)
    elseif args[1] == 'altunit' then
        execAltUnit(user_peer_id, is_admin, is_auth, args)
    else
        server.announce(
            getAnnounceName(),
            string.format(
                (
                    'error: undefined subcommand "%s"\n' ..
                    'see "%s help" for list of subcommands'
                ),
                args[1],
                g_cmd
            ),
            user_peer_id
        )
    end
end

function execHelp(user_peer_id, is_admin, is_auth, args)
    server.announce(
        getAnnounceName(),
        (
            g_cmd .. ' on\n' ..
            g_cmd .. ' off\n' ..
            g_cmd .. ' spdofs HOFS VOFS\n' ..
            g_cmd .. ' altofs HOFS VOFS\n' ..
            g_cmd .. ' spdunit UNIT\n' ..
            g_cmd .. ' altunit UNIT\n' ..
            g_cmd .. ' help'
        ),
        user_peer_id
    )
end

function execOn(user_peer_id, is_admin, is_auth, args)
    if #args > 1 then
        server.announce(getAnnounceName(), 'error: extra arguments', user_peer_id)
        return
    end
    g_userdata[user_peer_id]['enabled'] = true
    server.announce(getAnnounceName(), 'widgets are now enabled', user_peer_id)
end

function execOff(user_peer_id, is_admin, is_auth, args)
    if #args > 1 then
        server.announce(getAnnounceName(), 'error: extra arguments', user_peer_id)
        return
    end
    g_userdata[user_peer_id]['enabled'] = false
    server.announce(getAnnounceName(), 'widgets are now disabled', user_peer_id)
end

function execSpdOfs(user_peer_id, is_admin, is_auth, args)
    return execSetOfs(user_peer_id, is_admin, is_auth, args, 'spdofs', 'spd_hofs', 'spd_vofs')
end

function execAltOfs(user_peer_id, is_admin, is_auth, args)
    return execSetOfs(user_peer_id, is_admin, is_auth, args, 'altofs', 'alt_hofs', 'alt_vofs')
end

function execSetOfs(user_peer_id, is_admin, is_auth, args, param_name, param_key_hofs, param_key_vofs)
    if #args == 1 then
        server.announce(
            getAnnounceName(),
            string.format(
                (
                    'current %s is (%f, %f)\n' ..
                    'use "%s %s HOFS VOFS" to configure'
                ),
                param_name,
                g_userdata[user_peer_id][param_key_hofs],
                g_userdata[user_peer_id][param_key_vofs],
                g_cmd,
                args[1]
            ),
            user_peer_id
        )
        return
    elseif #args ~= 3 then
        server.announce(getAnnounceName(), 'error: wrong number of arguments', user_peer_id)
        return
    end

    local hofs_txt = args[2]
    local vofs_txt = args[3]
    local hofs = tonumber(hofs_txt)
    local vofs = tonumber(vofs_txt)
    if not hofs then
        server.announce(
            getAnnounceName(),
            string.format('error: got invalid number "%s"', hofs_txt),
            user_peer_id
        )
        return
    elseif not vofs then
        server.announce(
            getAnnounceName(),
            string.format('error: got invalid number "%s"', vofs_txt),
            user_peer_id
        )
        return
    elseif hofs < -1 or 1 < hofs or vofs < -1 or 1 < vofs then
        server.announce(getAnnounceName(), 'error: offset must be within the range -1 to 1', user_peer_id)
        return
    end

    g_userdata[user_peer_id][param_key_hofs] = hofs
    g_userdata[user_peer_id][param_key_vofs] = vofs
    server.announce(
        getAnnounceName(),
        string.format('%s is now set to (%f, %f)', param_name, hofs, vofs),
        user_peer_id
    )
end

function execSpdUnit(user_peer_id, is_admin, is_auth, args)
    return execSetUnit(
        user_peer_id,
        is_admin,
        is_auth,
        args,
        'spdunit',
        'spd_unit',
        g_spd_unit_tbl,
        'available units are "km/h", "m/s", "kt"'
    )
end

function execAltUnit(user_peer_id, is_admin, is_auth, args)
    return execSetUnit(
        user_peer_id,
        is_admin,
        is_auth,
        args,
        'altunit',
        'alt_unit',
        g_alt_unit_tbl,
        'available units are "m", "ft"'
    )
end

function execSetUnit(user_peer_id, is_admin, is_auth, args, param_name, param_key, param_tbl, param_choices)
    if #args < 2 then
        server.announce(
            getAnnounceName(),
            string.format(
                (
                    'current %s is "%s"\n' ..
                    'use "%s %s UNIT" to configure\n' ..
                    '%s'
                ),
                param_name,
                g_userdata[user_peer_id][param_key],
                g_cmd,
                args[1],
                param_choices
            ),
            user_peer_id
        )
        return
    end
    if #args > 2 then
        server.announce(getAnnounceName(), 'error: too many arguments', user_peer_id)
        return
    end

    local unit = args[2]
    if param_tbl[unit] == nil then
        server.announce(
            getAnnounceName(),
            string.format('error: got undefined unit "%s"\n%s', unit, param_choices),
            user_peer_id
        )
        return
    end
    g_userdata[user_peer_id][param_key] = unit
    server.announce(
        getAnnounceName(),
        string.format('%s is now set to "%s"', param_name, unit),
        user_peer_id
    )
end

function onTick(game_ticks)
    local player_tbl = getPlayerTable()
    for _, player in pairs(player_tbl) do
        if g_userdata[player['id']] == nil then
            g_userdata[player['id']] = {
                ['enabled'] = true,
                ['spd_hofs'] = 0.8,
                ['spd_vofs'] = -0.9,
                ['spd_unit'] = 'km/h',
                ['alt_hofs'] = 0.9,
                ['alt_vofs'] = -0.8,
                ['alt_unit'] = 'm',
            }
        end
    end
    for peer_id, _ in pairs(g_userdata) do
        if player_tbl[peer_id] == nil then
            g_userdata[peer_id] = nil
        end
    end
    for _, player in pairs(player_tbl) do
        if g_usertemp[player['id']] == nil then
            g_usertemp[player['id']] = {}
        end
    end
    for peer_id, _ in pairs(g_usertemp) do
        if player_tbl[peer_id] == nil then
            g_usertemp[peer_id] = nil
        end
    end

    for peer_id, _ in pairs(g_userdata) do
        if not g_userdata[peer_id]['enabled'] then
            g_usertemp[peer_id] = {}
            goto continue
        end

        local vehicle_id, is_success = getPlayerVehicle(peer_id)
        if not is_success then
            vehicle_id = nil
        end
        if vehicle_id ~= g_usertemp[peer_id]['vehicle_id'] then
            g_usertemp[peer_id] = {
                ['vehicle_id'] = vehicle_id,
            }
        end

        if vehicle_id ~= nil then
            local vehicle_pos, is_success = server.getVehiclePos(vehicle_id)
            if not is_success then
                g_usertemp[peer_id] = {}
                goto continue
            end

            if g_usertemp[peer_id]['vehicle_pos'] ~= nil then
                g_usertemp[peer_id]['spd'] = matrix.distance(vehicle_pos, g_usertemp[peer_id]['vehicle_pos'])
            end
            g_usertemp[peer_id]['alt'] = table.pack(matrix.position(vehicle_pos))[2]
            g_usertemp[peer_id]['vehicle_pos'] = vehicle_pos
        else
            local player_log = g_usertemp[peer_id]['player_log'] or {}
            local player_log_idx = g_usertemp[peer_id]['player_log_idx'] or 1
            local player_log_len = peer_id == 0 and 2 or 61

            local player_object_id, is_success = server.getPlayerCharacterID(peer_id)
            if not is_success then
                g_usertemp[peer_id] = {}
                goto continue
            end
            local player_new_pos, is_success = server.getObjectPos(player_object_id)
            if not is_success then
                g_usertemp[peer_id] = {}
                goto continue
            end

            player_log[player_log_idx] = player_new_pos
            player_log_idx = player_log_idx%player_log_len + 1

            if #player_log > 1 then
                local player_old_pos = player_log[player_log_idx] or player_log[1]
                g_usertemp[peer_id]['spd'] = matrix.distance(player_old_pos, player_new_pos)/(#player_log - 1)
            end
            g_usertemp[peer_id]['alt'] = table.pack(matrix.position(player_new_pos))[2]
            g_usertemp[peer_id]['player_log'] = player_log
            g_usertemp[peer_id]['player_log_idx'] = player_log_idx
        end
        ::continue::
    end

    for peer_id, _ in pairs(g_userdata) do
        local userdata = g_userdata[peer_id]
        local usertemp = g_usertemp[peer_id]
        if not userdata['enabled'] then
            goto continue
        end

        local spdtxt = 'SPD\n---'
        if usertemp['spd'] ~= nil then
            spdtxt = string.format(
                'SPD\n%.2f%s',
                usertemp['spd']*g_spd_unit_tbl[userdata['spd_unit']],
                userdata['spd_unit']
            )
        end

        local alttxt = 'ALT\n---'
        if usertemp['alt'] ~= nil then
            alttxt = string.format(
                'ALT\n%.2f%s',
                usertemp['alt']*g_alt_unit_tbl[userdata['alt_unit']],
                userdata['alt_unit']
            )
        end

        g_uim.setPopupScreen(peer_id, g_savedata['spd_ui_id'], getAnnounceName(), true, spdtxt, userdata['spd_hofs'], userdata['spd_vofs'])
        g_uim.setPopupScreen(peer_id, g_savedata['alt_ui_id'], getAnnounceName(), true, alttxt, userdata['alt_hofs'], userdata['alt_vofs'])
        ::continue::
    end
    g_uim.flushPopup()

    if g_userdata[0] ~= nil then
        g_savedata['hostdata'] = deepcopy(g_userdata[0])
    end
end

function onCreate(is_world_create)
    local version = 1
    if g_savedata['version'] ~= version then
        g_savedata = {
            ['version'] = version,
            ['spd_ui_id'] = server.getMapID(),
            ['alt_ui_id'] = server.getMapID(),
            ['hostdata'] = nil,
        }
    end
    if g_savedata['hostdata'] ~= nil then
        g_userdata[0] = deepcopy(g_savedata['hostdata'])
    end

    g_uim = buildUIManager()
    server.removePopup(-1, g_savedata['spd_ui_id'])
    server.removePopup(-1, g_savedata['alt_ui_id'])
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
    g_uim.onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
end

function buildUIManager()
    local uim = {
        ['_popup_old'] = {},
        ['_popup_new'] = {},
    }

    function uim.setPopupScreen(peer_id, ui_id, name, is_show, text, horizontal_offset, vertical_offset)
        for _, peer_id in pairs(uim._getPeerIDList(peer_id)) do
            local key = string.format('%d,%d', peer_id, ui_id)
            uim['_popup_new'][key] = {
                ['peer_id'] = peer_id,
                ['ui_id'] = ui_id,
                ['name'] = name,
                ['is_show'] = is_show,
                ['text'] = text,
                ['horizontal_offset'] = horizontal_offset,
                ['vertical_offset'] = vertical_offset,
            }
        end
    end

    function uim.flushPopup()
        for key, popup in pairs(uim['_popup_old']) do
            if uim['_popup_new'][key] == nil then
                server.removePopup(popup['peer_id'], popup['ui_id'])
            end
        end

        for key, popup_new in pairs(uim['_popup_new']) do
            local popup_old = uim['_popup_old'][key]
            if popup_old == nil or
                popup_new['name'] ~= popup_old['name'] or
                popup_new['is_show'] ~= popup_old['is_show'] or
                popup_new['text'] ~= popup_old['text'] or
                popup_new['horizontal_offset'] ~= popup_old['horizontal_offset'] or
                popup_new['vertical_offset'] ~= popup_old['vertical_offset'] then
                server.setPopupScreen(
                    popup_new['peer_id'],
                    popup_new['ui_id'],
                    popup_new['name'],
                    popup_new['is_show'],
                    popup_new['text'],
                    popup_new['horizontal_offset'],
                    popup_new['vertical_offset']
                )
            end
        end

        uim['_popup_old'] = uim['_popup_new']
        uim['_popup_new'] = {}
    end

    function uim.onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
        for key, popup in pairs(uim['_popup_old']) do
            if popup['peer_id'] == peer_id then
                server.removePopup(popup['peer_id'], popup['ui_id'])
                uim['_popup_old'][key] = nil
            end
        end
    end

    function uim._getPeerIDList(peer_id)
        local peer_id_list = {}
        if peer_id < 0 then
            for _, player in pairs(server.getPlayers()) do
                table.insert(peer_id_list, player['id'])
            end
        else
            table.insert(peer_id_list, peer_id)
        end
        return peer_id_list
    end

    return uim
end

function getAddonName()
    local addon_index = server.getAddonIndex()
    local addon_data = server.getAddonData(addon_index)
    return addon_data['name']
end

function getAnnounceName()
    return string.format('[%s]', getAddonName())
end

function getPlayerTable()
    local player_tbl = {}
    for _, player in pairs(server.getPlayers()) do
        player_tbl[player['id']] = player
    end
    return player_tbl
end

function getPlayerVehicle(peer_id)
    local object_id, is_success = server.getPlayerCharacterID(peer_id)
    if not is_success then
        return 0, false
    end
    return server.getCharacterVehicle(object_id)
end

function matrixEquals(matrix1, matrix2)
    local x1, y1, z1 = matrix.position(matrix1)
    local x2, y2, z2 = matrix.position(matrix2)
    return x1 == x2 and y1 == y2 and z1 == z2
end

function deepcopy(v)
    if type(v) ~= 'table' then
        return v
    end

    local tbl = {}
    for key, val in pairs(v) do
        key = deepcopy(key)
        val = deepcopy(val)
        tbl[key] = val
    end
    return tbl
end
