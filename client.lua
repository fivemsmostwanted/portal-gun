local portalA = nil
local portalB = nil
local isSettingPortalA = true
local lastTeleported = nil

function getAimingPoint()
    local playerPed = PlayerPedId()
    local weaponEntity = GetCurrentPedWeaponEntityIndex(playerPed)
    local weaponCoords = GetOffsetFromEntityInWorldCoords(weaponEntity, 0.0, 0.0, 0.0)
    local camRot = GetGameplayCamRot(2)
    local forwardVector = vector3(-math.sin(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))), math.cos(math.rad(camRot.z)) * math.abs(math.cos(math.rad(camRot.x))), math.sin(math.rad(camRot.x)))
    local endCoords = weaponCoords + (forwardVector * 1000)

    local rayHandle = StartShapeTestRay(weaponCoords.x, weaponCoords.y, weaponCoords.z, endCoords.x, endCoords.y, endCoords.z, 4294967295, playerPed, 0)
    local _, hit, hitCoords, _, _ = GetShapeTestResult(rayHandle)

    return hit, hitCoords
end

function startPortalTimer(portal)
    Citizen.CreateThread(function()
        Citizen.Wait(10000)
        if portal == 'A' then
            portalA = nil
            TriggerEvent('chat:addMessage', { args = { 'Portal A has expired!' } })
        elseif portal == 'B' then
            portalB = nil
            TriggerEvent('chat:addMessage', { args = { 'Portal B has expired!' } })
        end
    end)
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)

        local playerPed = PlayerPedId()
        local hasWeapon, currentWeapon = GetCurrentPedWeapon(playerPed, true)

        if IsPlayerFreeAiming(PlayerId()) then
            local hit, targetCoords = getAimingPoint()

            if hit then
                DrawMarker(28, targetCoords.x, targetCoords.y, targetCoords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.1, 1.1, 1.0, 255, 255, 255, 100, false, true, 2, nil, nil, false)
                local weaponCoords = GetOffsetFromEntityInWorldCoords(GetCurrentPedWeaponEntityIndex(playerPed), 0.0, 0.0, 0.0)
                DrawLine(weaponCoords, targetCoords, 255, 255, 255, 255)
            end
        end

        if hasWeapon and currentWeapon == GetHashKey('WEAPON_COMBATPISTOL') then
            if IsPedShooting(playerPed) then
                local hit, coords = GetPedLastWeaponImpactCoord(playerPed)
                if hit then
                    if isSettingPortalA then
                        portalA = coords
                        TriggerEvent('chat:addMessage', { args = { 'Portal A set!' } })
                        startPortalTimer('A')
                        isSettingPortalA = false
                    else
                        portalB = coords
                        TriggerEvent('chat:addMessage', { args = { 'Portal B set!' } })
                        startPortalTimer('B')
                        isSettingPortalA = true
                    end
                end
            end
        end

        if portalA ~= nil then
            DrawMarker(28, portalA.x, portalA.y, portalA.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 0, 0, 255, 100, false, true, 2, nil, nil, false)
            if Vdist2(GetEntityCoords(playerPed), portalA) < 4.0 then
                if lastTeleported ~= 'A' then
                    if portalB ~= nil then
                        SetEntityCoords(playerPed, portalB.x, portalB.y, portalB.z)
                        TriggerEvent('chat:addMessage', { args = { 'Teleported to Portal B!' } })
                        lastTeleported = 'B'
                    end
                end
            elseif lastTeleported == 'A' then
                lastTeleported = nil
            end
        end

        if portalB ~= nil then
            DrawMarker(28, portalB.x, portalB.y, portalB.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 255, 0, 0, 100, false, true, 2, nil, nil, false)
            if Vdist2(GetEntityCoords(playerPed), portalB) < 4.0 then
                if lastTeleported ~= 'B' then
                    if portalA ~= nil then
                        SetEntityCoords(playerPed, portalA.x, portalA.y, portalA.z)
                        TriggerEvent('chat:addMessage', { args = { 'Teleported to Portal A!' } })
                        lastTeleported = 'A'
                    end
                end
            elseif lastTeleported == 'B' then
                lastTeleported = nil
            end
        end
    end
end)
