require("deepcore/statemachine/DeepCoreState")

---@param dsl dsl
return function(dsl)
    local policy = dsl.policy

    local initialize = DeepCoreState.with_empty_policy()
    local setup = DeepCoreState(require("eawx-states/fotr-ftgu-setup-state"))
    local era_two = DeepCoreState(require("eawx-states/fotr-ftgu-era-two"))
    local era_three = DeepCoreState(require("eawx-states/fotr-ftgu-era-three"))
    local era_four = DeepCoreState(require("eawx-states/fotr-ftgu-era-four"))
    local era_five = DeepCoreState(require("eawx-states/fotr-ftgu-era-five"))

    dsl.transition(initialize)
        :to(setup)
        :when(policy:timed(2))
        :end_()

    dsl.transition(setup)
        :to(era_two)
        :when(policy:global_era(2))
        :end_()

    dsl.transition(setup)
        :to(era_three)
        :when(policy:global_era(3))
        :end_()

    dsl.transition(setup)
        :to(era_four)
        :when(policy:global_era(4))
        :end_()

    dsl.transition(setup)
        :to(era_five)
        :when(policy:global_era(5))
        :end_()
        
    return initialize
end
