require("PGStateMachine")


function Definitions()
	Define_State("State_Init", State_Init)

	mando_group_maul = false
	mando_group_dw = false
	mando_group_protectors = false
end

function State_Init(message)
	-- prevent this from doing anything in galactic mode and skirmish
	if Get_Game_Mode() ~= "Land" or Find_First_Object("Team_00_Base_Position_Marker") then
		ScriptExit()
	end

	if message == OnEnter then
		local female = GameRandom.Free_Random(1, 2)

		if Find_First_Object("Darth_Maul") then
			if Find_First_Object("Darth_Maul").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = true
				mando_group_dw = false
				mando_group_protectors = false
			end
		end
		if Find_First_Object("Savage_Opress") then
			if Find_First_Object("Savage_Opress").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = true
				mando_group_dw = false
				mando_group_protectors = false
			end
		end
		
		if Find_First_Object("Gar_Saxon") then
			if Find_First_Object("Gar_Saxon").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = true
				mando_group_dw = false
				mando_group_protectors = false
			end
		end
		
		if Find_First_Object("Rook_Kast") then
			if Find_First_Object("Rook_Kast").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = true
				mando_group_dw = false
				mando_group_protectors = false
			end
		end

		if Find_First_Object("Pre_Vizsla") then
			if Find_First_Object("Pre_Vizsla").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = false
				mando_group_dw = true
				mando_group_protectors = false
			end
		end
		if Find_First_Object("Bo_Katan") then
			if Find_First_Object("Bo_Katan").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = false
				mando_group_dw = true
				mando_group_protectors = false
			end
		end
		if Find_First_Object("Lorka_Gedyc") then
			if Find_First_Object("Lorka_Gedyc").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = false
				mando_group_dw = true
				mando_group_protectors = false
			end
		end

		if Find_First_Object("Spar") then
			if Find_First_Object("Spar").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = false
				mando_group_dw = false
				mando_group_protectors = true
			end
		end
		if Find_First_Object("Fenn_Shysa") then
			if Find_First_Object("Fenn_Shysa").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = false
				mando_group_dw = false
				mando_group_protectors = true
			end
		end
		if Find_First_Object("Tobbi_Dala") then
			if Find_First_Object("Tobbi_Dala").Get_Owner() == Object.Get_Owner() then
				mando_group_maul = false
				mando_group_dw = false
				mando_group_protectors = true
			end
		end

		if mando_group_protectors == true then
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD0")
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD1")
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD2")
			if female > 1 then
				Hide_Sub_Object(Object, 0, "Protector_F_LOD0")
				Hide_Sub_Object(Object, 0, "Protector_F_LOD1")
				Hide_Sub_Object(Object, 0, "Protector_F_LOD2")
			else
				Hide_Sub_Object(Object, 0, "Protector_M_LOD0")
				Hide_Sub_Object(Object, 0, "Protector_M_LOD1")
				Hide_Sub_Object(Object, 0, "Protector_M_LOD2")
			end
		elseif mando_group_dw == true then
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD0")
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD1")
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD2")
			if female > 1 then
				Hide_Sub_Object(Object, 0, "DW_F_LOD0")
				Hide_Sub_Object(Object, 0, "DW_F_LOD1")
				Hide_Sub_Object(Object, 0, "DW_F_LOD2")
			else
				Hide_Sub_Object(Object, 0, "DW_M_LOD0")
				Hide_Sub_Object(Object, 0, "DW_M_LOD1")
				Hide_Sub_Object(Object, 0, "DW_M_LOD2")
			end
		elseif mando_group_maul == true then
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD0")
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD1")
			Hide_Sub_Object(Object, 1, "Mercenary_M_LOD2")
			if female > 1 then
				Hide_Sub_Object(Object, 0, "Super_F_LOD0")
				Hide_Sub_Object(Object, 0, "Super_F_LOD1")
				Hide_Sub_Object(Object, 0, "Super_F_LOD2")
			else
				Hide_Sub_Object(Object, 0, "Super_M_LOD0")
				Hide_Sub_Object(Object, 0, "Super_M_LOD1")
				Hide_Sub_Object(Object, 0, "Super_M_LOD2")
			end
		else
			if female > 1 then
				Hide_Sub_Object(Object, 1, "Mercenary_M_LOD0")
				Hide_Sub_Object(Object, 1, "Mercenary_M_LOD1")
				Hide_Sub_Object(Object, 1, "Mercenary_M_LOD2")

				Hide_Sub_Object(Object, 0, "Mercenary_F_LOD0")
				Hide_Sub_Object(Object, 0, "Mercenary_F_LOD1")
				Hide_Sub_Object(Object, 0, "Mercenary_F_LOD2")
			end
		end
		ScriptExit()
	end
end