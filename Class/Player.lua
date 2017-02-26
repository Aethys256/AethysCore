--- ============== HEADER ==============
  -- Addon
  local addonName, AC = ...;
  -- AethysCore
  local Cache = AethysCore_Cache;
  local Unit = AC.Unit;
  local Player = Unit.Player;
  local Target = Unit.Target;
  local Spell = AC.Spell;
  local Item = AC.Item;
  -- Lua
  local pairs = pairs;
  local select = select;
  local tostring = tostring;
  -- File Locals
  


--- ============== CONTENT ==============
  -- Get if the player is mounted on a non-combat mount.
  function Unit:IsMounted ()
    return IsMounted() and not self:IsOnCombatMount();
  end

  -- Get if the player is on a combat mount or not.
  local CombatMountBuff = {
    --- Classes
      Spell(131347), -- Demon Hunter Glide
      Spell(783), -- Druid Travel Form
      Spell(165962), -- Druid Flight Form
      Spell(220509), -- Paladin Divine Steed
      Spell(221883), -- Paladin Divine Steed
      Spell(221884), -- Paladin Divine Steed
      Spell(221886), -- Paladin Divine Steed
      Spell(221887), -- Paladin Divine Steed
    --- Legion
      -- Class Order Hall
      Spell(220480), -- Death Knight Ebon Blade Deathcharger
      Spell(220484), -- Death Knight Nazgrim's Deathcharger
      Spell(220488), -- Death Knight Trollbane's Deathcharger
      Spell(220489), -- Death Knight Whitemane's Deathcharger
      Spell(220491), -- Death Knight Mograine's Deathcharger
      Spell(220504), -- Paladin Silver Hand Charger
      Spell(220507), -- Paladin Silver Hand Charger
      -- Stormheim PVP Quest (Bareback Brawl)
      Spell(221595), -- Storm's Reach Cliffwalker
      Spell(221671), -- Storm's Reach Warbear
      Spell(221672), -- Storm's Reach Greatstag
      Spell(221673), -- Storm's Reach Worg
      Spell(218964), -- Stormtalon
    --- Warlord of Draenor (WoD)
      -- Nagrand
      Spell(164222), -- Frostwolf War Wolf
      Spell(165803) -- Telaari Talbuk
  };
  function Unit:IsOnCombatMount ()
    for i = 1, #CombatMountBuff do
      if self:Buff(CombatMountBuff[i], nil, true) then
        return true;
      end
    end
    return false;
  end

  -- gcd
  local GCD_OneSecond = {
    [103] = true, -- Feral
    [259] = true, -- Assassination
    [260] = true, -- Outlaw
    [261] = true, -- Subtlety
    [268] = true, -- Brewmaster
    [269] = true  -- Windwalker
  };
  local GCD_Value = 1.5;
  function Unit:GCD ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].GCD then
        if GCD_OneSecond[Cache.Persistent.Player.Spec[1]] then
          Cache.UnitInfo[self:GUID()].GCD = 1;
        else
          GCD_Value = 1.5/(1+self:HastePct()/100);
          Cache.UnitInfo[self:GUID()].GCD = GCD_Value > 0.75 and GCD_Value or 0.75;
        end
      end
      return Cache.UnitInfo[self:GUID()].GCD;
    end
  end
  
  -- gcd.remains
  local GCDSpell = Spell(61304);
  function Unit:GCDRemains ()
    return GCDSpell:Cooldown(true);
  end

  -- attack_power
  -- TODO : Use Cache
  function Unit:AttackPower ()
    return UnitAttackPower(self.UnitID);
  end

  -- crit_chance
  -- TODO : Use Cache
  function Unit:CritChancePct ()
    return GetCritChance();
  end

  -- haste
  -- TODO : Use Cache
  function Unit:HastePct ()
    return GetHaste();
  end

  -- mastery
  -- TODO : Use Cache
  function Unit:MasteryPct ()
    return GetMasteryEffect();
  end

  -- versatility
  -- TODO : Use Cache
  function Unit:VersatilityDmgPct ()
    return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE);
  end

  --------------------------
  --- 1 | Rage Functions ---
  --------------------------
  -- rage.max
  function Unit:RageMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].RageMax then
        Cache.UnitInfo[self:GUID()].RageMax = UnitPowerMax(self.UnitID, SPELL_POWER_RAGE);
      end
      return Cache.UnitInfo[self:GUID()].RageMax;
    end
  end
  -- rage
  function Unit:Rage ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].Rage then
        Cache.UnitInfo[self:GUID()].Rage = UnitPower(self.UnitID, SPELL_POWER_RAGE);
      end
      return Cache.UnitInfo[self:GUID()].Rage;
    end
  end
  -- rage.pct
  function Unit:RagePercentage ()
    return (self:Rage() / self:RageMax()) * 100;
  end
  -- rage.deficit
  function Unit:RageDeficit ()
    return self:RageMax() - self:Rage();
  end
  -- "rage.deficit.pct"
  function Unit:RageDeficitPercentage ()
    return (self:RageDeficit() / self:RageMax()) * 100;
  end

  ---------------------------
  --- 2 | Focus Functions ---
  ---------------------------
  -- focus.max
  function Unit:FocusMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].FocusMax then
        Cache.UnitInfo[self:GUID()].FocusMax = UnitPowerMax(self.UnitID, SPELL_POWER_FOCUS);
      end
      return Cache.UnitInfo[self:GUID()].FocusMax;
    end
  end
  -- focus
  function Unit:Focus ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].Focus then
        Cache.UnitInfo[self:GUID()].Focus = UnitPower(self.UnitID, SPELL_POWER_FOCUS);
      end
      return Cache.UnitInfo[self:GUID()].Focus;
    end
  end
  -- focus.regen
  function Unit:FocusRegen ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].FocusRegen then
        Cache.UnitInfo[self:GUID()].FocusRegen = select(2, GetPowerRegen(self.UnitID));
      end
      return Cache.UnitInfo[self:GUID()].FocusRegen;
    end
  end
  -- focus.pct
  function Unit:FocusPercentage ()
    return (self:Focus() / self:FocusMax()) * 100;
  end
  -- focus.deficit
  function Unit:FocusDeficit ()
    return self:FocusMax() - self:Focus();
  end
  -- "focus.deficit.pct"
  function Unit:FocusDeficitPercentage ()
    return (self:FocusDeficit() / self:FocusMax()) * 100;
  end
  -- "focus.regen.pct"
  function Unit:FocusRegenPercentage ()
    return (self:FocusRegen() / self:FocusMax()) * 100;
  end
  -- focus.time_to_max
  function Unit:FocusTimeToMax ()
    if self:FocusRegen() == 0 then return -1; end
    return self:FocusDeficit() * (1 / self:FocusRegen());
  end
  -- "focus.time_to_x"
  function Unit:FocusTimeToX (Amount)
    if self:FocusRegen() == 0 then return -1; end
    return Amount > self:Focus() and (Amount - self:Focus()) * (1 / self:FocusRegen()) or 0;
  end
  -- "focus.time_to_x.pct"
  function Unit:FocusTimeToXPercentage (Amount)
    if self:FocusRegen() == 0 then return -1; end
    return Amount > self:FocusPercentage() and (Amount - self:FocusPercentage()) * (1 / self:FocusRegenPercentage()) or 0;
  end
  -- cast_regen
  function Unit:FocusCastRegen (CastTime)
    if self:FocusRegen() == 0 then return -1; end
    return self:FocusRegen() * CastTime;
  end
  -- "remaining_cast_regen"
  function Unit:FocusRemainingCastRegen (Offset)
    if self:FocusRegen() == 0 then return -1; end
    -- If we are casting, we check what we will regen until the end of the cast
    if self:IsCasting() then
      return self:FocusRegen() * (self:CastRemains() + (Offset or 0));
    -- Else we'll use the remaining GCD as "CastTime"
    else
      return self:FocusRegen() * (self:GCDRemains() + (Offset or 0));
    end
  end
  -- Get the Focus we will loose when our cast will end, if we cast.
  function Unit:FocusLossOnCastEnd ()
    return self:IsCasting() and Spell(self:CastID()):Cost() or 0;
  end
  -- Predict the expected Focus at the end of the Cast/GCD.
  function Unit:FocusPredicted (Offset)
    if self:FocusRegen() == 0 then return -1; end
    return self:Focus() + self:FocusRemainingCastRegen(Offset) - self:FocusLossOnCastEnd();
  end

  ----------------------------
  --- 3 | Energy Functions ---
  ----------------------------
  -- energy.max
  function Unit:EnergyMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].EnergyMax then
        Cache.UnitInfo[self:GUID()].EnergyMax = UnitPowerMax(self.UnitID, SPELL_POWER_ENERGY);
      end
      return Cache.UnitInfo[self:GUID()].EnergyMax;
    end
  end
  -- energy
  function Unit:Energy ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].Energy then
        Cache.UnitInfo[self:GUID()].Energy = UnitPower(self.UnitID, SPELL_POWER_ENERGY);
      end
      return Cache.UnitInfo[self:GUID()].Energy;
    end
  end
  -- energy.regen
  function Unit:EnergyRegen ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].EnergyRegen then
        Cache.UnitInfo[self:GUID()].EnergyRegen = select(2, GetPowerRegen(self.UnitID));
      end
      return Cache.UnitInfo[self:GUID()].EnergyRegen;
    end
  end
  -- energy.pct
  function Unit:EnergyPercentage ()
    return (self:Energy() / self:EnergyMax()) * 100;
  end
  -- energy.deficit
  function Unit:EnergyDeficit ()
    return self:EnergyMax() - self:Energy();
  end
  -- "energy.deficit.pct"
  function Unit:EnergyDeficitPercentage ()
    return (self:EnergyDeficit() / self:EnergyMax()) * 100;
  end
  -- "energy.regen.pct"
  function Unit:EnergyRegenPercentage ()
    return (self:EnergyRegen() / self:EnergyMax()) * 100;
  end
  -- energy.time_to_max
  function Unit:EnergyTimeToMax ()
    if self:EnergyRegen() == 0 then return -1; end
    return self:EnergyDeficit() * (1 / self:EnergyRegen());
  end
  -- "energy.time_to_x"
  function Unit:EnergyTimeToX (Amount)
    if self:EnergyRegen() == 0 then return -1; end
    return Amount > self:Energy() and (Amount - self:Energy()) * (1 / self:EnergyRegen()) or 0;
  end
  -- "energy.time_to_x.pct"
  function Unit:EnergyTimeToXPercentage (Amount)
    if self:EnergyRegen() == 0 then return -1; end
    return Amount > self:EnergyPercentage() and (Amount - self:EnergyPercentage()) * (1 / self:EnergyRegenPercentage()) or 0;
  end

  ----------------------------------
  --- 4 | Combo Points Functions ---
  ----------------------------------
  -- combo_points.max
  function Unit:ComboPointsMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].ComboPointsMax then
        Cache.UnitInfo[self:GUID()].ComboPointsMax = UnitPowerMax(self.UnitID, SPELL_POWER_COMBO_POINTS);
      end
      return Cache.UnitInfo[self:GUID()].ComboPointsMax;
    end
  end
  -- combo_points
  function Unit:ComboPoints ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].ComboPoints then
        Cache.UnitInfo[self:GUID()].ComboPoints = UnitPower(self.UnitID, SPELL_POWER_COMBO_POINTS);
      end
      return Cache.UnitInfo[self:GUID()].ComboPoints;
    end
  end
  -- combo_points.deficit
  function Unit:ComboPointsDeficit ()
    return self:ComboPointsMax() - self:ComboPoints();
  end

  ------------------------
  --- 8 | Astral Power ---
  ------------------------
  -- astral_power.Max
  function Unit:AstralPowerMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].AstralPowerMax then
        Cache.UnitInfo[self:GUID()].AstralPowerMax = UnitPowerMax(self.UnitID, SPELL_POWER_LUNAR_POWER);
      end
      return Cache.UnitInfo[self:GUID()].AstralPowerMax;
    end
  end
  -- astral_power
  function Unit:AstralPower ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].AstralPower then
        Cache.UnitInfo[self:GUID()].AstralPower = UnitPower(self.UnitID, SPELL_POWER_LUNAR_POWER);
      end
      return Cache.UnitInfo[self:GUID()].AstralPower;
    end
  end
  -- astral_power.pct
  function Unit:AstralPowerPercentage ()
    return (self:AstralPower() / self:AstralPowerMax()) * 100;
  end
  -- astral_power.deficit
  function Unit:AstralPowerDeficit ()
    return self:AstralPowerMax() - self:AstralPower();
  end
  -- "astral_power.deficit.pct"
  function Unit:AstralPowerDeficitPercentage ()
    return (self:AstralPowerDeficit() / self:AstralPowerMax()) * 100;
  end

  --------------------------------
  --- 9 | Holy Power Functions ---
  --------------------------------
  -- holy_power.max
  function Unit:HolyPowerMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].HolyPowerMax then
        Cache.UnitInfo[self:GUID()].HolyPowerMax = UnitPowerMax(self.UnitID, SPELL_POWER_HOLY_POWAC);
      end
      return Cache.UnitInfo[self:GUID()].HolyPowerMax;
    end
  end
  -- holy_power
  function Unit:HolyPower ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].HolyPower then
        Cache.UnitInfo[self:GUID()].HolyPower = UnitPower(self.UnitID, SPELL_POWER_HOLY_POWAC);
      end
      return Cache.UnitInfo[self:GUID()].HolyPower;
    end
  end
  -- holy_power.pct
  function Unit:HolyPowerPercentage ()
    return (self:HolyPower() / self:HolyPowerMax()) * 100;
  end
  -- holy_power.deficit
  function Unit:HolyPowerDeficit ()
    return self:HolyPowerMax() - self:HolyPower();
  end
  -- "holy_power.deficit.pct"
  function Unit:HolyPowerDeficitPercentage ()
    return (self:HolyPowerDeficit() / self:HolyPowerMax()) * 100;
  end

  ------------------------------
  -- 11 | Maelstrom Functions --
  ------------------------------
  -- maelstrom.max
  function Unit:MaelstromMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].MaelstromMax then
        Cache.UnitInfo[self:GUID()].MaelstromMax = UnitPowerMax(self.UnitID, SPELL_POWER_MAELSTROM);
      end
      return Cache.UnitInfo[self:GUID()].MaelstromMax;
    end
  end
  -- maelstrom
  function Unit:Maelstrom ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].MaelstromMax then
        Cache.UnitInfo[self:GUID()].MaelstromMax = UnitPower(self.UnitID, SPELL_POWER_MAELSTROM);
      end
      return Cache.UnitInfo[self:GUID()].MaelstromMax;
    end
  end
  -- maelstrom.pct
  function Unit:MaelstromPercentage ()
    return (self:Maelstrom() / self:MaelstromMax()) * 100;
  end
  -- maelstrom.deficit
  function Unit:MaelstromDeficit ()
    return self:MaelstromMax() - self:Maelstrom();
  end
  -- "maelstrom.deficit.pct"
  function Unit:MaelstromDeficitPercentage ()
    return (self:MaelstromDeficit() / self:MaelstromMax()) * 100;
  end

  ------------------------------
  -- 13 | Insanity Functions ---
  ------------------------------
  -- insanity.max
  function Unit:InsanityMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].InsanityMax then
        Cache.UnitInfo[self:GUID()].InsanityMax = UnitPowerMax(self.UnitID, SPELL_POWER_INSANITY);
      end
      return Cache.UnitInfo[self:GUID()].InsanityMax;
    end
  end
  -- insanity
  function Unit:Insanity ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].Insanity then
        Cache.UnitInfo[self:GUID()].Insanity = UnitPower(self.UnitID, SPELL_POWER_INSANITY);
      end
      return Cache.UnitInfo[self:GUID()].Insanity;
    end
  end
  -- insanity.pct
  function Unit:InsanityPercentage ()
    return (self:Insanity() / self:InsanityMax()) * 100;
  end
  -- insanity.deficit
  function Unit:InsanityDeficit ()
    return self:InsanityMax() - self:Insanity();
  end
  -- "insanity.deficit.pct"
  function Unit:InsanityDeficitPercentage ()
    return (self:InsanityDeficit() / self:InsanityMax()) * 100;
  end
  -- Insanity Drain
  function Unit:Insanityrain ()
    --TODO : calculate insanitydrain
    return 1;
  end

  ---------------------------
  --- 17 | Fury Functions ---
  ---------------------------
  -- fury.max
  function Unit:FuryMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].FuryMax then
        Cache.UnitInfo[self:GUID()].FuryMax = UnitPowerMax(self.UnitID, SPELL_POWER_FURY);
      end
      return Cache.UnitInfo[self:GUID()].FuryMax;
    end
  end
  -- fury
  function Unit:Fury ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].Fury then
        Cache.UnitInfo[self:GUID()].Fury = UnitPower(self.UnitID, SPELL_POWER_FURY);
      end
      return Cache.UnitInfo[self:GUID()].Fury;
    end
  end
  -- fury.pct
  function Unit:FuryPercentage ()
    return (self:Fury() / self:FuryMax()) * 100;
  end
  -- fury.deficit
  function Unit:FuryDeficit ()
    return self:FuryMax() - self:Fury();
  end
  -- "fury.deficit.pct"
  function Unit:FuryDeficitPercentage ()
    return (self:FuryDeficit() / self:FuryMax()) * 100;
  end

  ---------------------------
  --- 18 | Pain Functions ---
  ---------------------------
  -- pain.max
  function Unit:PainMax ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].PainMax then
        Cache.UnitInfo[self:GUID()].PainMax = UnitPowerMax(self.UnitID, SPELL_POWER_PAIN);
      end
      return Cache.UnitInfo[self:GUID()].PainMax;
    end
  end
  -- pain
  function Unit:Pain ()
    if self:GUID() then
      if not Cache.UnitInfo[self:GUID()] then Cache.UnitInfo[self:GUID()] = {}; end
      if not Cache.UnitInfo[self:GUID()].PainMax then
        Cache.UnitInfo[self:GUID()].PainMax = UnitPower(self.UnitID, SPELL_POWER_PAIN);
      end
      return Cache.UnitInfo[self:GUID()].PainMax;
    end
  end
  -- pain.pct
  function Unit:PainPercentage ()
    return (self:Pain() / self:PainMax()) * 100;
  end
  -- pain.deficit
  function Unit:PainDeficit ()
    return self:PainMax() - self:Pain();
  end
  -- "pain.deficit.pct"
  function Unit:PainDeficitPercentage ()
    return (self:PainDeficit() / self:PainMax()) * 100;
  end

  -- Get if the player is stealthed or not
  local IsStealthedBuff = {
    -- Normal Stealth
    {
      -- Rogue
      Spell(1784), -- Stealth
      Spell(115191), -- Stealth w/ Subterfuge Talent
      -- Feral
      Spell(5215), -- Prowl
    },
    -- Combat Stealth
    {
      -- Rogue
      Spell(11327), -- Vanish
      Spell(115193), -- Vanish w/ Subterfuge Talent
      Spell(115192), -- Subterfuge Buff
      Spell(185422), -- Stealth from Shadow Dance
    },
    -- Special Stealth
    {
      -- Night Elf
      Spell(58984) -- Shadowmeld
    }
  };
  function Unit:IterateStealthBuffs (Abilities, Special, Duration)
    -- TODO: Add Assassination Spells when it'll be done and improve code
    -- TODO: Add Feral if we do supports it some day
    if  Spell.Rogue.Outlaw.Vanish:TimeSinceLastCast() < 0.3 or
      Spell.Rogue.Subtlety.ShadowDance:TimeSinceLastCast() < 0.3 or
      Spell.Rogue.Subtlety.Vanish:TimeSinceLastCast() < 0.3 or
      (Special and (
        Spell.Rogue.Outlaw.Shadowmeld:TimeSinceLastCast() < 0.3 or
        Spell.Rogue.Subtlety.Shadowmeld:TimeSinceLastCast() < 0.3
      ))
    then
      return Duration and 1 or true;
    end
    -- Normal Stealth
    for i = 1, #IsStealthedBuff[1] do
      if self:Buff(IsStealthedBuff[1][i]) then
        return Duration and self:BuffRemains(IsStealthedBuff[1][i]) or true;
      end
    end
    -- Combat Stealth
    if Abilities then
      for i = 1, #IsStealthedBuff[2] do
        if self:Buff(IsStealthedBuff[2][i]) then
          return Duration and self:BuffRemains(IsStealthedBuff[2][i]) or true;
        end
      end
    end
    -- Special Stealth
    if Special then
      for i = 1, #IsStealthedBuff[3] do
        if self:Buff(IsStealthedBuff[3][i]) then
          return Duration and self:BuffRemains(IsStealthedBuff[3][i]) or true;
        end
      end
    end
    return false;
  end
  local IsStealthedKey;
  function Unit:IsStealthed (Abilities, Special)
    IsStealthedKey = tostring(Abilites).."-"..tostring(Special);
    if not Cache.MiscInfo then Cache.MiscInfo = {}; end
    if not Cache.MiscInfo.IsStealthed then Cache.MiscInfo.IsStealthed = {}; end
    if Cache.MiscInfo.IsStealthed[IsStealthedKey] == nil then
      Cache.MiscInfo.IsStealthed[IsStealthedKey] = self:IterateStealthBuffs(Abilities, Special);
    end
    return Cache.MiscInfo.IsStealthed[IsStealthedKey];
  end

  -- buff.bloodlust.up
  function Unit:HasHeroism ()
    -- TODO: Make a table with all the bloodlust spells then do a for loop checking them (with AnyCaster as true in buff)
    return false;
  end

  -- Save the current player's equipment.
  AC.Equipment = {};
  function AC.GetEquipment ()
    local Item;
    for i = 1, 19 do
      Item = select(1, GetInventoryItemID("Player", i));
      -- If there is an item in that slot
      if Item ~= nil then
        AC.Equipment[i] = Item;
      end
    end
  end

  -- Check player set bonuses (call AC.GetEquipment before to refresh the current gear)
  HasTierSets = {
    ["T18"] = {
      [0]     =  function (Count) return Count > 1, Count > 3; end,                -- Return Function
      [1]     =  {[5] = 124319, [10] = 124329, [1] = 124334, [7] = 124340, [3] = 124346},    -- Warrior: Chest, Hands, Head, Legs, Shoulder
      [2]     =  {[5] = 124318, [10] = 124328, [1] = 124333, [7] = 124339, [3] = 124345},    -- Paladin: Chest, Hands, Head, Legs, Shoulder
      [3]     =  {[5] = 124284, [10] = 124292, [1] = 124296, [7] = 124301, [3] = 124307},    -- Hunter: Chest, Hands, Head, Legs, Shoulder
      [4]     =  {[5] = 124248, [10] = 124257, [1] = 124263, [7] = 124269, [3] = 124274},    -- Rogue: Chest, Hands, Head, Legs, Shoulder
      [5]     =  {[5] = 124172, [10] = 124155, [1] = 124161, [7] = 124166, [3] = 124178},    -- Priest: Chest, Hands, Head, Legs, Shoulder
      [6]     =  {[5] = 124317, [10] = 124327, [1] = 124332, [7] = 124338, [3] = 124344},    -- Death Knight: Chest, Hands, Head, Legs, Shoulder
      [7]     =  {[5] = 124303, [10] = 124293, [1] = 124297, [7] = 124302, [3] = 124308},    -- Shaman: Chest, Hands, Head, Legs, Shoulder
      [8]     =  {[5] = 124171, [10] = 124154, [1] = 124160, [7] = 124165, [3] = 124177},    -- Mage: Chest, Hands, Head, Legs, Shoulder
      [9]     =  {[5] = 124173, [10] = 124156, [1] = 124162, [7] = 124167, [3] = 124179},    -- Warlock: Chest, Hands, Head, Legs, Shoulder
      [10]    =  {[5] = 124247, [10] = 124256, [1] = 124262, [7] = 124268, [3] = 124273},    -- Monk: Chest, Hands, Head, Legs, Shoulder
      [11]    =  {[5] = 124246, [10] = 124255, [1] = 124261, [7] = 124267, [3] = 124272},    -- Druid: Chest, Hands, Head, Legs, Shoulder
      [12]    =  nil                                        -- Demon Hunter: Chest, Hands, Head, Legs, Shoulder
    },
    ["T18_ClassTrinket"] = {
      [0]     =  function (Count) return Count > 0; end,    -- Return Function
      [1]     =  {[13] = 124523, [14] = 124523},        -- Warrior : Worldbreaker's Resolve
      [2]     =  {[13] = 124518, [14] = 124518},        -- Paladin : Libram of Vindication
      [3]     =  {[13] = 124515, [14] = 124515},        -- Hunter : Talisman of the Master Tracker
      [4]     =  {[13] = 124520, [14] = 124520},        -- Rogue : Bleeding Hollow Toxin Vessel
      [5]     =  {[13] = 124519, [14] = 124519},        -- Priest : Repudiation of War
      [6]     =  {[13] = 124513, [14] = 124513},        -- Death Knight : Reaper's Harvest
      [7]     =  {[13] = 124521, [14] = 124521},        -- Shaman : Core of the Primal Elements
      [8]     =  {[13] = 124516, [14] = 124516},        -- Mage : Tome of Shifting Words
      [9]     =  {[13] = 124522, [14] = 124522},        -- Warlock : Fragment of the Dark Star
      [10]    =  {[13] = 124517, [14] = 124517},        -- Monk : Sacred Draenic Incense
      [11]    =  {[13] = 124514, [14] = 124514},        -- Druid : Seed of Creation
      [12]    =  {[13] = 139630, [14] = 139630}        -- Demon Hunter : Etching of Sargeras
    },
    ["T19"] = {
      [0]     =  function (Count) return Count > 1, Count > 3; end,                      -- Return Function
      [1]     =  {[5] = 138351, [10] = 138354, [1] = 138357, [7] = 138360, [3] = 138363, [15] = 138374},    -- Warrior: Chest, Hands, Head, Legs, Shoulder, Back
      [2]     =  {[5] = 138350, [10] = 138353, [1] = 138356, [7] = 138359, [3] = 138362, [15] = 138369},    -- Paladin: Chest, Hands, Head, Legs, Shoulder, Back
      [3]     =  {[5] = 138339, [10] = 138340, [1] = 138342, [7] = 138344, [3] = 138347, [15] = 138368},    -- Hunter: Chest, Hands, Head, Legs, Shoulder, Back
      [4]     =  {[5] = 138326, [10] = 138329, [1] = 138332, [7] = 138335, [3] = 138338, [15] = 138371},    -- Rogue: Chest, Hands, Head, Legs, Shoulder, Back
      [5]     =  {[5] = 138319, [10] = 138310, [1] = 138313, [7] = 138316, [3] = 138322, [15] = 138370},    -- Priest: Chest, Hands, Head, Legs, Shoulder, Back
      [6]     =  {[5] = 138349, [10] = 138352, [1] = 138355, [7] = 138358, [3] = 138361, [15] = 138364},    -- Death Knight: Chest, Hands, Head, Legs, Shoulder, Back
      [7]     =  {[5] = 138346, [10] = 138341, [1] = 138343, [7] = 138345, [3] = 138348, [15] = 138372},    -- Shaman: Chest, Hands, Head, Legs, Shoulder, Back
      [8]     =  {[5] = 138318, [10] = 138309, [1] = 138312, [7] = 138315, [3] = 138321, [15] = 138365},    -- Mage: Chest, Hands, Head, Legs, Shoulder, Back
      [9]     =  {[5] = 138320, [10] = 138311, [1] = 138314, [7] = 138317, [3] = 138323, [15] = 138373},    -- Warlock: Chest, Hands, Head, Legs, Shoulder, Back
      [10]    =  {[5] = 138325, [10] = 138328, [1] = 138331, [7] = 138334, [3] = 138337, [15] = 138367},    -- Monk: Chest, Hands, Head, Legs, Shoulder, Back
      [11]    =  {[5] = 138324, [10] = 138327, [1] = 138330, [7] = 138333, [3] = 138336, [15] = 138366},    -- Druid: Chest, Hands, Head, Legs, Shoulder, Back
      [12]    =  {[5] = 138376, [10] = 138377, [1] = 138378, [7] = 138379, [3] = 138380, [15] = 138375}     -- Demon Hunter: Chest, Hands, Head, Legs, Shoulder, Back
    }
  };
  function AC.HasTier (Tier)
    -- Set Bonuses are disabled in Challenge Mode (Diff = 8) and in Proving Grounds (Map = 1148).
    local DifficultyID, _, _, _, _, MapID = select(3, GetInstanceInfo());
    if DifficultyID == 8 or MapID == 1148 then return false; end
    -- Check gear
    if HasTierSets[Tier][Cache.Persistent.Player.Class[3]] then
      local Count = 0;
      local Item;
      for Slot, ItemID in pairs(HasTierSets[Tier][Cache.Persistent.Player.Class[3]]) do
        Item = AC.Equipment[Slot];
        if Item and Item == ItemID then
          Count = Count + 1;
        end
      end
      return HasTierSets[Tier][0](Count);
    else
      return false;
    end
  end

  -- Mythic Dungeon Abilites
  local MDA = {
    PlayerBuff = {
    },
    PlayerDebuff = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Vault of the Wardens
          -- Inquisitor Tormentorum
          {Spell(200904), "Sapped Soul"}
    },
    EnemiesBuff = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Black Rook Hold
          -- Trashes
          {Spell(200291), "Blade Dance Buff"} -- Risen Scout
    },
    EnemiesCast = {
      --- Legion
        ----- Dungeons (7.0 Patch) -----
        --- Black Rook Hold
          -- Trashes
          {Spell(200291), "Blade Dance Cast"} -- Risen Scout
    },
    EnemiesDebuff = {
    }
  }
  function AC.MythicDungeon ()
    -- TODO: Optimize
    for Key, Value in pairs(MDA) do
      if Key == "PlayerBuff" then
        for i = 1, #Value do
          if Player:Buff(Value[i][1], nil, true) then
            return Value[i][2];
          end
        end
      elseif Key == "PlayerDebuff" then
        for i = 1, #Value do
          if Player:Debuff(Value[i][1], nil, true) then
            return Value[i][2];
          end
        end
      elseif Key == "EnemiesBuff" then

      elseif Key == "EnemiesCast" then

      elseif Key == "EnemiesDebuff" then

      end
    end
    return "";
  end
