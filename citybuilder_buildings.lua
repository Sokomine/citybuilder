--[[
	{ -- example entry:
		-- the filename of the schematic
		scm="npc_house_level_3_1_180",
		-- title, description and level will be used instead of the filename in order to describe the building for the player
		title="Small house",
		descr="Founding a family",
		-- filename of what this building can be upgraded to; note: that schematic ought to have the same dimensions
		upgrade_to="npc_house_level_4_1_180",
		-- what this building provides (=single string)
		provides="housing",
		-- ..and the level at which it is provided
		level=3,
		-- each building may require what other buildings provide at a certain level; in order to be allowed to build this
		-- particular building, you need one building that provides "lumberjack" at level 1 (or higher), another one that
		-- provides "pub" at level 1 (or higher), another one which provides "mine" at level 1, a "church" at at least
		-- level 2, and so on
		requires={ lumberjack = 1, pub = 1, mine = 1, church = 2, farm = 0, mill = 0},
		-- this house holds beds for 3 inhabitants and can house that many npc (not used yet)
		inh=3,
		-- 2 of the npc living in this house can work elsewhere (not used yet)
		worker=2,
		-- 1 of them is a child (not used yet)
		children=1,
		-- how many npc need to work here in order for the building to function? (not used yet)
		needs_worker=1,
		-- which job does the building provide? (not used yet)
		job="houseowner"
	},
--]]

citybuilder.buildings = {
	-- very tiny wooden cabin
	{scm="npc_house_level_0_1_180", title="Provisory shed",    descr="Just arrived",             upgrade_to="npc_house_level_1_1_180",
		-- we need to get started somehow
		requires=nil,
		-- other workers (apart from the basic lumberjack and bartender) may
		-- not be willing to work without beeing offered a better house
		provides="housing", level=0, inh=1, worker=1, children=0},

	-- wooden shed
	{scm="npc_house_level_1_1_180", title="Worker's hut",      descr="Getting settled",          upgrade_to="npc_house_level_2_1_180",
		-- the lumberjack provides the wood for this and further houses
		-- a pub attracts more workers
		requires={ lumberjack = 0, pub = 0},
		provides="housing", level=1, inh=1, worker=1, children=0},

	-- wooden house with furnace and first farming attempts
	{scm="npc_house_level_2_1_180", title="Tiny house",        descr="Getting married",          upgrade_to="npc_house_level_3_1_180",
		-- the miner is needed for the cobble in the building;
		-- the church is needed in order to get married :-)
		requires={ lumberjack = 0, pub = 0, mine = 0, church = 1}, -- TODO: also require a ring forged from gold?
		provides="housing", level=2, inh=2, worker=2, children=0},

	-- loam + wood + some farming
	{scm="npc_house_level_3_1_180", title="Small house",       descr="Founding a family",        upgrade_to="npc_house_level_4_1_180",
		-- the farmer provides straw for the roof and wheat; may also provide loam
		-- wheat + mill provide enough food for a child
		requires={ lumberjack = 1, pub = 1, mine = 1, church = 2, farm = 0, mill = 0},
		provides="housing", level=3, inh=3, worker=2, children=1},

	-- clay + wood
	{scm="npc_house_level_4_1_180", title="Family home",       descr="Room for a second child",  upgrade_to="npc_house_level_5_1_180",
		-- there are enough children for a school now;
		-- the bakery helps to feed more children more easily
		requires={ lumberjack = 1, pub = 1, mine = 1, church = 2, farm = 0, mill = 0, bakery = 0, school = 0},
		provides="housing", level=4, inh=4, worker=2, children=2},

	-- full caly + simple glass pane windows
	{scm="npc_house_level_5_1_180", title="Large family home", descr="Third child on the way",   upgrade_to="npc_house_level_6_1_180",
		-- the house uses glass; needs to come from somewhere
		-- a market might be useful for trading (more mouths to feed)
		requires={ lumberjack = 1, pub = 1, mine = 1, church = 2, farm = 0, mill = 0, bakery = 0, school = 0, glassmaker = 0, market = 0},
		provides="housing", level=5, inh=5, worker=2, children=3},

	-- full brick, bookshelves, obsidian glass, ...
	{scm="npc_house_level_6_1_180", title="Family estate",     descr="Grandparents move in",     upgrade_to=nil,
		-- the grandparents will expect some level of education; thus, the library;
		-- a doctor also comes in very handy...
		requires={ lumberjack = 1, pub = 1, mine = 1, church = 2, farm = 0, mill = 0, bakery = 0, school = 0, glassmaker = 0, market = 0, library = 0, doctor = 0},
		provides="housing", level=6, inh=7, worker=3, children=3},



	{scm="npc_mine_level_0_6_270", title="Prospektors Dig", descr="Is this a good place for a mine?", upgrade_to="npc_mine_level_1_6_270",
		-- we need to get started somehow
		requires=nil,
		provides="mine", level=0, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_1_6_270", title="Cobble mine", descr="Beginner's mine - Collecting cobble", upgrade_to="npc_mine_level_2_6_270",
		-- the mine will need a lot of wood;
		-- the pub is needed for recovery after all that mining;
		-- there has to be at least one house;
		requires={lumberjack = 1, pub = 1, housing = 1},
		provides="mine", level=1, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_2_6_270", title="Coal mine",   descr="Digging for coal",  upgrade_to="npc_mine_level_3_6_270",
		-- the miner is needed for the cobble in the building;
		requires={lumberjack = 1, pub = 1, housing = 1},
		provides="mine", level=2, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_3_6_270", title="Ore mine", descr="Searching for iron and copper",   upgrade_to="npc_mine_level_4_6_270",
		requires={lumberjack = 2, pub = 2, housing = 2},
		provides="mine", level=3, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_4_6_270", title="Gold mine", descr="Searching for gold and other ores",  upgrade_to="npc_mine_level_5_6_270",
		requires={lumberjack = 3, pub = 3, housing = 3},
		provides="mine", level=4, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_5_6_270", title="Mese mine", descr="Advanced mine",   upgrade_to="npc_mine_level_6_6_270",
		requires={lumberjack = 4, pub = 4, housing = 4},
		provides="mine", level=5, inh=0, worker=0, children=0, needs_worker=1, job="miner"},

	{scm="npc_mine_level_6_6_270", title="Diamond mine", descr="Extreme mining operation", upgrade_to=nil,
		requires={lumberjack = 5, pub = 5, housing = 5},
		provides="mine", level=6, inh=0, worker=0, children=0, needs_worker=1, job="miner"},



	-- very tiny wooden chapel
	{scm="npc_church_level_0_1_0", title="Small chapel",         descr="Getting started",          upgrade_to="npc_church_level_1_1_0",
		-- we need to get started somehow
		requires=nil,
		-- too small to require a worker of its own; can be done by a part-time worker
		provides="church", level=0, inh=0, worker=0, children=0, needs_worker=0, job="priest"},

	-- small wooden church
	{scm="npc_church_level_1_1_0", title="Small wooden church",  descr="Marriages can take place", upgrade_to="npc_church_level_2_1_0",
		-- we need to get started somehow
		requires={ lumberjack = 0, housing = 0},
		provides="church", level=1, inh=0, worker=0, children=0, needs_worker=1, job="priest"},

	};

