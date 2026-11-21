local drivescan = {}

export type Mode = "Pure" | "Vide" 
local maxchar = 16000

local pMap:{[string]:{string}} = {
    ["Base"] = {
        "Name", "AnchorPoint", "Position", "Size", "SizeConstraint", "BackgroundColor3", "BackgroundTransparency", "BorderSizePixel", "ClipsDescendants", "LayoutOrder", "Visible", "ZIndex", "AutomaticSize", "Rotation"
    },
    ["Text"] = {
        "FontFace", "Text", "TextColor3", "TextSize", "TextScaled", "TextWrapped", "TextTransparency", "TextXAlignment", "TextYAlignment", "RichText", "MaxVisibleGraphemes"
    },
    ["Image"] = {
        "Image", "ImageColor3", "ImageTransparency", "ScaleType", "SliceCenter", "SliceScale", "TileSize", "ResampleMode"
    },
    ["ScrollingFrame"] = {
        "CanvasSize", "AutomaticCanvasSize", "ScrollBarThickness", "ScrollBarImageColor3", "ScrollBarImageTransparency", "ScrollingDirection"
    },
    ["UIListLayout"] = {
        "FillDirection", "HorizontalAlignment", "VerticalAlignment", "Padding", "SortOrder", "StartCorner"
    },
    ["UIGridLayout"] = {
        "CellPadding", "CellSize", "FillDirection", "FillDirectionMaxCells", "HorizontalAlignment", "VerticalAlignment", "SortOrder", "StartCorner"
    },
    ["UICorner"] = {"CornerRadius"},
    ["UIStroke"] = { "ApplyStrokeMode", "Color", "LineJoinMode", "Thickness", "Transparency"},
    ["UIPadding"] = {"PaddingTop", "PaddingBottom", "PaddingLeft", "PaddingRight"},
    ["UIScale"] = {"Scale"},
    ["UIGradient"] = {"Color", "Offset", "Rotation", "Transparency"},
    ["UIAspectRatioConstraint"] = {"AspectRatio", "AspectType", "DominantAxis"}
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
    ["UIGradient"] = {"UIGradient"}
}
local cache = {}

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
    elseif t == "UDim" then return `UDim.new({formatNum(val.Scale)}, {val.Offset})`
    elseif t == "UDim2" then return `UDim2.new({formatNum(val.X.Scale)}, {val.X.Offset}, {formatNum(val.Y.Scale)}, {val.Y.Offset})`
    elseif t == "Vector2" then return `Vector2.new({formatNum(val.X)}, {formatNum(val.Y)})`
    elseif t == "Vector3" then return `Vector3.new({formatNum(val.X)}, {formatNum(val.Y)}, {formatNum(val.Z)})`
    elseif t == "vector" then return `vector.create({formatNum(val.X)}, {formatNum(val.Y)}, {formatNum(val.Z)})`
    elseif t == "Rect" then return `Rect.new({formatNum(val.Min.X)}, {formatNum(val.Min.Y)}, {formatNum(val.Max.X)}, {formatNum(val.Max.Y)})`
    elseif t == "Color3" then return `Color3.fromRGB({math.round(val.R * 255)}, {math.round(val.G * 255)}, {math.round(val.B * 255)})`
    elseif t == "Font" then return `Font.new("{val.Family}", {val.Weight}, {val.Style})`
    elseif t == "ColorSequence" then 
        local keypoints:{string} = {}
        for _, kp in val.Keypoints do
            table.insert(keypoints, `ColorSequenceKeypoint.new({formatNum(kp.Time)}, {serializeVal(kp.Value)})`)
        end
        return "ColorSequence.new({" .. table.concat(keypoints, ", ") .. "})"
    elseif t == "NumberSequence" then
        local keypoints:{string} = {}
        for _, kp in val.Keypoints do
            table.insert(keypoints, `NumberSequenceKeypoint.new({formatNum(kp.Time)}, {formatNum(kp.Value)}, {formatNum(kp.Envelope)})`)
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

local function genPure(root:Instance): string
    local lines:{string} = {}
    local used:{[string]:number} = {}

    local function visit(ins:Instance, parvar:string?)
        local cn = ins.ClassName
        if not cMap[cn] then return end
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
    end
    visit(root, nil)
    return table.concat(lines, "\n")
end

local function genVide(root:Instance): string
    local lines = {
        "local Vide = require(???) --your path here!",
        "local create = Vide.create --btw everyone uses upvalues js for vide, but you can do it everywhere!(yep idk why am i shitposting sry)"
    }
    local function visit(ins:Instance, indent:number):string?
        local cn = ins.ClassName
        if not cMap[cn] then return nil end
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
        table.insert(block, string.format("%s}", ind))
        return table.concat(block, "\n")
    end

    local rootCode = visit(root, 1)
    if rootCode then
        table.insert(lines, "local function Generate()")
        table.insert(lines, "\treturn " .. rootCode:gsub("^\t", ""))
        table.insert(lines, "end")
        table.insert(lines, "")
        table.insert(lines, "return Generate")
    end
    return table.concat(lines, "\n")
end

function drivescan.Scan(Root:ScreenGui, Type:Mode):string
    local output = Type == "Pure" and genPure(Root) or genVide(Root)
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
end

return drivescan