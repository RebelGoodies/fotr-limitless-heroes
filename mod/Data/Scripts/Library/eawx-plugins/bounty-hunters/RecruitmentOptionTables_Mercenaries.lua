return {
	BuildDummyName = "RANDOM_MERCENARY",
	RecruiterOptions = {"REBEL"},
	AvailableOptions = {
		"ARGYUS",
		"VAZUS",
	},
	AvailableOptionDetails = {
		["ARGYUS"] = {
			TeamName = "FARO_ARGYUS_TEAM",
			AvailableEras = {
				"ERA_1",
				"ERA_2",
			},
			active = false,
			available = true,
			ExcludedGCs = {"MALEVOLENCE"},
		},
		["VAZUS"] = {
			TeamName = "VAZUS_TEAM",
			AvailableEras = {
				"ERA_1",
				"ERA_2",
				"ERA_3",
				"ERA_4",
				"ERA_5",
			},
			active = false,
			available = true,
			ExcludedGCs = {"DURGES_LANCE","OUTER_RIM_SIEGES"},
		},
	},
}

