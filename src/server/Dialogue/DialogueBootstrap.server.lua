--!strict
-- Titik masuk sistem dialog NPC (server).

local DialogueService = require(script.Parent.DialogueService)
local NPCRegistry = require(script.Parent.NPCRegistry)

DialogueService.Start(NPCRegistry)
