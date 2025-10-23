local module = {}

module.PlayerPermission = {
    ["SkrapitBP6688"] = {PlayerTier = 2000};
    ["GIqTXvPQArG"] = {PlayerTier = 2000};
    ["Srmarvillar"] = {PlayerTier = 2000};
    ["nicolasmotaflore"] = {PlayerTier = 2000};
    ["paulo1521cessara"] = {PlayerTier = 2000};
    ["Itachi134681"] = {PlayerTier = 2000};
    ["ojapones63"] = {PlayerTier = 1};
    ["AnnaSpeedNoCb"] = {PlayerTier = 2000};
    [""] = {PlayerTier = 2000};
}

module.Characters = {
    ["Eren"] = {Tier = 2, PlayersPermission =
        {4334947706, }
        ,Icon = 100553756186052};
    ["Gojo2"] = {Tier = 1, PlayersPermission = 
        {}
        ,Icon = 15920890769};
    ["JP6"] = {Tier = 2, PlayersPermission = 
        {}
        ,Icon = 1818649418};
    ["Diavolo"] = {Tier = 2, PlayersPermission = 
        {}
        ,Icon = 6283115481};
    ["Gojo"] = {Tier = 1, PlayersPermission = 
        {}
        ,Icon = 8088264406};
    ["Hakaishin"] = {Tier = 1, PlayersPermission = 
        {}
        ,Icon = 110853103107286};
    ["Itachi"] = {Tier = 1, PlayersPermission = 
        {}
        ,Icon = 7102727200};
    ["Sung"] = {Tier = 1000, PlayersPermission = 
        {}
        ,Icon = 18222356419};
}

module.TrocarPersonagem = function (args)
    local Parent = script.Parent
    local Event = game.ReplicatedStorage:WaitForChild("ChangeCharacter")
    Event:FireServer({char = args.char, Permission = module.Characters[args.char], PlayerTier = module.PlayerPermission, Player = args.Player})
    
    Parent.Parent.Visible = false
end

return module
