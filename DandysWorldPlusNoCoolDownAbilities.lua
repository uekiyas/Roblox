local Admin_Event = game.ReplicatedStorage:WaitForChild("Events"):WaitForChild("AdminEvent")

while task.wait(0.1) do
    local success, isVisible = pcall(function()
        return game.Players.LocalPlayer.PlayerGui.ScreenGui.Ability1.CooldownFrame.Visible
    end)
    
    if success and isVisible then
        Admin_Event:FireServer("ResetCooldown")
    end
end
