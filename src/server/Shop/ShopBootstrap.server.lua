--!strict
-- Titik masuk sistem Shop (server). Urutan: mata uang dulu, baru toko.

local CurrencyService = require(script.Parent.Parent.Economy.CurrencyService)
local ShopService = require(script.Parent.ShopService)

CurrencyService.Start()
ShopService.Start()
