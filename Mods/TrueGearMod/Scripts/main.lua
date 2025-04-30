local pistol = { 
	"BP_Beretta_C",
	"BP_Glock_18_C",
	"BP_Gsh18_C",
	"BP_PM_C",
	"BP_PM_mod_C"
}

local rifle = { 
	"BP_AKSu74N_C",
	"BP_AK74N_C",
	"BP_AK74M_C",
	"BP_VSS_C",
	"BP_AS_VAL_C",
	"BP_Groza_C",
	"BP_Bizon_C",
	"BP_Kedr_C"
}

local shotgun = { 
	"BP_Saiga_C",
	"BP_Iz27_M_C",
	"BP_Iz27_C",
	"BP_Iz27_SawOff_C",
	"BP_SKS_M_C",
	"BP_SKS_C"
}

local hookIds = {}
local resetHook = true
local playerHealth = 35
local playerStamina = 100
local playerHunger = 100000
local leftHandItem = nil
local rightHandItem = nil
local vestSide = "Right"
local isPause = false
local canReturnMainMenu = false
local isFire = false
local mouthTime = 0
local isTwoHand = false

function SendMessage(context)
	if isDeath == true then
		return
	end
	if context then
		print(context .. "\n")
		return
	end
	print("nil\n")
end

function OutputMessage(context)
	if context then		
		local file = io.open("TrueGear.log", "a")			
		io.output(file)
		io.write(os.date("%Y-%m-%d %H:%M:%S") .. "	[TrueGear]:{".. context .."}\n")
		io.close(file)
		return
	end
end

function split(str, sep)
	assert(type(str) == 'string' and type(sep) == 'string', 'The arguments must be <string>')
	if sep == '' then return {str} end
	
	local res, from = {}, 1
	repeat
	  local pos = str:find(sep, from)
	  res[#res + 1] = str:sub(from, pos and pos - 1)
	  from = pos and pos + #sep
	until not from
	return res
end

local function inValue (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end

function PlayAngle(event,tmpAngle,tmpVertical)

	local rootObject = truegear.find_effect(event);

	local angle = (tmpAngle - 22.5 > 0) and (tmpAngle - 22.5) or (360 - tmpAngle)
	
    local horCount = math.floor(angle / 45) + 1
	local verCount = (tmpVertical > 0.1) and -4 or (tmpVertical < 0 and 8 or 0)

	print(rootObject)

	for kk, track in pairs(rootObject.tracks) do
        if tostring(track.action_type) == "Shake" then
            for i = 1, #track.index do
                if verCount ~= 0 then
                    track.index[i] = track.index[i] + verCount
                end
                if horCount < 8 then
                    if track.index[i] < 50 then
                        local remainder = track.index[i] % 4
                        if horCount <= remainder then
                            track.index[i] = track.index[i] - horCount
                        elseif horCount <= (remainder + 4) then
                            local num1 = horCount - remainder
                            track.index[i] = track.index[i] - remainder + 99 + num1
                        else
                            track.index[i] = track.index[i] + 2
                        end
                    else
                        local remainder = 3 - (track.index[i] % 4)
                        if horCount <= remainder then
                            track.index[i] = track.index[i] + horCount
                        elseif horCount <= (remainder + 4) then
                            local num1 = horCount - remainder
                            track.index[i] = track.index[i] + remainder - 99 - num1
                        else
                            track.index[i] = track.index[i] - 2
                        end
                    end
                end
            end
            if track.index then
                local filteredIndex = {}
                for _, v in pairs(track.index) do
                    if not (v < 0 or (v > 19 and v < 100) or v > 119) then
                        table.insert(filteredIndex, v)
                    end
                end
                track.index = filteredIndex
            end
        elseif tostring(track.action_type) ==  "Electrical" then
            for i = 1, #track.index do
                if horCount <= 4 then
                    track.index[i] = 0
                else
                    track.index[i] = 100
                end
            end
            if horCount == 1 or horCount == 8 or horCount == 4 or horCount == 5 then
                track.index = {0, 100}
            end
        end
    end

	truegear.play_effect_by_content(rootObject)
end


function RegisterHooks()


	for k,v in pairs(hookIds) do
		UnregisterHook(k, v.id1, v.id2)
	end
		
	hookIds = {}

	local funcName = "/Script/IntoTheRadius2.PlayerStatsComponent:OnAnyDamageTaken"
	local hook1, hook2 = RegisterHook(funcName, OnAnyDamageTaken)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/IntoTheRadius2.RadiusFirearmComponent:StartFire"
	local hook1, hook2 = RegisterHook(funcName, StartFire)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }
	
	local funcName = "/Game/ITR2/BPs/HolstersAndHolders/BPC_ItemHolster.BPC_ItemHolster_C:OnItemHolsterAttachChanged_Event"
	local hook1, hook2 = RegisterHook(funcName, OnItemHolsterAttachChanged_Event)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Player/BPC_PlayerBracelet.BPC_PlayerBracelet_C:ChangeHealth"
	local hook1, hook2 = RegisterHook(funcName, HealthChange)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Player/BP_RadiusPlayerCharacter_Gameplay.BP_RadiusPlayerCharacter_Gameplay_C:OnIngameMenuOpened"
	local hook1, hook2 = RegisterHook(funcName, OnIngameMenuOpened)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Player/BP_RadiusPlayerCharacter_Gameplay.BP_RadiusPlayerCharacter_Gameplay_C:OnIngameMenuClosed"
	local hook1, hook2 = RegisterHook(funcName, OnIngameMenuClosed)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Items/Equipment/Backpacks/BPA_Backpack_Base.BPA_Backpack_Base_C:Change Backpack State"
	local hook1, hook2 = RegisterHook(funcName, FChangeBackpackState)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/UI/MainMenu/WBP_MainMenu_Mih3D.WBP_MainMenu_Mih3D_C:ReturnToMainMenu"
	local hook1, hook2 = RegisterHook(funcName, ReturnToMainMenu)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Player/BPC_PlayerBracelet.BPC_PlayerBracelet_C:OnStaminaChange"
	local hook1, hook2 = RegisterHook(funcName, OnStaminaChange)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/IntoTheRadius2.RadiusFirearmComponent:DeliverAmmoFromMagToChamber"
	local hook1, hook2 = RegisterHook(funcName, DeliverAmmoFromMagToChamber)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Player/BPC_PlayerMouth.BPC_PlayerMouth_C:Server_DestroyActorDynamicData"
	local hook1, hook2 = RegisterHook(funcName, Server_DestroyActorDynamicData)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/Player/BPC_PlayerMouth.BPC_PlayerMouth_C:OnComponentBeginOverlap_Event"
	local hook1, hook2 = RegisterHook(funcName, OnComponentBeginOverlap_Event)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }


	local funcName = "/Script/IntoTheRadius2.RadiusPhysicalHand:OnDropped"
	local hook1, hook2 = RegisterHook(funcName, OnDropped)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/IntoTheRadius2.RadiusPhysicalHand:OnGripped"
	local hook1, hook2 = RegisterHook(funcName, OnGripped)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/IntoTheRadius2.RadiusPhysicalHand:OnGrippedSecondary"
	local hook1, hook2 = RegisterHook(funcName, OnGrippedSecondary)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Script/IntoTheRadius2.RadiusPhysicalHand:OnDroppedSecondary"
	local hook1, hook2 = RegisterHook(funcName, OnDroppedSecondary)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }


	local funcName = "/Game/ITR2/BPs/LevelObjects/BP_Bed.BP_Bed_C:DoSleep"
	local hook1, hook2 = RegisterHook(funcName, DoSleep)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	
	local funcName = "/Game/ITR2/BPs/HolstersAndHolders/BP_HolderVolume.BP_HolderVolume_C:DoAttachItem"
	local hook1, hook2 = RegisterHook(funcName, DoAttachItem)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

	local funcName = "/Game/ITR2/BPs/HolstersAndHolders/BP_HolderVolume.BP_HolderVolume_C:OnGrippedHolderedItem"
	local hook1, hook2 = RegisterHook(funcName, OnGrippedHolderedItem)
	hookIds[funcName] = { id1 = hook1; id2 = hook2 }

end

-- *******************************************************************


function DoAttachItem(self)
	SendMessage("--------------------------------")
	SendMessage("DoAttachItem")
	if vestSide == "Left" then
		SendMessage("RightHipSlotInputItem")
		OutputMessage("RightHipSlotInputItem")
	elseif vestSide == "Right" then
		SendMessage("LeftHipSlotInputItem")
		OutputMessage("LeftHipSlotInputItem")
	end
	SendMessage(self:get():GetFullName())
end

function OnGrippedHolderedItem(self)
	SendMessage("--------------------------------")
	SendMessage("OnGrippedHolderedItem")
	if vestSide == "Left" then
		SendMessage("RightHipSlotOutputItem")
		OutputMessage("RightHipSlotOutputItem")
	elseif vestSide == "Right" then
		SendMessage("LeftHipSlotOutputItem")
		OutputMessage("LeftHipSlotOutputItem")
	end
	SendMessage(self:get():GetFullName())
end



function OnGripped(self,GripInfo)
	if not self:get().OwingChar.Owner.bIsLocalPlayerController then
		return
	end
	SendMessage("--------------------------------")
	if self:get().bIsRightHand then
		SendMessage("RightHandPickupItem")
		rightHandItem = GripInfo:get().GrippedObject.RootComponent:GetFullName()
		OutputMessage("RightHandPickupItem")
	else
		SendMessage("LeftHandPickupItem")
		leftHandItem = GripInfo:get().GrippedObject.RootComponent:GetFullName()
		OutputMessage("LeftHandPickupItem")
	end
	
	SendMessage(self:get():GetFullName())
	SendMessage(GripInfo:get().GrippedObject:GetFullName())
	SendMessage(GripInfo:get().GrippedObject.RootComponent:GetFullName())
	SendMessage(tostring(self:get().bIsRightHand))
	SendMessage(tostring(self:get().OwingChar.Owner.bIsLocalPlayerController))
end

function OnDropped(self)
	if not self:get().OwingChar.Owner.bIsLocalPlayerController then
		return
	end
	SendMessage("--------------------------------")
	if self:get().bIsRightHand then
		SendMessage("RightHandDropItem")
		rightHandItem = nil
	else
		SendMessage("LeftHandDropItem")
		leftHandItem = nil
	end
	SendMessage(self:get():GetFullName())
	SendMessage(tostring(self:get().bIsRightHand))
end

function OnGrippedSecondary(self)
	if not self:get().OwingChar.Owner.bIsLocalPlayerController then
		return
	end
	isTwoHand = true
	SendMessage("--------------------------------")
	if self:get().bIsRightHand then
		SendMessage("RightHandPickupItem")
		OutputMessage("RightHandPickupItem")
	else
		SendMessage("LeftHandPickupItem")
		OutputMessage("LeftHandPickupItem")
	end
	SendMessage(self:get():GetFullName())
	SendMessage(tostring(self:get().bIsRightHand))
end

function OnDroppedSecondary(self)
	if not self:get().OwingChar.Owner.bIsLocalPlayerController then
		return
	end
	isTwoHand = false
	SendMessage("--------------------------------")
	if self:get().bIsRightHand then
		SendMessage("RightHandDropItem")
	else
		SendMessage("LeftHandDropItem")
	end
	SendMessage(self:get():GetFullName())
	SendMessage(tostring(self:get().bIsRightHand))
end



function DoSleep(self)
	SendMessage("--------------------------------")
	SendMessage("DoSleep")
	OutputMessage("Sleep")
	SendMessage(self:get():GetFullName())
end

function OnComponentBeginOverlap_Event(self)
	if self:get():GetPropertyValue("LastHolstered"):IsValid() then
		if os.clock() - mouthTime < 0.13 then
			return
		end
		mouthTime = os.clock()
		SendMessage("--------------------------------")
		SendMessage("Mouth")
		OutputMessage("Mouth")
		SendMessage(self:get():GetFullName())
		SendMessage(tostring(self:get():GetPropertyValue("LastHolstered"):IsValid()))
	end
end

function Server_DestroyActorDynamicData(self)
	SendMessage("--------------------------------")
	SendMessage("Deglutition")
	OutputMessage("Deglutition")
	SendMessage(self:get():GetFullName())
end



-- function Smoking(self)
-- 	SendMessage("--------------------------------")
-- 	SendMessage("Smoking")
-- 	SendMessage(self:get():GetFullName())
-- end

-- function Exhale(self)
-- 	SendMessage("--------------------------------")
-- 	SendMessage("Exhale")
-- 	SendMessage(self:get():GetFullName())
-- end


function DeliverAmmoFromMagToChamber(self)

	-- local leftWeaponAddress = nil
	-- local rightWeaponAddress = nil
	-- local shootWeaponAddress = self:get():GetPropertyValue("AttachParent"):GetAddress()

	-- if leftHandItem ~= nil then 		
	-- 	if leftHandItem:GetPropertyValue("WeaponMesh"):IsValid() then
	-- 		leftWeaponAddress = leftHandItem:GetPropertyValue("WeaponMesh"):GetAddress()
	-- 	end			
	-- end
	-- if rightHandItem ~= nil then 
	-- 	if rightHandItem:GetPropertyValue("WeaponMesh"):IsValid() then
	-- 		rightWeaponAddress = rightHandItem:GetPropertyValue("WeaponMesh"):GetAddress()
	-- 	end	
	-- end

	if isFire then
		isFire = false
		return
	end

	if leftHandItem ~= nil and leftHandItem == self:get().AttachParent:GetFullName() then
		SendMessage("--------------------------------")
		SendMessage("LeftHandChamber")	
		OutputMessage("LeftHandChamber")
	elseif rightHandItem ~= nil and rightHandItem == self:get().AttachParent:GetFullName() then
		SendMessage("--------------------------------")
		SendMessage("RightHandChamber")	
		OutputMessage("RightHandChamber")
	end
	-- SendMessage("DeliverAmmoFromMagToChamber")	
end









function Multicast_OnSleep(self)
	if self:get():GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	SendMessage("--------------------------------")
	SendMessage("Sleep")
	OutputMessage("Sleep")
	SendMessage(self:get():GetFullName())
end

function OnStaminaChange(self,Actor,CurrentStamina,Delta)
	if Actor:get():GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	playerStamina = CurrentStamina:get()
	playerHunger = self:get():GetPropertyValue("PlayerStats"):GetPropertyValue("CurrentHunger")
	-- SendMessage("--------------------------------")
	-- SendMessage("OnStaminaChange")
	-- SendMessage(self:get():GetFullName())
	-- SendMessage(Actor:get():GetFullName())
	-- SendMessage(tostring(CurrentStamina:get()))
	-- SendMessage(tostring(Delta:get()))
end

function OnGripRelease(self,Hand,bIsTriggerRelease)
	if self:get():GetController(Hand):GetPropertyValue("AttachChar"):GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	-- SendMessage("--------------------------------")
	-- SendMessage("OnGripRelease")
	-- SendMessage(self:get():GetFullName())
	-- SendMessage("Hand :" .. tostring(Hand:get()))
	-- SendMessage("bIsTriggerRelease :" .. tostring(bIsTriggerRelease:get()))
	if Hand:get() == 0 then
		leftHandItem = nil
	elseif Hand:get() == 1 then
		rightHandItem = nil
	end
end

function TryToGrabObject(self,ObjectToTryToGrab,WorldTransform,Hand,IsSlotGrip,GripSecondaryTag,GripBoneName,SlotName,IsSecondaryGrip,Gripped)
	if self:get():GetController(Hand):GetPropertyValue("AttachChar"):GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	if Hand:get() == 0 then
		SendMessage("--------------------------------")
		SendMessage("LeftHandPickupItem")
		OutputMessage("LeftHandPickupItem")
		leftHandItem = ObjectToTryToGrab:get()
	elseif Hand:get() == 1 then
		SendMessage("--------------------------------")
		SendMessage("RightHandPickupItem")
		OutputMessage("RightHandPickupItem")
		rightHandItem = ObjectToTryToGrab:get()
	end
	-- SendMessage("TryToGrabObject")
	-- SendMessage(self:get():GetFullName())
	SendMessage(ObjectToTryToGrab:get():GetFullName())
	-- SendMessage("Hand :" .. tostring(Hand:get()))
	-- SendMessage("IsSlotGrip :" .. tostring(IsSlotGrip:get()))
	-- SendMessage("Gripped :" .. tostring(Gripped:get()))
end

function ReturnToMainMenu(self)
	if canReturnMainMenu == false then
		return
	end
	canReturnMainMenu = false
	-- SendMessage("--------------------------------")
	-- SendMessage("ReturnToMainMenu")
	-- SendMessage(self:get():GetFullName())
	playerHealth = 35
	playerStamina = 100
	leftHandItem = nil
	rightHandItem = nil
end




function FChangeBackpackState(self,Open)
	if self:get():GetPropertyValue("Owner"):GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	if Open:get() then
		SendMessage("--------------------------------")
		SendMessage("LeftBackSlotOutputItem")
		OutputMessage("LeftBackSlotOutputItem")
	else
		SendMessage("--------------------------------")
		SendMessage("LeftBackSlotInputItem")
		OutputMessage("LeftBackSlotInputItem")
	end
	-- SendMessage(self:get():GetFullName())
	-- SendMessage(tostring(Open:get()))
end


function OnIngameMenuClosed(self)
	if self:get():GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	-- SendMessage("--------------------------------")
	-- SendMessage("OnIngameMenuClosed")
	-- SendMessage(self:get():GetFullName())
	isPause = false
	canReturnMainMenu = true
	ExecuteWithDelay(100, function()
		-- SendMessage("--------------------------------")
		-- SendMessage("ClearCanReturnMainMenu")
		canReturnMainMenu = false
	end)
end

function OnIngameMenuOpened(self)
	if self:get():GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	-- SendMessage("--------------------------------")
	-- SendMessage("OnIngameMenuOpened")
	-- SendMessage(self:get():GetFullName())
	isPause = true
end

local isPlayerDeath = false

function HealthChange(self,PlayerActor,CurrentHealth,ChangeDelta)
	if PlayerActor:get():GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	if CurrentHealth:get() == 0 then
		isPlayerDeath = true
		SendMessage("--------------------------------")
		SendMessage("PlayerDeath")
		OutputMessage("PlayerDeath")
		playerHealth = 35
		playerStamina = 100
		leftHandItem = nil
		rightHandItem = nil
		return
	end
	if playerHealth < CurrentHealth:get() then
		isPlayerDeath = false
		SendMessage("--------------------------------")
		SendMessage("Healing")
		OutputMessage("Healing")
	end
	playerHealth = CurrentHealth:get()


	-- SendMessage(self:get():GetFullName())
	-- SendMessage(PlayerActor:get():GetFullName())
	-- SendMessage(tostring(CurrentHealth:get()))
end



function VestSideCheck(vestName)
	local vestNames = split(vestName,"/")
	if string.find(vestName,"_L_") then
		vestSide = "Left"
	else
		vestSide = "Right"
	end
end

function OnItemHolsterAttachChanged_Event(self,HolsterComponent,RadiusItem,bHasAttached)
	if self:get():GetPropertyValue("HolsterCacheForReps"):GetPropertyValue("Owner"):GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end

	local slotName = HolsterComponent:get():GetPropertyValue("HolsterID")["TagName"]:ToString()
	-- SendMessage("--------------------------------")
	if bHasAttached:get() then
		if slotName == "Holster.Player.Vest" then			
			SendMessage("PutOnChestRig")
			VestSideCheck(RadiusItem:get():GetFullName())
			OutputMessage("PutOnChestRig")
		elseif slotName == "Holster.Player.Tablet" then
			SendMessage("LeftBackHipSlotInputItem")
			OutputMessage("LeftBackHipSlotInputItem")
		elseif slotName == "Holster.Player.LeftForearm" then
			SendMessage("LeftArmSlotInputItem")
			OutputMessage("LeftArmSlotInputItem")
		elseif slotName == "Holster.Player.RightForearm" then
			SendMessage("RightArmSlotInputItem")
			OutputMessage("RightArmSlotInputItem")
		elseif string.find(slotName,"Holster.Container.Magazine.Slot") then
			SendMessage("ChestSlotInputItem")
			OutputMessage("ChestSlotInputItem")
		elseif slotName == "Holster.Container.Item.Slot1" then
			SendMessage("LeftChestSlotInputItem")
			OutputMessage("LeftChestSlotInputItem")
		elseif slotName == "Holster.Container.Item.Slot0" then
			if string.find(HolsterComponent:get().AttachParent.AttachParent:GetFullName(),"Vertical7") then
				SendMessage("LeftChestSlotInputItem")
			else
				SendMessage("RightChestSlotInputItem")
			end			
			OutputMessage("RightChestSlotInputItem")
		elseif slotName == "Holster.Container.Weapon.Slot0" then
			SendMessage("RightBackSlotInputItem")
			OutputMessage("RightBackSlotInputItem")
		elseif slotName == "Holster.Container.Weapon.Slot2" then
			if vestSide == "Left" then
				SendMessage("LeftHipSlotInputItem")
				OutputMessage("LeftHipSlotInputItem")
			elseif vestSide == "Right" then
				SendMessage("RightHipSlotInputItem")
				OutputMessage("RightHipSlotInputItem")
			end
		end
	else
		if slotName == "Holster.Player.Vest" then			
			SendMessage("GetOffChestRig")
			OutputMessage("GetOffChestRig")
			vestSide = nil
		elseif slotName == "Holster.Player.Tablet" then
			SendMessage("LeftBackHipSlotOutputItem")
			OutputMessage("LeftBackHipSlotOutputItem")
		elseif slotName == "Holster.Player.LeftForearm" then
			SendMessage("LeftArmSlotOutputItem")
			OutputMessage("LeftArmSlotOutputItem")
		elseif slotName == "Holster.Player.RightForearm" then
			SendMessage("RightArmSlotOutputItem")
			OutputMessage("RightArmSlotOutputItem")
		elseif string.find(slotName,"Holster.Container.Magazine.Slot") then
			SendMessage("ChestSlotOutputItem")
			OutputMessage("ChestSlotOutputItem")
		elseif slotName == "Holster.Container.Item.Slot1" then
			SendMessage("LeftChestSlotOutputItem")
			OutputMessage("LeftChestSlotOutputItem")
		elseif slotName == "Holster.Container.Item.Slot0" then
			if string.find(HolsterComponent:get().AttachParent.AttachParent:GetFullName(),"Vertical7") then
				SendMessage("LeftChestSlotInputItem")
			else
				SendMessage("RightChestSlotInputItem")
			end		
			OutputMessage("RightChestSlotOutputItem")	
		elseif slotName == "Holster.Container.Weapon.Slot0" then
			SendMessage("RightBackSlotOutputItem")	
			OutputMessage("RightBackSlotOutputItem")
		elseif slotName == "Holster.Container.Weapon.Slot2" then
			if vestSide == "Left" then
				SendMessage("LeftHipSlotOutputItem")
				OutputMessage("LeftHipSlotOutputItem")
			elseif vestSide == "Right" then
				SendMessage("RightHipSlotOutputItem")
				OutputMessage("RightHipSlotOutputItem")
			end
		end
	end
	-- SendMessage("OnItemHolsterAttachChanged_Event")
	-- SendMessage(self:get():GetFullName())
	-- SendMessage(RadiusItem:get():GetFullName())
	-- SendMessage(tostring(bHasAttached:get()))
	-- SendMessage(HolsterComponent:get():GetFullName())
	-- SendMessage(tostring(HolsterComponent:get():GetPropertyValue("HolsterID")["TagName"]:ToString()))
end

function WeaponTypeCheck(weaponName)
	local weaponNames = split(weaponName,"/")
	SendMessage(weaponNames[1])
	if inValue(pistol,weaponNames[1]:gsub("%s+", "")) then
		return "Pistol"
	elseif inValue(rifle,weaponNames[1]:gsub("%s+", "")) then
		return "Rifle"
	elseif inValue(shotgun,weaponNames[1]:gsub("%s+", "")) then
		return "Shotgun"
	else
		return "Pistol"
	end
end

function StartFire(self)
	local canShoot = self:get():CanShoot()
	if not canShoot then
		return
	end
	if leftHandItem ~= nil and leftHandItem == self:get().AttachParent:GetFullName() then
		isFire = true
		SendMessage("--------------------------------")
		weaponType = WeaponTypeCheck(leftHandItem)
		SendMessage("LeftHand" .. weaponType .. "Shoot")
		OutputMessage("LeftHand" .. weaponType .. "Shoot")
		if isTwoHand then
			SendMessage("RightHand" .. weaponType .. "Shoot")
			OutputMessage("RightHand" .. weaponType .. "Shoot")
		end
	elseif rightHandItem ~= nil and rightHandItem == self:get().AttachParent:GetFullName() then
		isFire = true
		SendMessage("--------------------------------")
		weaponType = WeaponTypeCheck(rightHandItem)
		SendMessage("RightHand" .. weaponType .. "Shoot")
		OutputMessage("RightHand" .. weaponType .. "Shoot")
		if isTwoHand then
			SendMessage("LeftHand" .. weaponType .. "Shoot")
			OutputMessage("LeftHand" .. weaponType .. "Shoot")
		end
	end

	-- SendMessage(self:get():GetFullName())
	-- SendMessage(self:get().AttachParent:GetFullName())
	-- local canShoot = self:get():CanShoot()
	-- if canShoot then
	-- 	local leftWeaponAddress = nil
	-- 	local rightWeaponAddress = nil
	-- 	local weaponType = nil
	-- 	local shootWeaponAddress = self:get():GetPropertyValue("AttachParent"):GetAddress()

	-- 	if leftHandItem ~= nil then 		
	-- 		if leftHandItem:GetPropertyValue("WeaponMesh"):IsValid() then
	-- 			leftWeaponAddress = leftHandItem:GetPropertyValue("WeaponMesh"):GetAddress()
	-- 		end			
	-- 	end
	-- 	if rightHandItem ~= nil then 
	-- 		if rightHandItem:GetPropertyValue("WeaponMesh"):IsValid() then
	-- 			rightWeaponAddress = rightHandItem:GetPropertyValue("WeaponMesh"):GetAddress()
	-- 		end	
	-- 	end

	-- 	if leftWeaponAddress == rightWeaponAddress and leftWeaponAddress == shootWeaponAddress and leftWeaponAddress ~= nil then
	-- 		SendMessage("--------------------------------")
			
	-- 		SendMessage("LeftHand" .. weaponType .. "Shoot")
	-- 		SendMessage("RightHand" .. weaponType .. "Shoot")	
	-- 		OutputMessage("LeftHand" .. weaponType .. "Shoot")
	-- 		OutputMessage("RightHand" .. weaponType .. "Shoot")
	-- 	elseif leftWeaponAddress == shootWeaponAddress and leftWeaponAddress ~= nil then
	-- 		SendMessage("--------------------------------")
	-- 		weaponType = WeaponTypeCheck(leftHandItem:GetFullName())
	-- 		SendMessage("LeftHand" .. weaponType .. "Shoot")
	-- 		OutputMessage("LeftHand" .. weaponType .. "Shoot")
	-- 	else
	-- 		SendMessage("--------------------------------")
	-- 		weaponType = WeaponTypeCheck(rightHandItem:GetFullName())
	-- 		SendMessage("RightHand" .. weaponType .. "Shoot")	
	-- 		OutputMessage("RightHand" .. weaponType .. "Shoot")
	-- 	end
		
	-- 	SendMessage(self:get():GetFullName())
	-- end
end





function OnAnyDamageTaken(self,Actor,Damage,DamageType,InstigatedBy,DamageCauser)
	if Actor:get():GetPropertyValue("Owner"):GetPropertyValue("bIsLocalPlayerController") == false then
		return
	end
	if Actor:get():GetFullName() == DamageCauser:get():GetFullName() then
		SendMessage("--------------------------------")
		SendMessage("PoisonDamage")
		OutputMessage("PoisonDamage")
		-- SendMessage("myslef damage")
		return
	end
	local enemy = DamageCauser:get():GetPropertyValue('Controller')
	if enemy:IsValid() == false then 
		SendMessage("--------------------------------")
		SendMessage("PoisonDamage")
		OutputMessage("PoisonDamage")
		SendMessage(DamageCauser:get():GetFullName())
		SendMessage(self:get():GetFullName())
		SendMessage("enemy is not found")
		return
	end
	local enemyRotation = enemy:GetPropertyValue('ControlRotation')
	if enemyRotation:IsValid() == false then 
		SendMessage("enemyRotation is not found")
		return
	end
	
	local playerController = Actor:get():GetPropertyValue('Controller')
	if playerController:IsValid() == false then 
		SendMessage("playerController is not found")
		return
	end
	local playerRotation = playerController:GetPropertyValue('ControlRotation')
	if playerRotation:IsValid() == false then 
		SendMessage("playerRotation is not found")
		return
	else
		local angleYaw = playerRotation.Yaw - enemyRotation.Yaw
		angleYaw = angleYaw + 180
		if angleYaw > 360 then 
			angleYaw = angleYaw - 360
		end
		SendMessage("--------------------------------")
		SendMessage("DefaultDamage," .. angleYaw .. ",0")
		OutputMessage("DefaultDamage," .. angleYaw .. ",0")
		SendMessage(DamageCauser:get():GetFullName())
		SendMessage(Actor:get():GetFullName())
	end
end


function CheckPlayerSpawned()
	RegisterHook("/Script/Engine.PlayerController:ClientRestart", function()
		if resetHook then
			local ran, errorMsg = pcall(RegisterHooks)
			if ran then
				local file = io.open("TrueGear.log", "w")
				if file then
					file:close()
				else
					print("无法打开文件")
				end
				SendMessage("--------------------------------")
				SendMessage("HeartBeat")
				OutputMessage("HeartBeat")
				resetHook = false
			else
				print(errorMsg)
			end
		end		
	end)
end


SendMessage("TrueGear Mod is Loaded");
CheckPlayerSpawned()


function HeartBeat()
	if isPause or isPlayerDeath then
		return
	end
	if playerHealth < 35 then
		SendMessage("--------------------------------")
		SendMessage("HeartBeat")
		OutputMessage("HeartBeat")
	end
end

function Breath()
	if isPause or isPlayerDeath then
		return
	end
	if playerStamina < 35 and playerHunger > 30250 then
		SendMessage("--------------------------------")
		SendMessage("Breath")
		SendMessage(tostring(playerStamina))
		OutputMessage("Breath")
	end
end



LoopAsync(1000, HeartBeat)
LoopAsync(1000, Breath)
