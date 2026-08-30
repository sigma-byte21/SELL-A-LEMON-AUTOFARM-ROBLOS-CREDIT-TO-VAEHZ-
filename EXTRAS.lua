-- ======================== FIXED CALLFUNC ========================
local module = {}
local ts = cloneref(game:GetService("TweenService"))
local cg = cloneref(game:GetService("CoreGui"))
local ui = cloneref(game:GetService("UserInputService"))

function module:win(title)
    local window = game:GetObjects("rbxassetid://96576283085736")[1]
    local elements = game:GetObjects("rbxassetid://83539751566719")[1]

    local hui = gethui or get_hidden_gui or nil
    if hui then
        window.Parent = hui()
    else
        window.Parent = cg
    end

    local topbar = window.Frame.topbar
    topbar.title.Text = title

    local closeBtn = topbar.btns.Close
    local miniBtn = topbar.btns.Minimize
    local toggleCon = nil

    local function fadebtn(btn, isIn)
        ts:Create(btn, TweenInfo.new(0.15), {
            BackgroundTransparency = isIn and 0.8 or 1
        }):Play()
    end

    local function togglewin(isIn)
        ts:Create(window.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            GroupTransparency = isIn and 0 or 1
        }):Play()
        ts:Create(window.Frame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = isIn and UDim2.new(0.37, 0, 0.407, 0) or UDim2.new(0.37, 0, 0.376, 0)
        }):Play()
        window.Frame.Interactable = isIn and true or false
    end

    local function fadetopbar(isIn)
        ts:Create(topbar, TweenInfo.new(0.15), {
            BackgroundTransparency = isIn and 0.7 or 0.8
        }):Play()
    end

    closeBtn.MouseEnter:Connect(function() fadebtn(closeBtn, true) end)
    miniBtn.MouseEnter:Connect(function() fadebtn(miniBtn, true) end)
    closeBtn.MouseLeave:Connect(function() fadebtn(closeBtn, false) end)
    miniBtn.MouseLeave:Connect(function() fadebtn(miniBtn, false) end)
    topbar.MouseEnter:Connect(function() fadetopbar(true) end)
    topbar.MouseLeave:Connect(function() fadetopbar(false) end)

    closeBtn.MouseButton1Click:Connect(function()
        window:Destroy()
        elements:Destroy()
        if toggleCon then toggleCon:Disconnect() end
    end)

    miniBtn.MouseButton1Click:Connect(function()
        togglewin(false)
    end)

    toggleCon = ui.InputBegan:Connect(function(keyc, gamep)
        if not gamep and keyc.KeyCode == Enum.KeyCode.K then
            togglewin(not window.Frame.Interactable)
        end
    end)

    local sections = {}
    local curSelected = nil
    local dragging = false
    local dragInput, mousePos, framePos

    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            mousePos = input.Position
            framePos = window.Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    topbar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    ui.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - mousePos
            window.Frame.Position = UDim2.new(
                framePos.X.Scale, framePos.X.Offset + delta.X,
                framePos.Y.Scale, framePos.Y.Offset + delta.Y
            )
        end
    end)

    local function toggletab(tab, isIn)
        ts:Create(tab, TweenInfo.new(0.25), { GroupTransparency = isIn and 0 or 1 }):Play()
        ts:Create(tab, TweenInfo.new(0.25), {
            Position = isIn and UDim2.new(0.5, 0, 1, 0) or UDim2.new(0.5, 0, 1.1, 0)
        }):Play()
        tab.Interactable = isIn and true or false
    end

    local function fadeelement(which, isIn)
        ts:Create(which, TweenInfo.new(0.15), {
            BackgroundTransparency = isIn and 0.7 or 0.8
        }):Play()
    end

    function sections:tab(title, ico)
        local newBtn = elements.tabelement:Clone()
        newBtn.Name = title
        newBtn.Image = ico
        newBtn.title.Text = title
        newBtn.Parent = window.Frame.tabscontainer

        local newSect = elements.sectioncanvas:Clone()
        newSect.Parent = window.Frame.sectionsholder
        newSect.GroupTransparency = 1
        newSect.Position = UDim2.new(0.5, 0, 1.1, 0)
        newSect.Interactable = false

        local function fadetab(isIn)
            ts:Create(newBtn, TweenInfo.new(0.15), {ImageTransparency = isIn and 0.25 or 0.5}):Play()
            ts:Create(newBtn.title, TweenInfo.new(0.15), {TextTransparency = isIn and 0.5 or 1}):Play()
        end

        newBtn.MouseEnter:Connect(function() fadetab(true) end)
        newBtn.MouseLeave:Connect(function() fadetab(false) end)

        newBtn.MouseButton1Click:Connect(function()
            if curSelected == newSect then return end
            if curSelected ~= nil then
                toggletab(curSelected, false)
            end
            toggletab(newSect, true)
            curSelected = newSect
        end)

        local contents = {}

        function contents:label(title)
            local newLabel = elements.LabelElement:Clone()
            newLabel.lbl.Text = title
            newLabel.Parent = newSect.sectioncontainer
        end

        function contents:button(title, cb)
            local newButton = elements.ButtonElement:Clone()
            newButton.btn.lbl.Text = title
            newButton.Parent = newSect.sectioncontainer
            newButton.btn.MouseEnter:Connect(function() fadeelement(newButton.btn, true) end)
            newButton.btn.MouseLeave:Connect(function() fadeelement(newButton.btn, false) end)
            newButton.btn.MouseButton1Click:Connect(cb)
        end

        function contents:toggle(title, default, cb)
            local toggled = default
            local newToggle = elements.ToggleElement:Clone()
            newToggle.btn.lbl.Text = title
            newToggle.Parent = newSect.sectioncontainer

            newToggle.btn.MouseEnter:Connect(function() fadeelement(newToggle.btn, true) end)
            newToggle.btn.MouseLeave:Connect(function() fadeelement(newToggle.btn, false) end)

            local togglebg = newToggle.btn.togglebg
            local sidetog = togglebg.Frame

            if toggled then
                togglebg.BackgroundColor3 = Color3.fromRGB(74, 255, 89)
                sidetog.AnchorPoint = Vector2.new(1, 0.5)
                sidetog.Position = UDim2.new(1, 0, 0.5, 0)
                task.defer(cb, toggled)
            end

            newToggle.btn.MouseButton1Click:Connect(function()
                toggled = not toggled
                ts:Create(sidetog, TweenInfo.new(0.15), {
                    AnchorPoint = toggled and Vector2.new(1,0.5) or Vector2.new(0,0.5)
                }):Play()
                ts:Create(sidetog, TweenInfo.new(0.15), {
                    Position = toggled and UDim2.new(1, 0, 0.5, 0) or UDim2.new(0,0,0.5,0)
                }):Play()
                togglebg.BackgroundColor3 = toggled and Color3.fromRGB(74, 255, 89) or Color3.fromRGB(255, 75, 75)
                cb(toggled)
            end)
        end

        function contents:textbox(title, default, cb)
            local newtb = elements.TextboxElement:Clone()
            newtb.frame.lbl.Text = title
            newtb.Parent = newSect.sectioncontainer
            local inp = newtb.frame.inp.lbl
            inp.Text = default
            if default ~= "" then
                task.defer(cb, default)
            end
            inp.FocusLost:Connect(function(ep)
                if ep then cb(inp.Text) end
            end)
        end

        -- FIXED SLIDER: updates LIVE while dragging
        function contents:slider(title, min, max, default, cb)
            local newsl = elements.SliderElement:Clone()
            newsl.lbl.Text = title .. " : " .. tostring(default)
            newsl.Parent = newSect.sectioncontainer

            local slbtn = newsl.btn
            local prog = slbtn.prog
            local lastval = default
            local dragging = false

            local function setFromAlpha(alpha, fire)
                alpha = math.clamp(alpha, 0, 1)
                local value = math.floor(min + (max - min) * alpha + 0.5)
                prog.Size = UDim2.new(alpha, 0, 1, 0)
                lastval = value
                newsl.lbl.Text = title .. " : " .. tostring(value)
                if fire and cb then
                    pcall(cb, value)
                end
            end

            local function updateFromInput(x, fire)
                local rel = (x - slbtn.AbsolutePosition.X) / slbtn.AbsoluteSize.X
                setFromAlpha(rel, fire)
            end

            setFromAlpha((default - min) / (max - min), false)

            slbtn.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateFromInput(input.Position.X, true)
                end
            end)

            ui.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    updateFromInput(input.Position.X, true)
                end
            end)

            ui.InputEnded:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch) then
                    dragging = false
                    if cb then
                        pcall(cb, lastval)
                    end
                end
            end)
        end

        return contents
    end

    return sections
end

return module
