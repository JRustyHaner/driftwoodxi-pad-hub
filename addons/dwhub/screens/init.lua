--[[ screens/init.lua — hub screen registry ]]

local H = require('screens._helpers');
local home = require('screens.home');
local squad = require('screens.squad');
local jobs = require('screens.jobs');
local rules = require('screens.rules');
local port = require('screens.port');
local items = require('screens.items');
local engage = require('screens.engage');
local expansion = require('screens.expansion');

local M = {};

M.placeholder = home.placeholder;
M.HOME_GROUPS = home.HOME_GROUPS;
M.group = home.group;
M.home = home.home;

M.squad = squad.squad;
M.jobs = jobs.jobs;
M.rules = rules.rules;
M.port = port.port;
M.items = items.items;

M.engage = engage.engage;

M.storage = expansion.storage;
M.market = expansion.market;
M.merc = expansion.merc;
M.quests = expansion.quests;
M.drift = expansion.drift;
M.fish = expansion.fish;
M.raid = expansion.raid;
M.arena = expansion.arena;
M.scan = expansion.scan;

M._fire = H.fire;
M._pick_list = H.pick_list;
M._text_entry = H.text_entry;
M._action_rows = H.action_rows;
M._live_pick = H.live_pick;
M._pick_character = H.pick_character;
M._confirm_pick = H.confirm_pick;

return M;
