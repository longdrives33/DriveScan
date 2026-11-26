local drivescan = {}

export type Mode = "Pure" | "Vide" | "Flux" | "React" | "Fusion"
local maxchar = 16000
local showProgress = false

local pMap:{[string]:{string}} = {
    ["Base"] = {
        "Name", "AnchorPoint", "Position", "Size", "SizeConstraint", "BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "ClipsDescendants", "LayoutOrder", "Visible", "ZIndex", "AutomaticSize", "Rotation", "Active", "Interactable", "BorderColor3"
    },
    ["Text"] = {
        "FontFace", "Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "TextTransparency", "TextXAlignment", "TextYAlignment", "RichText", "MaxVisibleGraphemes", "LineHeight", "TextTruncate"
    },
    ["Image"] = {
        "Image", "ImageColor3", "ImageTransparency", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode", "ImageRectOffset", "ImageRectSize"
    },
    ["ScrollingFrame"] = {
        "CanvasSize", "AutomaticCanvasSize", "ScrollBarThickness", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollingDirection", "ScrollingEnabled"
    },
    ["UIListLayout"] = {
        "FillDirection", "HorizontalAlignment", "VerticalAlignment", "Padding", "SortOrder", "StartCorner", "Wraps", "HorizontalFlex", "VerticalFlex", "ItemLineAlignment"
    },
    ["UIGridLayout"] = {
        "CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "StartCorner"
    },
    ["UICorner"] = {"CornerRadius"},
    ["UIStroke"] = { "ApplyStrokeMode", "Color", "LineJoinMode", "Thickness", "Transparency"},
    ["UIPadding"] = {"PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"},
    ["UIScale"] = {"Scale"},
    ["UIGradient"] = {"Color", "Offset", "Rotation", "Transparency"},
    ["UIAspectRatioConstraint"] = {"AspectRatio", "AspectType", "DominantAxis"},
    ["UISizeConstraint"] = {"MinSize", "MaxSize"},
    ["UIFlexItem"] = {"FlexMode", "GrowRatio", "ShrinkRatio", "ItemLineAlignment"},
    ["UIShadow"] = {"BlurRadius", "Color", "Enabled", "Inset", "Mode", "Offset", "ShowBehindParent", "Spread", "Transparency"}
}
local cMap:{[string]:{string}} = {
    ["ScreenGui"] = {"Name", "Enabled", "ResetOnSpawn", "ZIndexBehavior", "IgnoreGuiInset", "DisplayOrder"},
    ["Frame"] = {"Base"},
    ["CanvasGroup"] = {"Base", "GroupColor3", "GroupTransparency"},
    ["ScrollingFrame"] = {"Base", "ScrollingFrame"},
    ["TextLabel"] = {"Base", "Text"},
    ["TextButton"] = {"Base", "Text", "AutoButtonColor"},
    ["TextBox"] = {"Base", "Text", "PlaceholderText", "PlaceholderColor3", "ClearTextOnFocus", "MultiLine"},
    ["ImageLabel"] = {"Base", "Image"},
    ["ImageButton"] = {"Base", "Image", "AutoButtonColor"},
    ["ViewportFrame"] = {"Base", "Ambient", "LightColor", "LightDirection"},
    ["UICorner"] = {"UICorner"},
    ["UIStroke"] = {"UIStroke"},
    ["UIPadding"] = {"UIPadding"},
    ["UIListLayout"] = {"UIListLayout"},
    ["UIGridLayout"] = {"UIGridLayout"},
    ["UIAspectRatioConstraint"] = {"UIAspectRatioConstraint"},
    ["UIScale"] = {"UIScale"},
    ["UIGradient"] = {"UIGradient"},
    ["UISizeConstraint"] = {"UISizeConstraint"},
    ["UIFlexItem"] = {"UIFlexItem"},
    ["UIShadow"] = {"UIShadow"}
}
local cache = {}

local function mprint(str:string)
    if showProgress then
        print(str)
    end
end

local function getDefIns(cn:string): Instance?
    if cache[cn] then return cache[cn] end
    local ok, ins = pcall(Instance.new, cn)
    if ok and ins then cache[cn] = ins; return ins end
    return nil
end

local function formatNum(x:number):string
    if math.floor(x) ==  x then return tostring(x) end
    return string.format("%.3f", x):gsub("%.?0+$", "")
end

local function serializeVal(val:any):string
    local t = typeof(val)
    if t == "string" then return string.format("%q", val)
    elseif t == "number" then return formatNum(val)
    elseif t == "UDim" then
        if val.Scale == 0 and val.Offset == 0 then
            return "UDim.new()"
        end 
        return `UDim.new({formatNum(val.Scale)}, {val.Offset})`
    elseif t == "UDim2" then
        if val.X.Offset == 0 and val.Y.Offset == 0 then
            return `UDim2.fromScale({formatNum(val.X.Scale)}, {formatNum(val.Y.Scale)})`
        elseif val.X.Scale == 0 and val.Y.Scale == 0 then
            return `UDim2.fromOffset({formatNum(val.X.Offset)}, {formatNum(val.Y.Offset)})`
        end
        return `UDim2.new({formatNum(val.X.Scale)}, {val.X.Offset}, {formatNum(val.Y.Scale)}, {val.Y.Offset})`
    elseif t == "Vector2" then
        if val == Vector2.zero then return "Vector2.zero"
        elseif val == Vector2.one then return "Vector2.one"
        elseif val == Vector2.xAxis then return "Vector2.xAxis"
        elseif val == Vector2.yAxis then return "Vector2.yAxis"
        end
        return `Vector2.new({formatNum(val.X)}, {formatNum(val.Y)})`
    elseif t == "Vector3" then
        if val == Vector3.zero then return "Vector3.zero"
        elseif val == Vector3.one then return "Vector3.one"
        elseif val == Vector3.xAxis then return "Vector3.xAxis"
        elseif val == Vector3.yAxis then return "Vector3.yAxis"
        elseif val == Vector3.zAxis then return "Vector3.zAxis" end
        return `Vector3.new({formatNum(val.X)}, {formatNum(val.Y)}, {formatNum(val.Z)})`
    elseif t == "vector" then
        if val == vector.zero then return "vector.zero"
        elseif val == vector.one then return "vector.one" end
        return `vector.create({formatNum(val.X)}, {formatNum(val.Y)}, {formatNum(val.Z)})`
    elseif t == "Rect" then 
        if val.Min == Vector2.zero and val.Max == Vector2.zero then return "Rect.new()" end
        return `Rect.new({formatNum(val.Min.X)}, {formatNum(val.Min.Y)}, {formatNum(val.Max.X)}, {formatNum(val.Max.Y)})`
    elseif t == "Color3" then
        local r, g, b = math.round(val.R * 255), math.round(val.G * 255), math.round(val.B)
        if r == 255 and g == 255 and b == 255 then
            return "Color3.new(1, 1, 1)"
        elseif r == 0 and g == 0 and b == 0 then
            return "Color3.new()"
        end
        return `Color3.fromRGB({math.round(val.R * 255)}, {math.round(val.G * 255)}, {math.round(val.B * 255)})`
    elseif t == "Font" then return `Font.new("{val.Family}", {val.Weight}, {val.Style})`
    elseif t == "ColorSequence" then
        local kpoint = val.Keypoints 
        if #kpoint == 2 and kpoint[1].Value == kpoint[2].Value then return `ColorSequence.new({serializeVal(kpoint[1].Value)})` end
        local keypoints:{string} = {}
        for _, kp in kpoint do
            table.insert(keypoints, `ColorSequenceKeypoint.new({formatNum(kp.Time)}, {serializeVal(kp.Value)})`)
        end
        return "ColorSequence.new({" .. table.concat(keypoints, ", ") .. "})"
    elseif t == "NumberSequence" then
        local kpoint = val.Keypoints
        if #kpoint == 2 and kpoint[1].Value == kpoint[2].Value and kpoint[1].Envelope == 0 and kpoint[2].Envelope == 0 then return `NumberSequence.new({formatNum(kpoint[1].Value)})` end
        local keypoints:{string} = {}
        for _, kp in kpoint do
            if kp.Envelope == 0 then
                table.insert(keypoints, `NumberSequenceKeypoint.new({formatNum(kp.Time)}, {formatNum(kp.Value)})`)
            else
                table.insert(keypoints, `NumberSequenceKeypoint.new({formatNum(kp.Time)}, {formatNum(kp.Value)}, {formatNum(kp.Envelope)})`)
            end
        end
        return "NumberSequence.new({" .. table.concat(keypoints, ", ") .. "})"
    end
return tostring(val)

end

local function getChangedProps(ins:Instance):{{name: string, value:string}}
    local cn = ins.ClassName
    local profile = cMap[cn]
    if not profile then return {} end
    local defIns = getDefIns(cn)
    local propsToCheck:{string} = {}

    for _, v in profile do
        if pMap[v] then
            for _, vv in pMap[v] do
                table.insert(propsToCheck, vv)
            end
        else
            table.insert(propsToCheck, v)
        end
    end
    local changed = {}
    for _, v in propsToCheck do
        local ok, val = pcall(function() return (ins)[v] end)
        if ok and val ~= nil then
            local different = true
            if defIns then
                local dok, dval = pcall(function() return defIns[v] end)
                if dok and dval == val then different = false end
            end
            if v == "Name" and val == cn then different = false end

            if different then 
                table.insert(changed, {name = v, value = serializeVal(val)})
            end
        end
    end
    return changed
end

local function getName(n:string, used:{[string]:number}): string
    local clean = n:gsub("[^%w_]", "")
    if clean == "" or clean:match("^%d") then clean = `UI_{clean}` end
    clean = clean:sub(1, 1):lower() .. clean:sub(2)

    local count = used[clean] or 0
    used[clean] = count + 1
    if count > 0 then return clean .. tostring(count + 1) end
    return clean
end

local function genPure(root:Instance, gen:boolean): string
    local lines:{string} = {}
    mprint("Starting luau..")

    if gen then
        table.insert(lines, "Have fun with scripting!")
        table.insert(lines, "")
    end
    local used:{[string]:number} = {}

    local function visit(ins:Instance, parvar:string?)
        local cn = ins.ClassName
        mprint(`Scanning {ins.Name}/{cn}..`)
        if not cMap[cn] then
            mprint(`{cn} type of UI isn't supported yet:(`)
            return
        end
        local name = getName(ins.Name, used)
        table.insert(lines, `local {name} = Instance.new("{cn}")`)

        local props = getChangedProps(ins)
        for _, prop in props do
            table.insert(lines, `{name}.{prop.name} = {prop.value}`)
        end
        if parvar then
            table.insert(lines, `{name}.Parent = {parvar}`)
        end
        table.insert(lines, "")
        for _, child in ins:GetChildren() do
            visit(child, name)
        end
        mprint(`Done with {ins.Name}/{cn}!`)
    end
    local rootCode = visit(root, nil)
    mprint(rootCode == true and "Successfully generated luau!" or "Couldn't scan given data.")
    return table.concat(lines, "\n")
end

local function genVide(root:Instance, gen:boolean): string
    local lines:{string} = {}
    mprint("Starting Vide..")

    if gen then
        mprint("Preparing..")
        table.insert(lines, "local Vide = require(???) --your path here!")
        table.insert(lines, "local create = Vide.create --btw everyone uses upvalues js for vide, but you can do it everywhere!(yep idk why am i shitposting sry)")
        table.insert(lines, "")
    end

    local function visit(ins:Instance, indent:number):string?
        local cn = ins.ClassName
        mprint(`Scanning {ins.Name}/{cn}..`)
        if not cMap[cn] then
            mprint(`{cn} type of UI isn't supported yet:()`)
            return nil
        end
        local ind = string.rep("\t", indent)
        local inner = string.rep("\t", indent + 1)
        local block:{string} = {}

        table.insert(block, string.format("%screate %q {", ind, cn))
        local props = getChangedProps(ins)
        for _, prop in props do
            table.insert(block, `{inner}{prop.name} = {prop.value},`)
        end
        
        local children = ins:GetChildren()
        if #children > 0 and #props > 0 then
            table.insert(block, "")
        end
        for _, child in children do
            local code = visit(child, indent + 1)
            if code then
                table.insert(block, code .. ",")
            end
        end
        table.insert(block, `{ind}}`)
        mprint(`Done with {ins.Name}/{cn}!`)
        return table.concat(block, "\n")
    end

    local rootCode = visit(root, 1)
    if rootCode then
        table.insert(lines, "local function Generate()")
        table.insert(lines, "\treturn " .. rootCode:gsub("^\t", ""))
        table.insert(lines, "end")
        table.insert(lines, "")
        table.insert(lines, "return Generate")
        mprint("Successfully generated Vide!")
    else
        mprint("Couldn't scan given data.")
    end
    return table.concat(lines, "\n")
end

local function genFlux(root:Instance, gen:boolean):string
    local lines:{string} = {}
    mprint("Starting Flux..")

    if gen then
        mprint("Preparing..")
        table.insert(lines, "local Flux = require(???) --your path here!!")
        table.insert(lines, "local new = Flux.new --another fun fact, the module creator's birthday is soon:D I'm turning 15 this end of January")
        table.insert(lines, "")
    end
    local function visit(ins: Instance, indent: number):string?
        local cn = ins.ClassName
        mprint(`Scanning {ins.Name}/{cn}...`)
        if not cMap[cn] then
            mprint(`{cn} type of UI isn't supported yet:(`)
            return nil
        end
        local ind = string.rep("\t", indent)
        local inner = string.rep("\t", indent + 1)
        local block:{string} = {}

        table.insert(block, string.format("%snew %q {", ind, cn))

        local props = getChangedProps(ins)
        for _, prop in props do
            table.insert(block, `{inner}{prop.name} = {prop.value}`)
        end

        local children = ins:GetChildren()
        for _, child in children do
            local code = visit(child, indent + 1)
            if code then
                table.insert(block, code .. ",")
            end
        end
        
        table.insert(block, `{ind}}`)
        mprint(`Done with {ins.Name}/{cn}!`)
        return table.concat(block, "\n")
    end
    local rootCode = visit(root, 1)
    if rootCode then
        table.insert(lines, "local function Generate()")
        table.insert(lines, "\treturn" .. rootCode:sub(2))
        table.insert(lines, "end")
        table.insert(lines, "")
        table.insert(lines, "return Generate")
        mprint(`Successfully generated Flux!`)
    else
        mprint("Couldn't scan given data.")
    end

    return table.concat(lines, "\n")
end

local function genFus(root:Instance, gen:boolean):string
    local lines:{string} = {}
    mprint("Starting fusion..")

    if gen then
        mprint("Preparing..")
        table.insert(lines, "local Fusion = require(???) --your path here!!")
        table.insert(lines, "local Children = Fusion.Children --I don't have any fun facts:(")
    end
    local function visit(ins:Instance, indent:number):string?
        local cn = ins.ClassName
        mprint(`Scanning {ins.Name}/{cn}..`)
        if not cMap[cn] then
            mprint(`{cn} type of UI isn't supported yet:(`)
            return nil
        end

        local ind = string.rep("\t", indent)
        local inner = string.rep("\t", indent + 1)
        local block:{string} = {}
		table.insert(block, string.format("%sscope:New %q {", ind, cn))

        local props = getChangedProps(ins)
        for _, prop in props do
            table.insert(block, `{inner}{prop.name} = {prop.value},`)
        end
        local childBlock:{string} = {}
        for _, child in ins:GetChildren() do
            local code = visit(child, indent + 2)
            if code then
                table.insert(childBlock, code .. ",")
            end
        end

        if #childBlock > 0 then 
            if #props > 0 then
                table.insert(block, "")
            end
            table.insert(block, `{inner}[Children] = \{`)
            for _, cCode in childBlock do
                table.insert(block, cCode)
            end
            table.insert(block, `{inner}\},`)
        end
        table.insert(block, string.format("%s}", ind))
        mprint(`Done with {ins.Name}/{cn}!`)
        return table.concat(block, "\n")
    end

    local rootCode = visit(root, 1)
    if rootCode then
        table.insert(lines, "local function Generate(scope: Fusion.Scope<typeof(Fusion)>)")
        table.insert(lines, "\treturn " .. rootCode:sub(2))
        table.insert(lines, "end")
        table.insert(lines, "")
        table.insert(lines, "return Generate")
        mprint("Successfully generated Fusion!")
    else
        mprint("Couldn't scan given data.")
    end
    return table.concat(lines, "\n")
end

local function genReact(root:Instance, gen:boolean):string
    local lines:{string} = {}
    mprint("Starting React..")
    if gen then
        mprint("Preparing..")
        table.insert(lines, "local React = require(???) --your path here!")
        table.insert(lines, "")
    end

    local function visit(ins: Instance, indent:number):string?
        local cn = ins.ClassName
        mprint(`Scanning {ins.Name}/{cn}..`)

        if not cMap[cn] then
            mprint(`{cn} type of UI isn't supported yet:(`)
            return nil
        end

        local ind = string.rep("\t", indent)
		local inner = string.rep("\t", indent + 1)
		local block: { string } = {}

		local props = getChangedProps(ins)
		local childBlocks: { string } = {}
		for _, child in ins:GetChildren() do
			local code = visit(child, indent + 1)
			if code then
				table.insert(childBlocks, code .. ",")
			end
		end

		if #props == 0 and #childBlocks == 0 then
			return string.format("%sReact.createElement(%q)", ind, cn)
		end

		table.insert(block, string.format("%sReact.createElement(%q, {", ind, cn))
		for _, prop in props do
			table.insert(block, `{inner}{prop.name} = {prop.value},`)
		end

		if #childBlocks == 0 then
			table.insert(block, string.format("%s})", ind))
		else
			table.insert(block, string.format("%s}, {", ind))
			for _, cCode in childBlocks do
				table.insert(block, cCode)
			end
			table.insert(block, string.format("%s})", ind))
		end

        mprint(`Done with {ins.Name}/{cn}!`)
		return table.concat(block, "\n")
	end

    local rootCode = visit(root, 1)
	if rootCode then
		table.insert(lines, "local function Generate()")
		table.insert(lines, "\treturn " .. rootCode:sub(2))
		table.insert(lines, "end")
		table.insert(lines, "")
		table.insert(lines, "return Generate")
        mprint("Successfully generated React!")
    else
        mprint("Couldn't scan given data.")
	end

	return table.concat(lines, "\n")
end

local actions:{} = {
    ["Pure"] = genPure,
    ["Vide"] = genVide,
    ["Flux"] = genFlux,
    ["React"] = genReact,
    ["Fusion"] = genFus
}

function drivescan.Scan(Root:ScreenGui, Type:Mode):string
    mprint("Initializing..")
    local output:string
    output = actions[Type](Root, true)
    mprint("Scan done!")
    return output
end

function drivescan.Analyze(Root:Folder, Type:Mode):string
    mprint("Analyzing..")
    local lines:{string} = {}
    local output:string
    local roots:{ScreenGui} = {}
    local gen = true
    for _, v in Root:GetChildren() do
        if v:IsA("ScreenGui") then
            table.insert(roots, v)
        end
    end
    for _, v in roots do
        table.insert(lines, actions[Type](v, gen))
        gen = false
    end
    output = table.concat(lines, "\n")
    mprint("Analyze done!")
    return output
end

function drivescan.Print(Value:string, Size:number?):()
    local s = Size or maxchar
    if s <= 0 then s = maxchar end
    local waitNum = 0
    for i = 1, #Value, s do
        print(Value:sub(i, i + s - 1))
        waitNum += 1
        if waitNum % 10 == 0 then task.wait() end
    end
end

function drivescan.Cache():()
    for _, ins in cache do
        ins:Destroy()
    end
    table.clear(cache)
    mprint("Cache cleared!")
end

return drivescan