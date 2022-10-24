ESX = nil TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

isWork = false
isInWork = false

blip = {}
blip.pos = Work.blip[1].pos
blip.name = Work.blip[1].name
blip.id = Work.blip[1].id
blip.color = Work.blip[1].color
blip.scale = Work.blip[1].scale

blipWork = {}
blipWork.pos = Work.blip[2].pos
blipWork.name = Work.blip[2].name
blipWork.id = Work.blip[2].id
blipWork.color = Work.blip[2].color
blipWork.scale = Work.blip[2].scale

npc = {}
npc.pos = Work.npc.position
npc.heading = Work.npc.heading
npc.model = Work.npc.model
npc.scenario = Work.npc.scenario

CreateBlip(blip.pos, blip.id, blip.color, blip.scale, blip.name)

Citizen.CreateThread(function()

    local interval = 0

    while true do

        local model = GetHashKey(npc.model)
        RequestModel(model)

        local dst = GetDistanceBetweenCoords(npc.pos, GetEntityCoords(PlayerPedId()), true)

        if not DoesEntityExist(ped) then

            ped = CreatePed(4, model, npc.pos, npc.heading, false, false)
            FreezeEntityPosition(ped, true)
            SetEntityInvincible(ped, true)
            SetBlockingOfNonTemporaryEvents(ped, true)

            TaskStartScenarioInPlace(ped, npc.scenario, 0, true)
            interval = 0

        else

            interval = 1000

        end

        if (dst <= 1.5) then

            interval = 0

            ESX.ShowHelpNotification(language.openMenu)

            if (IsControlJustPressed(0, 51)) then

                PlayPedAmbientSpeechNative(ped, "GENERIC_HI", "SPEECH_PARAMS_FORCE")

                openMenuChantier()

            end
        end

        Citizen.Wait(interval)
    end


end)

openMenuChantier = function()

    local main = RageUI.CreateMenu(language.menuTitle, language.menuDescription);

    RageUI.Visible(main, not RageUI.Visible(main))

    while main do

        Citizen.Wait(0)

        RageUI.IsVisible(main, function()

            RageUILine()

            if isWork then

                RageUI.Button(language.button.stopWork, nil, {}, true, {
                    onSelected = function()
                        ESX.ShowAdvancedNotification(language.notification.sender, language.notification.stopWork.subject, language.notification.stopWork.message, language.notification.texture, 3)

                        StopWork()
                    end
                })

            else

                RageUI.Button(language.button.startWork, nil, {}, true, {
                    onSelected = function()

                        TriggerEvent('skinchanger:getSkin', function(skin)
                            TriggerEvent('skinchanger:loadClothes', skin, Work.clothes)
                        end)

                        ESX.ShowAdvancedNotification(language.notification.sender, language.notification.startWork.subject, language.notification.startWork.message, language.notification.texture, 3)

                        isWork = true

                        pos = Work.work[math.random(1, #Work.work)]
                        markerPos = vector3(pos.x, pos.y, pos.z)

                        workBlip = CreateBlip(markerPos, blipWork.id, blipWork.color, blipWork.scale, blipWork.name)

                        while true do

                            local dst = math.floor(GetDistanceBetweenCoords(markerPos, GetEntityCoords(PlayerPedId())))

                            if dst > Work.maxDistance and isWork then

                                ESX.ShowAdvancedNotification(language.notification.sender, language.notification.tooFar.subject, language.notification.tooFar.message, language.notification.texture, 3)

                                StopWork()

                            end

                            if isWork and not isInWork then
                                DrawMarker(2, markerPos, 0, 0, 0, 0, 0, 0, .5, .5, .5, 255, 255, 255, 200, true, false)
                                if dst > .0 and Work.text then
                                    Draw3DText(pos.x, pos.y, pos.z, dst/40, 'Travail (~r~'..dst..'m~s~)')
                                end
                            end

                            if (dst <= 1.5) and not isInWork then

                                ESX.ShowHelpNotification(language.pushtowork)

                                if (IsControlJustPressed (0, 51)) then

                                    for _, data in pairs(Work.work) do

                                        position = vector3(data.x, data.y, data.z)

                                        if position == markerPos then
                                            SetEntityCoords(PlayerPedId(), vector3(data.x, data.y, data.z-1.0))
                                            SetEntityHeading(PlayerPedId(), data.heading)
                                        end

                                    end

                                    isInWork = true

                                    FreezeEntityPosition(PlayerPedId(), true)

                                    RequestAnimDict(Work.animDict)
                                    while (not HasAnimDictLoaded(Work.animDict)) do Citizen.Wait(0) end
                                    TaskPlayAnim(PlayerPedId(),Work.animDict,Work.animName,1.0,-1.0, -1, 1, 1, true, true, true)


                                    local duration = math.random(Work.durationMin, Work.durationMax)

                                    exports.rprogress:Custom({
                                        Duration = duration,
                                        x = Work.progressBarX,
                                        y = Work.progressBarY,
                                        Label = Work.progressBarLabel
                                    })

                                    SetTimeout(duration, function()

                                        TriggerServerEvent('chantier:finish')

                                        ClearPedTasks(PlayerPedId())

                                        isInWork = false

                                        FreezeEntityPosition(PlayerPedId(), false)

                                        pos = Work.work[math.random(1, #Work.work)]
                                        markerPos = vector3(pos.x, pos.y, pos.z)

                                        RemoveBlip(workBlip)

                                        workBlip = CreateBlip(markerPos, blipWork.id, blipWork.color, blipWork.scale, blipWork.name)
                                    end)

                                end
                            end

                            Citizen.Wait(0)
                        end

                    end
                })

            end

        end)

        if not RageUI.Visible(main) then
            main = RMenu:DeleteType('main', true)
        end

    end

end

CreateBlip = function(coords)

    local blip = AddBlipForCoord(coords)

    SetBlipSprite(blip, blipWork.id)
    SetBlipColour(blip, blipWork.color)
    SetBlipScale(blip, blipWork.scale)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(blipWork.name)
    EndTextCommandSetBlipName(blip)

    return blip

end

StopWork = function()

    isWork = false

    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
    end)

    RemoveBlip(workBlip)

end