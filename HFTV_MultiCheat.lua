local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local function cam() return Workspace.CurrentCamera end

local Package = ReplicatedStorage:WaitForChild("ReplicatedStoragePackageLink", 20)
local Remotes = Package and Package:WaitForChild("Remotes", 20)
local Shared = Package and Package:WaitForChild("Shared", 20)
if not Remotes then warn("[HFTV] wrong game") return end

local function req(n)
    local m = Shared and Shared:FindFirstChild(n)
    if not m then return nil end
    local ok, r = pcall(require, m)
    return ok and r or nil
end

local GameConfig = req("GameConfig") or {}
local MovementConfig = req("MovementConfig") or {}
local TaskConfig = req("TaskConfig") or {}
local SkillConfig = req("SkillConfig") or {}

local VILLAIN_HP = GameConfig.VillainHealth or 450
local ULTRA_JUMP_VEL = MovementConfig.UltraJumpVelocity or 115
local WALK_SPEED = MovementConfig.WalkSpeed or 16
local RUN_SPEED = MovementConfig.RunSpeed or 34
local TASK_MIN = TaskConfig.MinDuration or 2

local function R(n) return Remotes:FindFirstChild(n) end
local function fire(n, ...)
    local r = R(n)
    if r and r:IsA("RemoteEvent") then
        local a = table.pack(...)
        return (pcall(function() r:FireServer(table.unpack(a, 1, a.n)) end))
    end
    return false
end
local function onRemote(n, cb)
    local r = R(n)
    if r and r:IsA("RemoteEvent") then return r.OnClientEvent:Connect(cb) end
end

local S = {
    lang = "ru",
    espPlayers = false, espNames = true, espBox = true, espHP = true, espDist = true, tracers = false,
    espLoot = false, espCrates = false, espPrompts = false, espMaxDist = 400,
    infJump = false, ultraJumpSpam = false, ultraDelay = 0.05, speedOn = false, speedValue = RUN_SPEED,
    antiRagdoll = false, antiSlow = false, autoDodge = false, dodgeCooldown = 0.2,
    autoTask = false, taskDelay = 0, autoPrompt = false, promptCooldown = 0.4,
    autoHeal = false, healThreshold = 60, healCooldown = 3,
    aimbot = false, aimFov = 140, aimPart = "Head", autoPunch = false, punchRate = 0.35,
    phoneSpam = false, hudVisible = true, espRate = 0.1,
}

local Round = { state = "?", endsAt = 0, chance = nil, myRole = "?" }
local Watch = { filmed = false, hearing = 0 }
local tpTargetName = nil

local LANGS = { "ru", "en", "es" }
local LANG_LABEL = { ru = "\u0420\u0443\u0441\u0441\u043a\u0438\u0439", en = "English", es = "Espa\u00f1ol" }

local T = {
    ru = {
        title = "HFTV Multi-Cheat v5", sub = "\u0441\u043e\u0431\u0440\u0430\u043d\u043e \u043f\u043e \u0434\u0430\u043c\u043f\u0443 \u0438\u0433\u0440\u044b",
        tabVisuals = "\u0412\u0438\u0437\u0443\u0430\u043b", tabMove = "\u0414\u0432\u0438\u0436\u0435\u043d\u0438\u0435", tabCombat = "\u0411\u043e\u0439", tabFarm = "\u0424\u0430\u0440\u043c", tabMisc = "\u0420\u0430\u0437\u043d\u043e\u0435", tabSettings = "\u041d\u0430\u0441\u0442\u0440\u043e\u0439\u043a\u0438",
        espPlayers = "ESP \u0438\u0433\u0440\u043e\u043a\u043e\u0432", espBox = "\u041f\u043e\u0434\u0441\u0432\u0435\u0442\u043a\u0430", espNames = "\u041d\u0438\u043a\u0438 \u0438 \u0441\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u044f",
        espHP = "\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0442\u044c HP", espDist = "\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0442\u044c \u0434\u0438\u0441\u0442\u0430\u043d\u0446\u0438\u044e", tracers = "\u0422\u0440\u0435\u0439\u0441\u0435\u0440\u044b",
        espCrates = "ESP \u044f\u0449\u0438\u043a\u043e\u0432", espLoot = "ESP \u043b\u0443\u0442\u0430 (Temp V / \u0430\u043f\u0442\u0435\u0447\u043a\u0438)", espPrompts = "ESP \u0438\u043d\u0442\u0435\u0440\u0430\u043a\u0442\u0438\u0432\u043e\u0432",
        espMaxDist = "\u041c\u0430\u043a\u0441. \u0434\u0438\u0441\u0442\u0430\u043d\u0446\u0438\u044f ESP", rescan = "\u041f\u0435\u0440\u0435\u0441\u043a\u0430\u043d\u0438\u0440\u043e\u0432\u0430\u0442\u044c \u043a\u0430\u0440\u0442\u0443", cratesFound = "\u041d\u0430\u0439\u0434\u0435\u043d\u043e \u044f\u0449\u0438\u043a\u043e\u0432: ",
        infJump = "\u0411\u0435\u0441\u043a\u043e\u043d\u0435\u0447\u043d\u044b\u0439 \u043f\u0440\u044b\u0436\u043e\u043a", ultraSpam = "\u0421\u043f\u0430\u043c ultra jump (\u043f\u0440\u043e\u0431\u0435\u043b)", ultraOnce = "Ultra jump (\u0440\u0430\u0437\u043e\u0432\u043e)",
        ultraDelay = "\u0417\u0430\u0434\u0435\u0440\u0436\u043a\u0430 ultra jump, \u0441\u0435\u043a", speedOn = "\u0418\u0437\u043c\u0435\u043d\u0438\u0442\u044c \u0441\u043a\u043e\u0440\u043e\u0441\u0442\u044c", speedValue = "\u0421\u043a\u043e\u0440\u043e\u0441\u0442\u044c",
        antiRagdoll = "Anti-ragdoll / anti-stun", antiSlow = "Anti-slow / anti-root",
        tpCrate = "\u0422\u041f: \u0431\u043b\u0438\u0436\u0430\u0439\u0448\u0438\u0439 \u044f\u0449\u0438\u043a", tpLoot = "\u0422\u041f: \u0431\u043b\u0438\u0436\u0430\u0439\u0448\u0438\u0439 \u043b\u0443\u0442", tpSpawn = "\u0422\u041f: \u0441\u043f\u0430\u0432\u043d \u0432\u044b\u0436\u0438\u0432\u0448\u0438\u0445", tpStore = "\u0422\u041f: \u043c\u0430\u0433\u0430\u0437\u0438\u043d \u0438\u043d\u0441\u0442\u0440\u0443\u043c\u0435\u043d\u0442\u043e\u0432",
        player = "\u0418\u0433\u0440\u043e\u043a", refresh = "\u041e\u0431\u043d\u043e\u0432\u0438\u0442\u044c \u0441\u043f\u0438\u0441\u043e\u043a", tpPlayer = "\u0422\u041f: \u043a \u0438\u0433\u0440\u043e\u043a\u0443",
        aimbot = "Aimbot (\u043a\u0430\u043c\u0435\u0440\u0430)", aimFov = "Aimbot FOV (\u043f\u0438\u043a\u0441\u0435\u043b\u0438)", aimPart = "\u0422\u043e\u0447\u043a\u0430 \u043f\u0440\u0438\u0446\u0435\u043b\u0430",
        autoPunch = "\u0410\u0432\u0442\u043e SuperPunch", punchRate = "\u0418\u043d\u0442\u0435\u0440\u0432\u0430\u043b SuperPunch, \u0441\u0435\u043a", punchOnce = "SuperPunch (\u0440\u0430\u0437\u043e\u0432\u043e)",
        autoDodge = "\u0410\u0432\u0442\u043e\u0443\u0432\u043e\u0440\u043e\u0442 \u043e\u0442 \u0441\u043f\u043e\u0441\u043e\u0431\u043d\u043e\u0441\u0442\u0435\u0439", dodgeCd = "\u041a\u0443\u043b\u0434\u0430\u0443\u043d \u0443\u0432\u043e\u0440\u043e\u0442\u0430, \u0441\u0435\u043a",
        skill = "\u0421\u043a\u0438\u043b\u043b", skillUse = "\u0418\u0441\u043f\u043e\u043b\u044c\u0437\u043e\u0432\u0430\u0442\u044c \u0441\u043a\u0438\u043b\u043b", skillManual = "\u0421\u043a\u0438\u043b\u043b \u0432\u0440\u0443\u0447\u043d\u0443\u044e",
        autoTask = "\u0410\u0432\u0442\u043e\u0437\u0430\u0434\u0430\u043d\u0438\u044f", taskDelay = "\u0417\u0430\u0434\u0435\u0440\u0436\u043a\u0430 \u0437\u0430\u0434\u0430\u043d\u0438\u044f, \u0441\u0435\u043a", autoPrompt = "\u0410\u0432\u0442\u043e\u043e\u0442\u043a\u0440\u044b\u0442\u0438\u0435 \u044f\u0449\u0438\u043a\u043e\u0432 \u0438 \u043f\u0440\u043e\u043c\u043f\u0442\u043e\u0432",
        promptCd = "\u041a\u0443\u043b\u0434\u0430\u0443\u043d \u043f\u0440\u043e\u043c\u043f\u0442\u0430, \u0441\u0435\u043a", autoHeal = "\u0410\u0432\u0442\u043e\u043b\u0435\u0447\u0435\u043d\u0438\u0435", healThreshold = "\u041f\u043e\u0440\u043e\u0433 \u043b\u0435\u0447\u0435\u043d\u0438\u044f, % HP",
        healCd = "\u041a\u0443\u043b\u0434\u0430\u0443\u043d \u043b\u0435\u0447\u0435\u043d\u0438\u044f, \u0441\u0435\u043a", healSelf = "\u041b\u0435\u0447\u0438\u0442\u044c \u0441\u0435\u0431\u044f", healStop = "\u041e\u0441\u0442\u0430\u043d\u043e\u0432\u0438\u0442\u044c \u043b\u0435\u0447\u0435\u043d\u0438\u0435",
        forceVillain = "\u0421\u0442\u0430\u0442\u044c \u0437\u043b\u043e\u0434\u0435\u0435\u043c (\u0431\u0435\u0441\u043f\u043b\u0430\u0442\u043d\u043e)", reqRound = "\u0417\u0430\u043f\u0440\u043e\u0441\u0438\u0442\u044c \u0441\u043e\u0441\u0442\u043e\u044f\u043d\u0438\u0435 \u0440\u0430\u0443\u043d\u0434\u0430",
        phoneSpam = "\u0422\u0435\u043b\u0435\u0444\u043e\u043d: \u0441\u043f\u0430\u043c \u0437\u0430\u043f\u0438\u0441\u0438 \u043f\u043e \u0446\u0435\u043b\u0438", phoneStop = "\u0422\u0435\u043b\u0435\u0444\u043e\u043d: \u0441\u0442\u043e\u043f", hud = "\u041f\u043e\u043a\u0430\u0437\u044b\u0432\u0430\u0442\u044c HUD",
        language = "\u042f\u0437\u044b\u043a", espRate = "\u0418\u043d\u0442\u0435\u0440\u0432\u0430\u043b \u043e\u0431\u043d\u043e\u0432\u043b\u0435\u043d\u0438\u044f ESP, \u0441\u0435\u043a", unloadBtn = "\u0412\u044b\u0433\u0440\u0443\u0437\u0438\u0442\u044c \u0441\u043a\u0440\u0438\u043f\u0442",
        loaded = "\u0421\u043a\u0440\u0438\u043f\u0442 \u0437\u0430\u0433\u0440\u0443\u0436\u0435\u043d", langChanged = "\u042f\u0437\u044b\u043a \u0438\u0437\u043c\u0435\u043d\u0451\u043d", notFound = "\u041d\u0435 \u043d\u0430\u0439\u0434\u0435\u043d\u043e", unavailable = "\u041d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u043d\u043e",
        sent = "\u041e\u0442\u043f\u0440\u0430\u0432\u043b\u0435\u043d\u043e", taskDone = "\u0417\u0430\u0434\u0430\u043d\u0438\u0435 \u0432\u044b\u043f\u043e\u043b\u043d\u0435\u043d\u043e", taskFail = "\u0417\u0430\u0434\u0430\u043d\u0438\u0435 \u043f\u0440\u043e\u0432\u0430\u043b\u0435\u043d\u043e",
        hudState = "\u0421\u0422\u0410\u0422\u0423\u0421", hudTime = "\u0412\u0420\u0415\u041c\u042f", hudRole = "\u0420\u041e\u041b\u042c", hudChance = "\u0428\u0410\u041d\u0421", hudFilmed = "\u0422\u0415\u0411\u042f \u0421\u041d\u0418\u041c\u0410\u042e\u0422", hudHearing = "\u0421\u0423\u041f\u0415\u0420\u0421\u041b\u0423\u0425",
        villain = "\u0417\u041b\u041e\u0414\u0415\u0419", crate = "\u042f\u0429\u0418\u041a", tempv = "TEMP V", medkit = "\u0410\u041f\u0422\u0415\u0427\u041a\u0410", prompt = "\u0418\u041d\u0422\u0415\u0420\u0410\u041a\u0422\u0418\u0412",
    },
    en = {
        title = "HFTV Multi-Cheat v5", sub = "built from the game dump",
        tabVisuals = "Visuals", tabMove = "Movement", tabCombat = "Combat", tabFarm = "Farm", tabMisc = "Misc", tabSettings = "Settings",
        espPlayers = "Player ESP", espBox = "Highlight", espNames = "Names and states",
        espHP = "Show HP", espDist = "Show distance", tracers = "Tracers",
        espCrates = "Crate ESP", espLoot = "Loot ESP (Temp V / medkits)", espPrompts = "Interactable ESP",
        espMaxDist = "Max ESP distance", rescan = "Rescan map", cratesFound = "Crates found: ",
        infJump = "Infinite jump", ultraSpam = "Ultra jump spam (space)", ultraOnce = "Ultra jump (once)",
        ultraDelay = "Ultra jump delay, sec", speedOn = "Speed override", speedValue = "Speed",
        antiRagdoll = "Anti-ragdoll / anti-stun", antiSlow = "Anti-slow / anti-root",
        tpCrate = "TP: nearest crate", tpLoot = "TP: nearest loot", tpSpawn = "TP: survivor spawns", tpStore = "TP: tool store",
        player = "Player", refresh = "Refresh list", tpPlayer = "TP: to player",
        aimbot = "Aimbot (camera)", aimFov = "Aimbot FOV (pixels)", aimPart = "Aim part",
        autoPunch = "Auto SuperPunch", punchRate = "SuperPunch interval, sec", punchOnce = "SuperPunch (once)",
        autoDodge = "Auto-dodge abilities", dodgeCd = "Dodge cooldown, sec",
        skill = "Skill", skillUse = "Use skill", skillManual = "Manual skill key",
        autoTask = "Auto tasks", taskDelay = "Task delay, sec", autoPrompt = "Auto-open crates and prompts",
        promptCd = "Prompt cooldown, sec", autoHeal = "Auto heal", healThreshold = "Heal threshold, % HP",
        healCd = "Heal cooldown, sec", healSelf = "Heal self", healStop = "Stop healing",
        forceVillain = "Force villain (free)", reqRound = "Request round state",
        phoneSpam = "Phone: spam recording at target", phoneStop = "Phone: stop", hud = "Show HUD",
        language = "Language", espRate = "ESP refresh interval, sec", unloadBtn = "Unload script",
        loaded = "Script loaded", langChanged = "Language changed", notFound = "Not found", unavailable = "Unavailable",
        sent = "Sent", taskDone = "Task complete", taskFail = "Task failed",
        hudState = "STATE", hudTime = "TIME", hudRole = "ROLE", hudChance = "CHANCE", hudFilmed = "YOU ARE BEING FILMED", hudHearing = "SUPER HEARING",
        villain = "VILLAIN", crate = "CRATE", tempv = "TEMP V", medkit = "MEDKIT", prompt = "PROMPT",
    },
    es = {
        title = "HFTV Multi-Cheat v5", sub = "creado desde el volcado del juego",
        tabVisuals = "Visuales", tabMove = "Movimiento", tabCombat = "Combate", tabFarm = "Farmeo", tabMisc = "Varios", tabSettings = "Ajustes",
        espPlayers = "ESP de jugadores", espBox = "Resaltado", espNames = "Nombres y estados",
        espHP = "Mostrar vida", espDist = "Mostrar distancia", tracers = "Trazadores",
        espCrates = "ESP de cajas", espLoot = "ESP de bot\u00edn (Temp V / botiquines)", espPrompts = "ESP de interacciones",
        espMaxDist = "Distancia m\u00e1x. del ESP", rescan = "Reescanear el mapa", cratesFound = "Cajas encontradas: ",
        infJump = "Salto infinito", ultraSpam = "Spam de ultra salto (espacio)", ultraOnce = "Ultra salto (una vez)",
        ultraDelay = "Retardo del ultra salto, seg", speedOn = "Anular velocidad", speedValue = "Velocidad",
        antiRagdoll = "Anti-ragdoll / anti-aturdimiento", antiSlow = "Anti-ralentizaci\u00f3n / anti-ra\u00edz",
        tpCrate = "TP: caja m\u00e1s cercana", tpLoot = "TP: bot\u00edn m\u00e1s cercano", tpSpawn = "TP: aparici\u00f3n de supervivientes", tpStore = "TP: tienda de herramientas",
        player = "Jugador", refresh = "Actualizar lista", tpPlayer = "TP: al jugador",
        aimbot = "Aimbot (c\u00e1mara)", aimFov = "FOV del aimbot (p\u00edxeles)", aimPart = "Parte objetivo",
        autoPunch = "SuperPunch autom\u00e1tico", punchRate = "Intervalo de SuperPunch, seg", punchOnce = "SuperPunch (una vez)",
        autoDodge = "Esquiva autom\u00e1tica de habilidades", dodgeCd = "Enfriamiento de esquiva, seg",
        skill = "Habilidad", skillUse = "Usar habilidad", skillManual = "Clave manual de habilidad",
        autoTask = "Tareas autom\u00e1ticas", taskDelay = "Retardo de tarea, seg", autoPrompt = "Abrir cajas y prompts autom\u00e1ticamente",
        promptCd = "Enfriamiento del prompt, seg", autoHeal = "Curaci\u00f3n autom\u00e1tica", healThreshold = "Umbral de curaci\u00f3n, % vida",
        healCd = "Enfriamiento de curaci\u00f3n, seg", healSelf = "Curarme", healStop = "Detener curaci\u00f3n",
        forceVillain = "Forzar villano (gratis)", reqRound = "Solicitar estado de la ronda",
        phoneSpam = "Tel\u00e9fono: spam de grabaci\u00f3n al objetivo", phoneStop = "Tel\u00e9fono: detener", hud = "Mostrar HUD",
        language = "Idioma", espRate = "Intervalo de refresco del ESP, seg", unloadBtn = "Descargar script",
        loaded = "Script cargado", langChanged = "Idioma cambiado", notFound = "No encontrado", unavailable = "No disponible",
        sent = "Enviado", taskDone = "Tarea completada", taskFail = "Tarea fallida",
        hudState = "ESTADO", hudTime = "TIEMPO", hudRole = "ROL", hudChance = "PROBABILIDAD", hudFilmed = "TE EST\u00c1N GRABANDO", hudHearing = "S\u00daPER O\u00cdDO",
        villain = "VILLANO", crate = "CAJA", tempv = "TEMP V", medkit = "BOTIQU\u00cdN", prompt = "INTERACCI\u00d3N",
    },
}

local function L(key)
    local pack = T[S.lang] or T.ru
    return pack[key] or T.en[key] or key
end

local function isVillain(plr)
    local ch = plr.Character
    if ch and ch:FindFirstChild("VillainCostume") then return true end
    if plr.Team and plr.Team.Name == "Villain" then return true end
    if ch then
        local h = ch:FindFirstChildOfClass("Humanoid")
        if h and h.MaxHealth >= VILLAIN_HP - 1 then return true end
        if ch:GetAttribute("VillainMorph") or ch:GetAttribute("VillainUltraJump")
            or ch:GetAttribute("VillainWalkSpeed") then return true end
    end
    return false
end

onRemote("RoleReveal", function(role) if typeof(role) == "string" then Round.myRole = role end end)
onRemote("RoundState", function(state, timeLeft)
    if typeof(state) == "string" then Round.state = state end
    if typeof(timeLeft) == "number" then Round.endsAt = os.clock() + timeLeft end
end)
onRemote("RoundTimeSync", function(s) if typeof(s) == "number" then Round.endsAt = os.clock() + s end end)
onRemote("VillainChance", function(v) if typeof(v) == "number" then Round.chance = v end end)
onRemote("BeingFilmed", function(b) Watch.filmed = b and true or false end)
onRemote("SuperHearing", function() Watch.hearing = os.clock() + 3 end)
fire("RequestRoundState")

local gui = Instance.new("ScreenGui")
gui.Name = "HFTV_UI"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = CoreGui

local adornFolder = Instance.new("Folder")
adornFolder.Name = "HFTV_Adorn"
adornFolder.Parent = CoreGui

local hudLbl = Instance.new("TextLabel", gui)
hudLbl.AnchorPoint = Vector2.new(0.5, 0)
hudLbl.Position = UDim2.new(0.5, 0, 0, 6)
hudLbl.Size = UDim2.fromOffset(780, 44)
hudLbl.BackgroundTransparency = 1
hudLbl.TextColor3 = Color3.new(1, 1, 1)
hudLbl.TextStrokeTransparency = 0.3
hudLbl.TextSize = 16
hudLbl.Font = Enum.Font.GothamBold
hudLbl.RichText = true

local entries = {}
local function makeEntry()
    local hl = Instance.new("Highlight")
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.FillTransparency = 0.7
    hl.Parent = adornFolder

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.fromOffset(250, 44)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = adornFolder

    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.TextSize = 14
    lbl.Font = Enum.Font.GothamBold
    lbl.TextStrokeTransparency = 0.3

    local line = Instance.new("Frame", gui)
    line.BorderSizePixel = 0
    line.AnchorPoint = Vector2.new(0.5, 0)
    line.Visible = false

    return { hl = hl, bb = bb, lbl = lbl, line = line }
end

Players.PlayerRemoving:Connect(function(p)
    local e = entries[p]
    if e then e.hl:Destroy() e.bb:Destroy() e.line:Destroy() entries[p] = nil end
end)

local STATE_ATTRS = { "AbilityActive", "Stunned", "Grabbed", "Ragdolled", "Slammed", "Rooted", "Cloaked", "Shrunk", "Hyperarmor" }

local function updateESP()
    local c = cam()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local e = entries[plr]
            if not e then e = makeEntry() entries[plr] = e end
            local ch = plr.Character
            local hrpPart = ch and ch:FindFirstChild("HumanoidRootPart")
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            local dist = (c and hrpPart) and (c.CFrame.Position - hrpPart.Position).Magnitude or math.huge
            local show = S.espPlayers and hrpPart and hum and hum.Health > 0 and c and dist <= S.espMaxDist

            e.hl.Enabled = (show and S.espBox) or false
            e.bb.Enabled = (show and S.espNames) or false
            e.line.Visible = false

            if show then
                local vil = isVillain(plr)
                local col = vil and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(80, 255, 120)
                e.hl.Adornee = ch
                e.hl.FillColor = col
                e.hl.OutlineColor = col
                e.bb.Adornee = hrpPart

                local parts = { plr.Name }
                if vil then table.insert(parts, L("villain")) end
                if S.espHP then table.insert(parts, math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) end
                if S.espDist then table.insert(parts, math.floor(dist) .. "m") end
                local flags = {}
                for _, a in ipairs(STATE_ATTRS) do
                    if ch:GetAttribute(a) then table.insert(flags, a) end
                end
                if #flags > 0 then table.insert(parts, table.concat(flags, ",")) end
                e.lbl.Text = table.concat(parts, " | ")
                e.lbl.TextColor3 = col

                if S.tracers then
                    local sp, on = c:WorldToViewportPoint(hrpPart.Position)
                    if on then
                        local o = Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y)
                        local t = Vector2.new(sp.X, sp.Y)
                        local d = t - o
                        e.line.Visible = true
                        e.line.BackgroundColor3 = col
                        e.line.Size = UDim2.fromOffset(1, d.Magnitude)
                        e.line.Position = UDim2.fromOffset((o.X + t.X) / 2, (o.Y + t.Y) / 2)
                        e.line.Rotation = math.deg(math.atan2(d.Y, d.X)) - 90
                    end
                end
            end
        end
    end
end

local tags = {}
local tracked = { loot = {}, crate = {}, prompt = {} }

local function partOf(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then
        return inst.PrimaryPart or inst:FindFirstChild("Center") or inst:FindFirstChildWhichIsA("BasePart")
    end
    return inst:FindFirstChildWhichIsA("BasePart", true)
end

local function tagInst(inst, key, color)
    local existing = tags[inst]
    if existing then
        existing.label.Text = L(key)
        existing.gui.MaxDistance = S.espMaxDist
        return
    end
    local base = partOf(inst)
    if not base then return end
    local bb = Instance.new("BillboardGui")
    bb.Adornee = base
    bb.Size = UDim2.fromOffset(160, 20)
    bb.AlwaysOnTop = true
    bb.MaxDistance = S.espMaxDist
    bb.Parent = adornFolder
    local l = Instance.new("TextLabel", bb)
    l.Size = UDim2.fromScale(1, 1)
    l.BackgroundTransparency = 1
    l.TextColor3 = color
    l.TextSize = 13
    l.Font = Enum.Font.GothamBold
    l.TextStrokeTransparency = 0.4
    l.Text = L(key)
    tags[inst] = { gui = bb, label = l }
end

local function untag(inst)
    local t = tags[inst]
    if t then t.gui:Destroy() tags[inst] = nil end
end

local function isCrate(inst)
    if inst.Name == "VoughtCrate" then return true end
    if inst.Parent and inst.Parent.Name == "CrateSpawns" then return true end
    local ok, has = pcall(function() return CollectionService:HasTag(inst, "Crate") end)
    if ok and has then return true end
    local p = inst:FindFirstChildWhichIsA("ProximityPrompt", true)
    if p and p.ObjectText:upper() == "CRATE" then return true end
    return false
end

local function classify(d)
    if d.Name == "TempVPickup" then
        tracked.loot[d] = "tempv"
    elseif d.Name == "MedkitPickup" then
        tracked.loot[d] = "medkit"
    elseif d:IsA("Model") and isCrate(d) then
        tracked.crate[d] = "crate"
    elseif d:IsA("ProximityPrompt") then
        local host = d.Parent
        if host then
            if host:IsA("Model") and isCrate(host) then
                tracked.crate[host] = "crate"
            else
                tracked.prompt[d] = "prompt"
            end
        end
    end
end

task.spawn(function()
    for _, d in ipairs(Workspace:GetDescendants()) do pcall(classify, d) end
end)
Workspace.DescendantAdded:Connect(function(d) task.defer(function() pcall(classify, d) end) end)
Workspace.DescendantRemoving:Connect(function(d)
    untag(d)
    tracked.loot[d] = nil
    tracked.crate[d] = nil
    tracked.prompt[d] = nil
end)

local function refreshWorldESP()
    local sets = {
        { on = S.espLoot, set = tracked.loot, col = Color3.fromRGB(120, 200, 255) },
        { on = S.espCrates, set = tracked.crate, col = Color3.fromRGB(255, 120, 220) },
        { on = S.espPrompts, set = tracked.prompt, col = Color3.fromRGB(255, 220, 110) },
    }
    for _, g in ipairs(sets) do
        for inst, key in pairs(g.set) do
            local host = inst:IsA("ProximityPrompt") and inst.Parent or inst
            if not inst.Parent then
                untag(host)
                g.set[inst] = nil
            elseif g.on then
                tagInst(host, key, g.col)
            else
                untag(host)
            end
        end
    end
end

local function updateHUD()
    local left = math.max(0, Round.endsAt - os.clock())
    local bits = {
        L("hudState") .. ": " .. Round.state,
        ("%s: %d:%02d"):format(L("hudTime"), left / 60, left % 60),
        L("hudRole") .. ": " .. Round.myRole,
    }
    if Round.chance then table.insert(bits, ("%s: %.1f%%"):format(L("hudChance"), Round.chance)) end
    if Watch.filmed then table.insert(bits, "<font color='#ff5555'>" .. L("hudFilmed") .. "</font>") end
    if os.clock() < Watch.hearing then table.insert(bits, "<font color='#ffaa00'>" .. L("hudHearing") .. "</font>") end
    hudLbl.Text = table.concat(bits, "   |   ")
end

local function char() return LocalPlayer.Character end
local function hum() local c = char() return c and c:FindFirstChildOfClass("Humanoid") end
local function hrp() local c = char() return c and c:FindFirstChild("HumanoidRootPart") end

UserInputService.JumpRequest:Connect(function()
    if S.infJump then
        local h = hum()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

local lastUltra = 0
local function ultraJump()
    if os.clock() - lastUltra < S.ultraDelay then return end
    lastUltra = os.clock()
    local root = hrp()
    if not root then return end
    local v = root.AssemblyLinearVelocity
    root.AssemblyLinearVelocity = Vector3.new(v.X, ULTRA_JUMP_VEL, v.Z)
end

local function applyStateLocks(on)
    local h = hum()
    if not h then return end
    for _, st in ipairs({ Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.Physics }) do
        pcall(function() h:SetStateEnabled(st, not on) end)
    end
end

local lastAntiRag, lastAttrClear = 0, 0
local function antiRagdollStep()
    local c, h = char(), hum()
    if not (c and h) then return end
    if os.clock() - lastAntiRag > 0.4 then
        local st = h:GetState()
        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.FallingDown then
            lastAntiRag = os.clock()
            h:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end
    if os.clock() - lastAttrClear > 0.25 then
        lastAttrClear = os.clock()
        for _, a in ipairs({ "Ragdolled", "Grabbed", "Stunned", "Slammed" }) do
            if c:GetAttribute(a) ~= nil then c:SetAttribute(a, nil) end
        end
    end
end

local lastSlowClear = 0
local function antiSlowStep()
    local c, h = char(), hum()
    if not (c and h) then return end
    if os.clock() - lastSlowClear > 0.25 then
        lastSlowClear = os.clock()
        for k in pairs(c:GetAttributes()) do
            local p = k:sub(1, 5)
            if p == "Slow_" or p == "Root_" then c:SetAttribute(k, nil) end
        end
        if c:GetAttribute("Slowed") ~= nil then c:SetAttribute("Slowed", nil) end
        if c:GetAttribute("Rooted") ~= nil then c:SetAttribute("Rooted", nil) end
    end
    if h.WalkSpeed < WALK_SPEED - 0.5 then h.WalkSpeed = WALK_SPEED end
end

local function speedStep()
    if not S.speedOn then return end
    local h = hum()
    if h and math.abs(h.WalkSpeed - S.speedValue) > 0.5 then h.WalkSpeed = S.speedValue end
end

local function tpTo(pos)
    local root = hrp()
    if root then root.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end
end

local function findFirstNamed(name)
    for _, d in ipairs(Workspace:GetDescendants()) do
        if d.Name == name then return d end
    end
end

local function pivotOf(inst)
    if inst:IsA("BasePart") then return inst.Position end
    if inst:IsA("Model") then return inst:GetPivot().Position end
    local p = inst:FindFirstChildWhichIsA("BasePart", true)
    return p and p.Position
end

local function nearestFrom(set)
    local root = hrp()
    if not root then return nil end
    local best, bd
    for inst in pairs(set) do
        local p = inst.Parent and pivotOf(inst)
        if p then
            local d = (p - root.Position).Magnitude
            if not bd or d < bd then best, bd = p, d end
        end
    end
    return best
end

local function superPunch() return fire("SuperPunch") end
local function activateSkill(k, m) return fire("ActivateSkill", k, m or "tap") end

local skillKeys = {}
do
    local seen = {}
    local function collect(tbl, depth)
        if type(tbl) ~= "table" or depth > 3 then return end
        for k, v in pairs(tbl) do
            if type(k) == "string" and type(v) == "table" and not seen[k] then
                if v.Cooldown or v.Name or v.Key or v.Type then
                    seen[k] = true
                    table.insert(skillKeys, k)
                end
                collect(v, depth + 1)
            end
        end
    end
    pcall(collect, SkillConfig, 1)
    table.sort(skillKeys)
end

local function nearestTarget()
    local c = cam()
    if not c then return nil end
    local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local part = plr.Character:FindFirstChild(S.aimPart) or plr.Character:FindFirstChild("HumanoidRootPart")
            local h = plr.Character:FindFirstChildOfClass("Humanoid")
            if part and h and h.Health > 0 then
                local sp, on = c:WorldToViewportPoint(part.Position)
                if on then
                    local d = (Vector2.new(sp.X, sp.Y) - c.ViewportSize / 2).Magnitude
                    if d < S.aimFov and d < bestD then best, bestD = part, d end
                end
            end
        end
    end
    return best
end

local function aimbotStep()
    if not S.aimbot then return end
    local c, t = cam(), nearestTarget()
    if c and t then c.CFrame = CFrame.new(c.CFrame.Position, t.Position) end
end

local dodgeRemotes = {}
for _, n in ipairs({ "KingOfCursesDash", "SoldierBoyCharge", "ATrainHit", "ATrainDash", "HomelanderLaser", "FlightFX" }) do
    if R(n) then table.insert(dodgeRemotes, n) end
end

local lastDodge = 0
for _, n in ipairs(dodgeRemotes) do
    onRemote(n, function()
        if not S.autoDodge or os.clock() - lastDodge < S.dodgeCooldown then return end
        lastDodge = os.clock()
        local root = hrp()
        if not root then return end
        root.AssemblyLinearVelocity = root.CFrame.RightVector * 28 + Vector3.new(0, 22, 0)
    end)
end

local notify
onRemote("TaskStart", function(token)
    if not S.autoTask or not token then return end
    if S.taskDelay <= 0 then
        fire("TaskComplete", token)
    else
        task.delay(S.taskDelay, function() fire("TaskComplete", token) end)
    end
end)
onRemote("TaskResult", function(ok, rew)
    if S.autoTask and notify then
        local extra = (rew and rew.Money) and (" +" .. rew.Money .. " V") or ""
        notify(ok and (L("taskDone") .. extra) or L("taskFail"))
    end
end)

local promptCd = {}
local function autoPromptStep()
    if not S.autoPrompt then return end
    local root = hrp()
    if not root then return end
    local now = os.clock()
    local function tryPrompt(p, host)
        if not (p and p.Parent and p.Enabled) then return end
        if (promptCd[p] or 0) >= now then return end
        local base = partOf(host)
        if base and (base.Position - root.Position).Magnitude <= math.max(p.MaxActivationDistance, 12) then
            promptCd[p] = now + S.promptCooldown
            pcall(function() fireproximityprompt(p) end)
        end
    end
    for p in pairs(tracked.prompt) do tryPrompt(p, p.Parent) end
    for c in pairs(tracked.crate) do
        if c.Parent then tryPrompt(c:FindFirstChildWhichIsA("ProximityPrompt", true), c) end
    end
end

local function healSelf() return fire("HealChannel", "self") end
local function healStop() return fire("HealChannel", "stop") end

local lastHeal = 0
local function autoHealStep()
    if not S.autoHeal then return end
    local h = hum()
    if not h or h.Health <= 0 then return end
    if h.Health / math.max(1, h.MaxHealth) * 100 <= S.healThreshold and os.clock() - lastHeal > S.healCooldown then
        lastHeal = os.clock()
        healSelf()
    end
end

local function forceVillainFree()
    if not R("ForceVillainFree") then return false end
    return fire("ForceVillainFree")
end

local function phoneRecordAt(target)
    local root = hrp()
    if not root then return false end
    local look = root.CFrame.LookVector
    local tr = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if tr then look = (tr.Position - root.Position).Unit end
    return fire("PhoneRecord", true, look)
end

local function playerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(t, p.Name) end
    end
    return t
end

local okUI, Rayfield = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
if not okUI or not Rayfield then warn("[HFTV] Rayfield failed to load") return end

notify = function(msg)
    pcall(function() Rayfield:Notify({ Title = "HFTV", Content = msg or "", Duration = 3 }) end)
end

local running = true
local selectedSkill = skillKeys[1]
local buildUI

buildUI = function()
    local Window = Rayfield:CreateWindow({
        Name = L("title"),
        LoadingTitle = "Hide From The Villain",
        LoadingSubtitle = L("sub"),
        ConfigurationSaving = { Enabled = false },
        KeySystem = false,
    })

    local TabVis = Window:CreateTab(L("tabVisuals"), 4483362458)
    local TabMove = Window:CreateTab(L("tabMove"), 4483362458)
    local TabComb = Window:CreateTab(L("tabCombat"), 4483362458)
    local TabFarm = Window:CreateTab(L("tabFarm"), 4483362458)
    local TabMisc = Window:CreateTab(L("tabMisc"), 4483362458)
    local TabSet = Window:CreateTab(L("tabSettings"), 4483362458)

    TabVis:CreateToggle({ Name = L("espPlayers"), CurrentValue = S.espPlayers, Callback = function(v) S.espPlayers = v end })
    TabVis:CreateToggle({ Name = L("espBox"), CurrentValue = S.espBox, Callback = function(v) S.espBox = v end })
    TabVis:CreateToggle({ Name = L("espNames"), CurrentValue = S.espNames, Callback = function(v) S.espNames = v end })
    TabVis:CreateToggle({ Name = L("espHP"), CurrentValue = S.espHP, Callback = function(v) S.espHP = v end })
    TabVis:CreateToggle({ Name = L("espDist"), CurrentValue = S.espDist, Callback = function(v) S.espDist = v end })
    TabVis:CreateToggle({ Name = L("tracers"), CurrentValue = S.tracers, Callback = function(v) S.tracers = v end })
    TabVis:CreateToggle({ Name = L("espCrates"), CurrentValue = S.espCrates, Callback = function(v) S.espCrates = v refreshWorldESP() end })
    TabVis:CreateToggle({ Name = L("espLoot"), CurrentValue = S.espLoot, Callback = function(v) S.espLoot = v refreshWorldESP() end })
    TabVis:CreateToggle({ Name = L("espPrompts"), CurrentValue = S.espPrompts, Callback = function(v) S.espPrompts = v refreshWorldESP() end })
    TabVis:CreateSlider({ Name = L("espMaxDist"), Range = { 50, 2000 }, Increment = 50, CurrentValue = S.espMaxDist, Callback = function(v) S.espMaxDist = v end })
    TabVis:CreateButton({ Name = L("rescan"), Callback = function()
        for _, d in ipairs(Workspace:GetDescendants()) do pcall(classify, d) end
        refreshWorldESP()
        local n = 0
        for _ in pairs(tracked.crate) do n = n + 1 end
        notify(L("cratesFound") .. n)
    end })

    TabMove:CreateToggle({ Name = L("infJump"), CurrentValue = S.infJump, Callback = function(v) S.infJump = v end })
    TabMove:CreateToggle({ Name = L("ultraSpam"), CurrentValue = S.ultraJumpSpam, Callback = function(v) S.ultraJumpSpam = v end })
    TabMove:CreateButton({ Name = L("ultraOnce"), Callback = ultraJump })
    TabMove:CreateSlider({ Name = L("ultraDelay"), Range = { 0, 1 }, Increment = 0.05, CurrentValue = S.ultraDelay, Callback = function(v) S.ultraDelay = v end })
    TabMove:CreateToggle({ Name = L("speedOn"), CurrentValue = S.speedOn, Callback = function(v)
        S.speedOn = v
        if not v then
            local h = hum()
            if h then h.WalkSpeed = WALK_SPEED end
        end
    end })
    TabMove:CreateSlider({ Name = L("speedValue"), Range = { 16, 400 }, Increment = 2, CurrentValue = S.speedValue, Callback = function(v) S.speedValue = v end })
    TabMove:CreateToggle({ Name = L("antiRagdoll"), CurrentValue = S.antiRagdoll, Callback = function(v) S.antiRagdoll = v applyStateLocks(v) end })
    TabMove:CreateToggle({ Name = L("antiSlow"), CurrentValue = S.antiSlow, Callback = function(v) S.antiSlow = v end })
    TabMove:CreateButton({ Name = L("tpCrate"), Callback = function()
        local p = nearestFrom(tracked.crate)
        if p then tpTo(p) else notify(L("notFound")) end
    end })
    TabMove:CreateButton({ Name = L("tpLoot"), Callback = function()
        local p = nearestFrom(tracked.loot)
        if p then tpTo(p) else notify(L("notFound")) end
    end })
    TabMove:CreateButton({ Name = L("tpSpawn"), Callback = function()
        local f = findFirstNamed("SurvivorSpawns")
        local p = f and pivotOf(f)
        if p then tpTo(p) else notify(L("notFound")) end
    end })
    TabMove:CreateButton({ Name = L("tpStore"), Callback = function()
        local f = findFirstNamed("ToolStore")
        local p = f and pivotOf(f)
        if p then tpTo(p) else notify(L("notFound")) end
    end })
    local tpDrop = TabMove:CreateDropdown({ Name = L("player"), Options = playerNames(), CurrentOption = {}, MultipleOptions = false,
        Callback = function(o) tpTargetName = (typeof(o) == "table" and o[1]) or o end })
    TabMove:CreateButton({ Name = L("refresh"), Callback = function()
        pcall(function() tpDrop:Refresh(playerNames()) end)
    end })
    TabMove:CreateButton({ Name = L("tpPlayer"), Callback = function()
        local p = tpTargetName and Players:FindFirstChild(tpTargetName)
        local r = p and p.Character and p.Character:FindFirstChild("HumanoidRootPart")
        if r then tpTo(r.Position + r.CFrame.LookVector * 4) else notify(L("notFound")) end
    end })

    TabComb:CreateToggle({ Name = L("aimbot"), CurrentValue = S.aimbot, Callback = function(v) S.aimbot = v end })
    TabComb:CreateSlider({ Name = L("aimFov"), Range = { 40, 900 }, Increment = 10, CurrentValue = S.aimFov, Callback = function(v) S.aimFov = v end })
    TabComb:CreateDropdown({ Name = L("aimPart"), Options = { "Head", "HumanoidRootPart", "UpperTorso", "Torso" }, CurrentOption = { S.aimPart }, MultipleOptions = false,
        Callback = function(o) S.aimPart = (typeof(o) == "table" and o[1]) or o end })
    TabComb:CreateToggle({ Name = L("autoPunch"), CurrentValue = S.autoPunch, Callback = function(v) S.autoPunch = v end })
    TabComb:CreateSlider({ Name = L("punchRate"), Range = { 0.05, 2 }, Increment = 0.05, CurrentValue = S.punchRate, Callback = function(v) S.punchRate = v end })
    TabComb:CreateButton({ Name = L("punchOnce"), Callback = function()
        if not superPunch() then notify(L("unavailable")) end
    end })
    TabComb:CreateToggle({ Name = L("autoDodge"), CurrentValue = S.autoDodge, Callback = function(v)
        if #dodgeRemotes == 0 then notify(L("unavailable")) end
        S.autoDodge = v
    end })
    TabComb:CreateSlider({ Name = L("dodgeCd"), Range = { 0, 2 }, Increment = 0.1, CurrentValue = S.dodgeCooldown, Callback = function(v) S.dodgeCooldown = v end })
    if #skillKeys > 0 then
        TabComb:CreateDropdown({ Name = L("skill"), Options = skillKeys, CurrentOption = { selectedSkill }, MultipleOptions = false,
            Callback = function(o) selectedSkill = (typeof(o) == "table" and o[1]) or o end })
        TabComb:CreateButton({ Name = L("skillUse"), Callback = function()
            if selectedSkill then activateSkill(selectedSkill, "tap") end
        end })
    end
    TabComb:CreateInput({ Name = L("skillManual"), PlaceholderText = "skill key", RemoveTextAfterFocusLost = false,
        Callback = function(t) if t and t ~= "" then activateSkill(t, "tap") end end })

    TabFarm:CreateToggle({ Name = L("autoTask"), CurrentValue = S.autoTask, Callback = function(v) S.autoTask = v end })
    TabFarm:CreateSlider({ Name = L("taskDelay"), Range = { 0, 5 }, Increment = 0.25, CurrentValue = S.taskDelay, Callback = function(v) S.taskDelay = v end })
    TabFarm:CreateToggle({ Name = L("autoPrompt"), CurrentValue = S.autoPrompt, Callback = function(v) S.autoPrompt = v end })
    TabFarm:CreateSlider({ Name = L("promptCd"), Range = { 0.1, 3 }, Increment = 0.1, CurrentValue = S.promptCooldown, Callback = function(v) S.promptCooldown = v end })
    TabFarm:CreateToggle({ Name = L("autoHeal"), CurrentValue = S.autoHeal, Callback = function(v) S.autoHeal = v end })
    TabFarm:CreateSlider({ Name = L("healThreshold"), Range = { 10, 100 }, Increment = 5, CurrentValue = S.healThreshold, Callback = function(v) S.healThreshold = v end })
    TabFarm:CreateSlider({ Name = L("healCd"), Range = { 0.5, 10 }, Increment = 0.5, CurrentValue = S.healCooldown, Callback = function(v) S.healCooldown = v end })
    TabFarm:CreateButton({ Name = L("healSelf"), Callback = function()
        if not healSelf() then notify(L("unavailable")) end
    end })
    TabFarm:CreateButton({ Name = L("healStop"), Callback = healStop })

    TabMisc:CreateButton({ Name = L("forceVillain"), Callback = function()
        notify(forceVillainFree() and L("sent") or L("unavailable"))
    end })
    TabMisc:CreateButton({ Name = L("reqRound"), Callback = function() fire("RequestRoundState") end })
    TabMisc:CreateToggle({ Name = L("phoneSpam"), CurrentValue = S.phoneSpam, Callback = function(v) S.phoneSpam = v end })
    TabMisc:CreateButton({ Name = L("phoneStop"), Callback = function()
        local root = hrp()
        fire("PhoneRecord", false, root and root.CFrame.LookVector or Vector3.zero)
    end })
    TabMisc:CreateToggle({ Name = L("hud"), CurrentValue = S.hudVisible, Callback = function(v)
        S.hudVisible = v
        hudLbl.Visible = v
    end })

    local langOptions = {}
    for _, code in ipairs(LANGS) do table.insert(langOptions, LANG_LABEL[code]) end
    TabSet:CreateDropdown({ Name = L("language"), Options = langOptions, CurrentOption = { LANG_LABEL[S.lang] }, MultipleOptions = false,
        Callback = function(o)
            local label = (typeof(o) == "table" and o[1]) or o
            local newLang = S.lang
            for _, code in ipairs(LANGS) do
                if LANG_LABEL[code] == label then newLang = code end
            end
            if newLang == S.lang then return end
            S.lang = newLang
            task.defer(function()
                pcall(function() Rayfield:Destroy() end)
                task.wait(0.15)
                local ok2, rf = pcall(function() return loadstring(game:HttpGet("https://sirius.menu/rayfield"))() end)
                if ok2 and rf then Rayfield = rf end
                for inst in pairs(tags) do untag(inst) end
                buildUI()
                refreshWorldESP()
                notify(L("langChanged"))
            end)
        end })
    TabSet:CreateSlider({ Name = L("espRate"), Range = { 0.05, 1 }, Increment = 0.05, CurrentValue = S.espRate, Callback = function(v) S.espRate = v end })
    TabSet:CreateButton({ Name = L("unloadBtn"), Callback = function()
        running = false
        for _, e in pairs(entries) do
            pcall(function() e.hl:Destroy() e.bb:Destroy() e.line:Destroy() end)
        end
        for inst in pairs(tags) do untag(inst) end
        pcall(function() adornFolder:Destroy() end)
        pcall(function() gui:Destroy() end)
        pcall(function() Rayfield:Destroy() end)
    end })
end

buildUI()

task.spawn(function()
    while running do
        pcall(updateESP)
        pcall(updateHUD)
        task.wait(S.espRate)
    end
end)

task.spawn(function()
    while running do
        pcall(refreshWorldESP)
        task.wait(1)
    end
end)

task.spawn(function()
    while running do
        pcall(autoPromptStep)
        pcall(autoHealStep)
        if S.phoneSpam then
            pcall(phoneRecordAt, tpTargetName and Players:FindFirstChild(tpTargetName))
        end
        task.wait(0.25)
    end
end)

task.spawn(function()
    while running do
        if S.autoPunch then pcall(superPunch) end
        task.wait(S.punchRate)
    end
end)

RunService.RenderStepped:Connect(function()
    if not running then return end
    if S.antiRagdoll then pcall(antiRagdollStep) end
    if S.antiSlow then pcall(antiSlowStep) end
    pcall(speedStep)
    pcall(aimbotStep)
    if S.ultraJumpSpam and UserInputService:IsKeyDown(Enum.KeyCode.Space) then pcall(ultraJump) end
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    if S.antiRagdoll then applyStateLocks(true) end
    fire("RequestRoundState")
end)

notify(L("loaded"))
