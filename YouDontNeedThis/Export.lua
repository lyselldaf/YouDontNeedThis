-- You Don't Need This - seed data exporter
-- Copyright (C) 2026 Nick. Licensed under the GNU GPL v3 or later; see LICENSE.md.
--
-- Developer tool. `/ydnt export` walks the QuestieDB addon's database (LibQuestieDB, with all of
-- its corrections applied, exactly as Questie sees it) and saves every item -> quest link to the
-- account-wide saved variable YDNT_Export. After logging out, tools/Build-SeedData.ps1 turns that
-- saved variable into SeedData.lua. Players never need to run this.

local _, ns = ...

local CHUNK = 250 -- entities per frame, so the export never hits the script time limit

local function Lib()
    local L = LibQuestieDB
    if type(L) == "table" and L.Quest and L.Quest.Get and L.Quest.GetAllIds then return L end
end

local function HasFlag(mask, flag)
    -- Arithmetic instead of bit.band: Forever race masks use bits above 32.
    return mask % (2 * flag) >= flag
end

-- Repeatable, daily and weekly quests never stay "completed", so an item linked to one
-- could never be flagged. Leave them out.
local function IsRepeatable(Q, qid)
    if HasFlag(Q.Get(qid, "specialFlags") or 0, 1) then return true end
    local flags = Q.Get(qid, "questFlags") or 0
    return HasFlag(flags, 4096) or HasFlag(flags, 32768)
end

-- Runs fn(id) over ids, CHUNK per frame, then calls done().
local function Walk(ids, fn, done)
    local i = 0
    local function step()
        local stop = math.min(i + CHUNK, #ids)
        for k = i + 1, stop do
            local ok, err = pcall(fn, ids[k])
            if not ok then ns.exportErrors = (ns.exportErrors or 0) + 1; ns.lastExportError = err end
        end
        i = stop
        if i < #ids then C_Timer.After(0, step) else done() end
    end
    step()
end

local running = false

function ns.ExportSeed(print)
    local L = Lib()
    if not L then
        print("export needs the QuestieDB addon (installed with Questie) to be loaded.")
        return
    end
    if running then print("export already running.") return end
    running = true
    ns.exportErrors, ns.lastExportError = 0, nil

    local Q = L.Quest
    local items, quests = {}, {}
    local itemCount, questCount = 0, 0

    local function Link(itemID, qid)
        if type(itemID) ~= "number" or itemID <= 0 then return end
        if not quests[qid] then
            quests[qid] = { Q.Get(qid, "name") or "", Q.Get(qid, "requiredRaces") or 0, Q.Get(qid, "requiredClasses") or 0 }
            questCount = questCount + 1
        end
        local list = items[itemID]
        if not list then list = {}; items[itemID] = list; itemCount = itemCount + 1 end
        for _, existing in ipairs(list) do if existing == qid then return end end
        list[#list + 1] = qid
    end

    local function FromQuest(qid)
        if IsRepeatable(Q, qid) then return end
        local objectives = Q.Get(qid, "objectives")
        if objectives and objectives[3] then
            for _, obj in pairs(objectives[3]) do
                if type(obj) == "table" then Link(obj[1], qid) end
            end
        end
        for _, itemID in pairs(Q.Get(qid, "requiredSourceItems") or {}) do Link(itemID, qid) end
        Link(Q.Get(qid, "sourceItemId"), qid) -- item handed to you when you accept the quest
    end

    local function FromItem(itemID)
        local qid = L.Item.Get(itemID, "startQuest") -- item that starts a quest
        if qid and qid > 0 and Q.Exists(qid) and not IsRepeatable(Q, qid) then Link(itemID, qid) end
    end

    print("exporting from QuestieDB... (this takes a few seconds)")
    Walk(Q.GetAllIds(), FromQuest, function()
        local itemIDs = (L.Item and L.Item.Get and L.Item.GetAllIds) and L.Item.GetAllIds() or {}
        Walk(itemIDs, FromItem, function()
            local raceMask = {}
            for raceID, mask in pairs((L.Enum and L.Enum.raceMaskById) or {}) do raceMask[raceID] = mask end

            -- Quests Questie hides as unobtainable (its blacklist lives in Questie, not QuestieDB).
            -- Value true = hidden; the string "HIDE_ON_MAP" = obtainable, just not drawn on the map.
            local hidden, hiddenCount = {}, 0
            local corrections = QuestieLoader and QuestieLoader.ImportModule
                and QuestieLoader:ImportModule("QuestieCorrections")
            for qid, value in pairs((corrections and corrections.hiddenQuests) or {}) do
                if value == true and quests[qid] then hidden[qid] = true; hiddenCount = hiddenCount + 1 end
            end
            if not (corrections and corrections.hiddenQuests) then
                print("note: Questie's quest blacklist wasn't found (is Questie enabled?), so no quests are marked unavailable.")
            end

            local GetMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
            local version, build = GetBuildInfo()
            YDNT_Export = {
                meta = {
                    source = "QuestieDB " .. tostring(GetMeta and GetMeta("QuestieDB", "Version") or "?")
                        .. " (contract " .. tostring(L.contractVersion) .. ")",
                    client = tostring(version) .. "." .. tostring(build),
                    date = date("%Y-%m-%d"),
                    items = itemCount,
                    quests = questCount,
                    hidden = hiddenCount,
                },
                items = items,
                quests = quests,
                raceMask = raceMask,
                hidden = hidden,
            }
            running = false
            print(("export done: %d items linked to %d quests (%d unavailable)%s. Log out (or /reload) to write the file, then run tools/Build-SeedData.ps1.")
                :format(itemCount, questCount, hiddenCount,
                    ns.exportErrors > 0 and (", " .. ns.exportErrors .. " errors, last: " .. tostring(ns.lastExportError)) or ""))
        end)
    end)
end
