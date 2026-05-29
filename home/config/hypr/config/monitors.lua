local laptop = "desc:BOE 0x095F"
local dell = "desc:Dell Inc. DELL U2723QE 688XM04"
local lg = "desc:LG Electronics LG ULTRAGEAR 010NTHM7V873"

-- Fallback for unknown displays. Keeps single-monitor setups simple.
hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
})

-- Laptop display.
hl.monitor({
    output = laptop,
    mode = "2256x1504@60",
    position = "0x0",
    scale = 1.17,
})

-- Dell U2723QE, centered in the docked layout.
hl.monitor({
    output = dell,
    mode = "3840x2160@60",
    position = "1920x0",
    scale = 1.5,
})

-- LG Ultragear, right side in the docked layout.
hl.monitor({
    output = lg,
    mode = "2560x1440@144",
    position = "4480x0",
    scale = 1,
})

local function monitor_count()
    local count = 0

    for _, _ in ipairs(hl.get_monitors()) do
        count = count + 1
    end

    return count
end

local function monitor_name(selector)
    local monitor = hl.get_monitor(selector)

    if monitor == nil then
        return nil
    end

    return monitor.name
end

local function move_range(first, last, monitor)
    for i = first, last do
        local workspace = tostring(i)

        hl.workspace_rule({
            workspace = workspace,
            monitor = monitor,
            persistent = true,
        })

        local existing_workspace = hl.get_workspace(workspace)

        if existing_workspace == nil and i == first then
            hl.dispatch(hl.dsp.focus({ workspace = workspace }))
        end

        hl.dispatch(hl.dsp.workspace.move({
            workspace = workspace,
            monitor = monitor,
        }))
    end
end

local function laptop_profile()
    local laptop_name = monitor_name(laptop)

    if laptop_name == nil then
        return
    end

    move_range(1, 9, laptop_name)
    hl.dispatch(hl.dsp.focus({ monitor = laptop_name }))
    hl.dispatch(hl.dsp.focus({ workspace = "1" }))
end

local function dock_profile()
    local laptop_name = monitor_name(laptop)
    local dell_name = monitor_name(dell)
    local lg_name = monitor_name(lg)

    if laptop_name == nil or dell_name == nil or lg_name == nil then
        laptop_profile()
        return
    end

    move_range(1, 2, laptop_name)
    move_range(3, 6, dell_name)
    move_range(7, 9, lg_name)

    hl.dispatch(hl.dsp.focus({ monitor = laptop_name }))
    hl.dispatch(hl.dsp.focus({ workspace = "1" }))
end

local function apply_monitor_profile()
    if monitor_count() <= 1 then
        laptop_profile()
    else
        dock_profile()
    end
end

hl.on("hyprland.start", function()
    apply_monitor_profile()
end)

hl.on("monitor.added", function()
    apply_monitor_profile()
end)

hl.on("monitor.removed", function()
    apply_monitor_profile()
end)

apply_monitor_profile()
