local boxfarm_thread -- box

        Start_BoxFarm = function()
            boxfarm_thread = task.spawn(LPH_NO_VIRTUALIZE(function()
                while task.wait() do
                    if not LocalPlayer.Character then continue end
                    if not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then continue end
                    if not Config.South_Bronx.FarmingUtilities.BoxFarm then continue end

                    if (LocalPlayer.Character.HumanoidRootPart.Position - Vector3.new(-549, 3, -82)).Magnitude >= 150 then
                        Config:Teleport(CFrame.new(-549, 3, -82), true)
                    end

                    if not LocalPlayer.Backpack:FindFirstChild("Crate") and not LocalPlayer.Character:FindFirstChild("Crate") then
                        local DistanceFromBox = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(-549, 3, -82))

                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(GetTweenSpeed(DistanceFromBox), Enum.EasingStyle.Linear), {CFrame = CFrame.new(-549.1292724609375, 3.5371456146240234, -82.9239501953125)})

                        --PressKeyTween(Enum.KeyCode.W, Tween) ; PressKeyTween(Enum.KeyCode.LeftShift, Tween)

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        fireproximityprompt(Workspace.PlaceHere.Attachment.ProximityPrompt)

                        task.wait(1)

                        repeat task.wait() until LocalPlayer.Backpack:FindFirstChild("Crate")

                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack.Crate)

                        task.wait(1)
                    end

                    if not LocalPlayer.Character:FindFirstChild("Crate") then
                        LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Crate"))
                        task.wait(1)
                    end

                    if not LocalPlayer.Backpack:FindFirstChild("Crate") and not LocalPlayer.Character:FindFirstChild("Crate") then
                        continue
                    end

                    local DistanceFromTruck = GetDistance(LocalPlayer.Character.HumanoidRootPart.Position, Vector3.new(-401.04364013671875, 3.3621325492858887, -72.07713317871094))

                    local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(GetTweenSpeed(DistanceFromTruck), Enum.EasingStyle.Linear), {CFrame = CFrame.new(-401.04364013671875, 3.3621325492858887, -72.07713317871094)})

                   -- PressKeyTween(Enum.KeyCode.W, Tween) ; PressKeyTween(Enum.KeyCode.LeftShift, Tween)

                    Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                    fireproximityprompt(Workspace.cratetruck2.Model.ClickBox.Attachment.ProximityPrompt)

                    task.wait(0.9)
                end
            end))
        end

        Stop_BoxFarm = LPH_NO_VIRTUALIZE(function()
            if not boxfarm_thread then return end

            if coroutine.status(boxfarm_thread) == "suspended" then
                task.cancel(boxfarm_thread)
            end
        end)

local MarshmallowFarm_Thread -- marshmllow

        local MarshMallowStep = "Water";

        local GetNumberOfItemsInBackpack = LPH_NO_VIRTUALIZE(function(Name)
            local Amount = 0

            for Index, Value in LocalPlayer.Backpack:GetChildren() do
                if Value.Name == Name then
                    Amount+=1
                end
            end

            return Amount
        end)

        Start_MarshmallowFarm = function()
            MarshmallowFarm_Thread = task.spawn(LPH_JIT_MAX(function()
                while wait(1) do
                    if not Config.South_Bronx.FarmingUtilities.MarshmallowFarm then continue end
                    
                    local Marshmellow_Increment = Config.South_Bronx.FarmingUtilities.MarshmallowIncrement

                    local Items = {"Gelatin", "Sugar Block Bag", "Water"}

                    Config.Teleport("Force", CFrame.new(510, 4, 602))
                    
                    for Index, Value in Items do
                        for _ = 1, Marshmellow_Increment do
                            if GetNumberOfItemsInBackpack(Value) == Marshmellow_Increment then
                                continue
                            end

                            local Added = false;
                            local Child_Added; Child_Added = LocalPlayer.Backpack.ChildAdded:Connect(function(Child)
                                if Child.Name == Value then
                                    Added = true
                                    Child_Added:Disconnect()
                                end
                            end)

                            repeat task.wait(.1)
                                ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("StorePurchase"):FireServer(Value)
                            until Added == true
                        end
                    end

                    task.wait(2.5)

                    local House = GetHouse();

                    if not House then
                        local HouseToBuy = Config.GetUnclaimedApartment()

                        if not HouseToBuy then repeat task.wait(1)
                            Library:Notification({
                                Name = "Phantom.wtf | Info",
                                Description = "House not found, waiting until a house is available. or consider hopping server.",
                                Duration = 1,
                            })
                        HouseToBuy = Config.GetUnclaimedApartment() until HouseToBuy end

                        Config:Teleport(HouseToBuy.Board.backboard.CFrame, true)

                        task.wait(1)

                        fireproximityprompt(HouseToBuy.Board:FindFirstChildWhichIsA("ProximityPrompt", true))

                        task.wait(1)

                        House = GetHouse()
                    end 

                    local Personal_Apartment = Config.GetPersonalApartment()

                    if Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(0,90,0) and Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(0,- 90,0) and Personal_Apartment.Door.Interact.Rotation ~= Vector3.new(180, 0,180) then
                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = Personal_Apartment.Door.Interact.CFrame})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        task.wait(.5)

                        fireproximityprompt(Personal_Apartment.Door.Interact.Attachment.ProximityPrompt)

                        task.wait(1)
                    end

                    if Personal_Apartment.Door.DoorLock.Part.Rotation ~= Vector3.new(90,0,0) then
                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = Personal_Apartment.Door.Interact.CFrame})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        task.wait(.5)

                        fireproximityprompt(Personal_Apartment.Door.DoorLock.Part.ProximityPrompt)

                        task.wait(.5)
                    end

                    local Interior = House:FindFirstChild("Interior") or House

                    for Index, Value in Interior:GetChildren() do
                        if Value.Name == "Floor" then
                            Value.CanCollide = false
                        end
                    end

                    local Pot = Interior["Cooking Pot"]

                    Config:Teleport(Pot.CFrame, true)

                    local tween_and_prompt = function(Prompt)
                        if not Console_Server then
                            if (House.Parent.Name == "Apartments") then
                                local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = Pot.CFrame + Vector3.new(0, 7, 0)})

                                Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                                task.wait(0.5)

                                fireproximityprompt(Prompt)

                                task.wait(2.5)

                                Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = Pot.CFrame + Vector3.new(0, 16, 0)})

                                Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                            else
                                fireproximityprompt(Prompt)
                            end
                        else
                            if (House.Parent.Name == "Apartments") then
                                Config:Teleport(Pot.CFrame + Vector3.new(0, 7, 0))

                                task.wait(1.5)

                                fireproximityprompt(Prompt)

                                task.wait(2.5)

                                Config:Teleport(CFrame.new(-746 + math.random(-25, 25), 53, 588 + math.random(-25, 25)))
                            else
                                Config:Teleport(Pot.CFrame + Vector3.new(0, 7, 0))

                                task.wait(1.5)

                                fireproximityprompt(Prompt)

                                task.wait(2.5)

                                Config:Teleport(CFrame.new(-746 + math.random(-25, 25), 53, 588 + math.random(-25, 25)))
                            end    
                        end
                    end

                    if not (House.Parent.Name == "Apartments") then
                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(1, Enum.EasingStyle.Linear), {CFrame = Pot.CFrame - Vector3.new(0, 7, 0)})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil
                    end

                    LocalPlayer.Character:FindFirstChild("Humanoid"):UnequipTools()

                    task.wait();

                    local Gun = Config.GetGun()

                    if Gun then
                        if Gun.Parent == LocalPlayer.Backpack then
                            LocalPlayer.Character:FindFirstChild("Humanoid"):EquipTool(Gun)

                            repeat RunService.Stepped:Wait() until Gun.Parent == LocalPlayer.Character
                        end

                        LocalPlayer.Character:FindFirstChild("Humanoid"):UnequipTools()

                        task.wait();
                    end
                    
                    if MarshMallowStep == "Sugar Block Bag" then
                        repeat task.wait() until Pot.Timer.TextLabel.Text == "0"
                        if not LocalPlayer.Character:FindFirstChild("Sugar Block Bag") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Sugar Block Bag"))
                        end

                        task.wait(1)

                        LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                        task.wait(.5)

                        tween_and_prompt(Pot.Attachment.ProximityPrompt)

                        if not (House.Parent.Name == "Apartments") then
                            task.wait(2.5)
                        end

                        LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame - Vector3.new(0, 7, 0)

                        LocalPlayer.Character.Humanoid:UnequipTools()
                        MarshMallowStep = "Gelatin"
                    end

                    if MarshMallowStep == "Gelatin" then
                        LocalPlayer.Character.Humanoid:UnequipTools()

                        task.wait(1)

                        if not LocalPlayer.Character:FindFirstChild("Gelatin") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Gelatin"))
                        end

                        LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                        task.wait(.5)

                        tween_and_prompt(Pot.Attachment.ProximityPrompt)

                        if not (House.Parent.Name == "Apartments") then
                            task.wait(2.5)
                        end

                        LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame - Vector3.new(0, 7, 0)

                        MarshMallowStep = "Collect"
                    end

                    if MarshMallowStep == "Collect" then
                        repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                        if not LocalPlayer.Character:FindFirstChild("Empty Bag") then
                            LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Empty Bag"))
                        end

                        LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                        task.wait(1)

                        tween_and_prompt(Pot.Attachment.ProximityPrompt)

                        if not (House.Parent.Name == "Apartments") then
                            task.wait(2.5)
                        end
                        LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame - Vector3.new(0, 7, 0)

                        LocalPlayer.Character.Humanoid:UnequipTools()
                        
                        MarshMallowStep = "Water"
                    end

                    if MarshMallowStep ~= "Sell" then
                        local Water, Gel, Sug = {}, {}, {}

                        for _, Value in ipairs(LocalPlayer.Backpack:GetChildren()) do
                            if Value.Name == "Sugar Block Bag" then
                                table.insert(Sug, Value)
                            elseif Value.Name == "Gelatin" then
                                table.insert(Gel, Value)
                            elseif Value.Name == "Water" then
                                table.insert(Water, Value)
                            end
                        end

                        local highestCommon = math.min(#Water, #Gel, #Sug)

                        for _ = 1, highestCommon do
                            if MarshMallowStep == "Water" then
                                if not LocalPlayer.Character:FindFirstChild("Water") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Water"))
                                end

                                LocalPlayer.Character.HumanoidRootPart.CFrame = Pot.CFrame

                                task.wait(1)

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                if not (House.Parent.Name == "Apartments") then
                                    task.wait(2.5)
                                end     

                                MarshMallowStep = "Sugar Block Bag"
                            end

                            if MarshMallowStep == "Sugar Block Bag" then
                                repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                                if not LocalPlayer.Character:FindFirstChild("Sugar Block Bag") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Sugar Block Bag"))
                                end

                                task.wait(1)

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                if not (House.Parent.Name == "Apartments") then
                                    task.wait(2.5)
                                end

                                LocalPlayer.Character.Humanoid:UnequipTools()
                                MarshMallowStep = "Gelatin"
                            end

                            if MarshMallowStep == "Gelatin" then
                                repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                                local HumanoidConnection; HumanoidConnection = LocalPlayer.Character.Humanoid.Died:Connect(function()
                                    MarshMallowStep = "Water"
                                    HumanoidConnection:Disconnect()
                                end)

                                LocalPlayer.Character.Humanoid:UnequipTools()

                                task.wait(1)

                                if not LocalPlayer.Character:FindFirstChild("Gelatin") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Gelatin"))
                                end

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                if not (House.Parent.Name == "Apartments") then
                                    task.wait(2.5)
                                end

                                MarshMallowStep = "Collect"

                                HumanoidConnection:Disconnect()
                            end

                            if MarshMallowStep == "Collect" then
                                repeat task.wait() until Pot.Timer.TextLabel.Text == "0"

                                local HumanoidConnection; HumanoidConnection = LocalPlayer.Character.Humanoid.Died:Connect(function()
                                    MarshMallowStep = "Water"
                                    HumanoidConnection:Disconnect()
                                end)
                                
                                if not LocalPlayer.Character:FindFirstChild("Empty Bag") then
                                    LocalPlayer.Character.Humanoid:EquipTool(LocalPlayer.Backpack:FindFirstChild("Empty Bag"))
                                end

                                task.wait(1)

                                tween_and_prompt(Pot.Attachment.ProximityPrompt)

                                task.wait(1)

                                LocalPlayer.Character.Humanoid:UnequipTools()
                                
                                if _ == Marshmellow_Increment --[[MarshmallowIncrement]] then
                                    MarshMallowStep = "Sell"
                                else
                                    MarshMallowStep = "Water"
                                end

                                HumanoidConnection:Disconnect()
                            end
                        end
                    end

                    if MarshMallowStep == "Sell" then
                        Config:Teleport(CFrame.new(510, 4, 602), true, true)

                        repeat task.wait() until Workspace.Folders.NPCs:FindFirstChild('Lamont Bell')

                        task.wait(1)

                        local Tween = Services.TweenService:Create(LocalPlayer.Character.HumanoidRootPart, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {CFrame = CFrame.new(511, 4, 598)})

                        Tween:Play() ; Tween.Completed:Wait() ; Tween = nil

                        for Index, Value in LocalPlayer.Backpack:GetChildren() do
                            if Value:IsA("Tool") and Value.Name:find("Marshmallow") then
                                LocalPlayer.Character.Humanoid:EquipTool(Value)
                                fireproximityprompt(Workspace.Folders.NPCs["Lamont Bell"].UpperTorso.ProximityPrompt)
                                Config.South_Bronx.Farm_Data.Marshmellows_Sold+=1

                                task.wait(0.25)
                            end
                        end

                        MarshMallowStep = "Water"
                    end
                end
            end))
        end

        Stop_MarshmallowFarm = LPH_NO_VIRTUALIZE(function()
            if not MarshmallowFarm_Thread then return end
            if coroutine.status(MarshmallowFarm_Thread) == "suspended" then
                task.cancel(MarshmallowFarm_Thread)
            end
            Teleport_Debounce = false
            Config.DeleteHiddenScreen()
        end)
