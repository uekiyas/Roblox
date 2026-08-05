local TweenService = game:GetService("TweenService")

local DWPrompt = {}

function DWPrompt:Create(config)
	config = config or {}
	
	local titleText = config.Title or "BOXTEN"
	local descText = config.Description or "Boxten completes machines faster if there are more players in your round!"
	local confirmText = config.ConfirmText or "Confirm"
	local cancelText = config.CancelText or "Return"
	local onConfirm = config.OnConfirm or function() end
	local onCancel = config.OnCancel or function() end
	
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.Parent = gethui()

	local Prompt = Instance.new("Frame")
	Prompt.Name = "Prompt"
	Prompt.Size = UDim2.new(0.26563340425491333, 0, 0.2728443741798401, 0)
	Prompt.Position = UDim2.new(0.5, 0, 0.49976399540901184, 0)
	Prompt.BackgroundColor3 = Color3.fromRGB(26, 26, 26)
	Prompt.BackgroundTransparency = 0.30000001192092896
	Prompt.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Prompt.AnchorPoint = Vector2.new(0.5, 0.5)
	Prompt.Parent = ScreenGui

	local Confirm = Instance.new("TextButton")
	Confirm.Name = "Confirm"
	Confirm.Size = UDim2.new(0.4000000059604645, 0, 0.20000000298023224, 0)
	Confirm.Position = UDim2.new(0.9478415846824646, 0, 0.8860366344451904, 0)
	Confirm.BackgroundColor3 = Color3.fromRGB(0, 181, 72)
	Confirm.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Confirm.Text = confirmText
	Confirm.TextColor3 = Color3.fromRGB(255, 255, 255)
	Confirm.Font = Enum.Font.FredokaOne
	Confirm.TextScaled = true
	Confirm.TextWrapped = true
	Confirm.ZIndex = 4
	Confirm.AnchorPoint = Vector2.new(1, 1)
	Confirm.Parent = Prompt

	Instance.new("UIPadding", Confirm)
	Instance.new("UICorner", Confirm)
	Instance.new("UIStroke", Confirm)
	Instance.new("UIStroke", Confirm)
	
	local ConfirmGradient = Instance.new("UIGradient")
	ConfirmGradient.Rotation = 90
	ConfirmGradient.Parent = Confirm

	local Background = Instance.new("Frame")
	Background.Name = "Background"
	Background.Size = UDim2.new(1, 0, 1, 0)
	Background.Position = UDim2.new(0.5, 0, 0.5, 0)
	Background.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
	Background.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Background.BorderSizePixel = 0
	Background.ZIndex = 0
	Background.AnchorPoint = Vector2.new(0.5, 0.5)
	Background.Parent = Prompt

	Instance.new("UIStroke", Background)
	Instance.new("UICorner", Background)
	Instance.new("UIGradient", Background)

	local Stripes = Instance.new("ImageLabel")
	Stripes.Name = "Stripes"
	Stripes.Size = UDim2.new(1, 0, 1, 0)
	Stripes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Stripes.BackgroundTransparency = 1
	Stripes.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Stripes.BorderSizePixel = 0
	Stripes.Image = "rbxassetid://6794283750"
	Stripes.ImageColor3 = Color3.fromRGB(255, 255, 255)
	Stripes.ImageTransparency = 0.9800000190734863
	Stripes.Parent = Background

	local Trimming = Instance.new("Frame")
	Trimming.Name = "Trimming"
	Trimming.Size = UDim2.new(1, 0, 1, 0)
	Trimming.Position = UDim2.new(0.5, 0, 0.5, 0)
	Trimming.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Trimming.BackgroundTransparency = 0.8999999761581421
	Trimming.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Trimming.BorderSizePixel = 0
	Trimming.Visible = false
	Trimming.AnchorPoint = Vector2.new(0.5, 0.5)
	Instance.new("UICorner", Trimming).Parent = Trimming
	Trimming.Parent = Background

	local Description = Instance.new("TextLabel")
	Description.Name = "Description"
	Description.Size = UDim2.new(0.9215831160545349, -10, 0.5051830410957336, -10)
	Description.Position = UDim2.new(0.5050898194313049, 0, 0.39172306656837463, 0)
	Description.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	Description.BackgroundTransparency = 1
	Description.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Description.BorderSizePixel = 0
	Description.Text = descText
	Description.TextColor3 = Color3.fromRGB(190, 190, 190)
	Description.TextSize = 14
	Description.Font = Enum.Font.FredokaOne
	Description.TextScaled = true
	Description.TextWrapped = true
	Description.ZIndex = 2
	Description.AnchorPoint = Vector2.new(0.5, 0.5)
	Description.Parent = Prompt

	local DescGradient = Instance.new("UIGradient")
	DescGradient.Rotation = 90
	DescGradient.Parent = Description
	
	Instance.new("UIStroke", Description)

	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(0.8500000238418579, 0, 0.1651136875152588, 0)
	Title.Position = UDim2.new(0.5, 0, -8.540012430557908e-08, 5)
	Title.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderColor3 = Color3.fromRGB(0, 0, 0)
	Title.BorderSizePixel = 0
	Title.Text = titleText
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)
	Title.TextSize = 14
	Title.Font = Enum.Font.FredokaOne
	Title.TextScaled = true
	Title.TextWrapped = true
	Title.ZIndex = 2
	Title.AnchorPoint = Vector2.new(0.5, 1)
	Instance.new("UICorner", Title).Parent = Title
	Title.Parent = Prompt

	local Cancel = Instance.new("TextButton")
	Cancel.Name = "Cancel"
	Cancel.Size = UDim2.new(0.4000000059604645, 0, 0.20000000298023224, 0)
	Cancel.Position = UDim2.new(0.04784141853451729, 0, 0.8860366344451904, 0)
	Cancel.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	Cancel.BorderColor3 = Color3.fromRGB(27, 42, 53)
	Cancel.Text = cancelText
	Cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
	Cancel.Font = Enum.Font.FredokaOne
	Cancel.TextScaled = true
	Cancel.TextWrapped = true
	Cancel.ZIndex = 4
	Cancel.AnchorPoint = Vector2.new(0, 1)
	Cancel.Parent = Prompt

	Instance.new("UIPadding", Cancel)
	Instance.new("UICorner", Cancel)
	Instance.new("UIStroke", Cancel)
	Instance.new("UIStroke", Cancel)
	
	local CancelGradient = Instance.new("UIGradient")
	CancelGradient.Rotation = 90
	CancelGradient.Parent = Cancel

	Instance.new("UICorner", Prompt)
	Instance.new("UIAspectRatioConstraint", Prompt)

	local function setupHover(button, originalColor)
		button.MouseEnter:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = originalColor:Lerp(Color3.fromRGB(255, 255, 255), 0.15)
			}):Play()
		end)
		
		button.MouseLeave:Connect(function()
			TweenService:Create(button, TweenInfo.new(0.2), {
				BackgroundColor3 = originalColor
			}):Play()
		end)
	end

	setupHover(Confirm, Color3.fromRGB(0, 181, 72))
	setupHover(Cancel, Color3.fromRGB(120, 120, 120))

	Confirm.MouseButton1Click:Connect(function()
		TweenService:Create(Prompt, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.15)
		ScreenGui:Destroy()
		onConfirm()
	end)

	Cancel.MouseButton1Click:Connect(function()
		TweenService:Create(Prompt, TweenInfo.new(0.15), {Size = UDim2.new(0, 0, 0, 0)}):Play()
		task.wait(0.15)
		ScreenGui:Destroy()
		onCancel()
	end)

	Prompt.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(Prompt, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
		Size = UDim2.new(0.26563340425491333, 0, 0.2728443741798401, 0)
	}):Play()

	return ScreenGui
end

return DWPrompt
