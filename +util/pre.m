function [sc, pl, en, S0, opts] = pre(casefile, analysisfile)
	% util.pre(casefile, analysisfile)
	% Preprocesses input file and generates AETHER objects
	%
	% Inputs:
	%   casefile        :=  Name or path of the case *.json input file
	%                       If not provided, will use 'json/defaults.json'
	%   analysisfile    :=  Name or path of the analysis *.json input file
	%                       (optional, depending on chosen analysis)
	%
	% Outputs
	%   sc      :=  Spacecraft object
	%   pl      :=  Planet object
	%   S0      :=  Array of initial conditions
	%   en      :=  Engine object
	%   opts    :=  Options structure for specific analysis

	% How many inputs?
	hascase = false;
	hasanalysis = false;
	if nargin > 0 && ~isempty(casefile)
		hascase = true;
	end
	if nargin > 1 && ~isempty(analysisfile)
		hasanalysis = true;
	end

	% Load case defaults
	data = json2struct('defaults');
	backup = data;

	% Override defaults with case inputs
	if hascase
		try
			casedata = json2struct(casefile);
			topfields = fieldnames(data);
			topmatches = isfield(casedata, topfields);
			for i = find(topmatches).'
				midfields = fieldnames(data.(topfields{i}));
				midmatches = isfield(casedata.(topfields{i}), midfields);
				for j = find(midmatches).'
					data.(topfields{i}).(midfields{j}) = casedata.(topfields{i}).(midfields{j});
				end
			end
		catch
			warning('Error loading case data. Reverting back to defaults...');
			data = backup;
		end
	end
	
	% Load analysis defaults if available
	db = dbstack;
	fn = db(end).name;
	if isfile(fullfile('json/', [fn '.json']))
		opts = json2struct(fn);
		backup = opts;
	end

	% Override analysis defaults if provided
	if hasanalysis
		try
			analysisdata = json2struct(analysisfile);
			fields = fieldnames(opts);
			matches = isfield(analysisdata, fields);
			for i = find(matches).'
				opts.(fields{i}) = analysisdata.(fields{i});
			end			
		catch
			warning('Error loading case data. Reverting back to defaults...');
			opts = backup;
		end
	end

	% Generate Spacecraft object
	sf = SpacecraftFactory;
	sc = sf.generate(data.spacecraft);

	% Generate Atmosphere object
	af = AtmosphereFactory;
	at = af.generate(data.planet.atmosphere, data.initial.datetime);

	% Generate Planet object
	pf = PlanetFactory;
	pl = pf.generate(data.planet, at, data.initial.datetime);

	% Generate Engine object
	ef = EngineFactory;
	en = ef.generate(data.integration);

	% Generate array of initial conditions
	% Note: data will *always* have the following fields
	IC = data.initial;
	alt = IC.altitude;
	Umag = IC.velocity;
	gamma = deg2rad(IC.flightpath);
	chi = deg2rad(IC.heading);
	lat = deg2rad(IC.latitude);
	lon = deg2rad(IC.longitude);
	att = num2cell(deg2rad(IC.attitude));
	delta0 = deg2rad(IC.bank);
	[ph, th, ps] = att{:};
	ang = num2cell(IC.angular);
	[p, q, r] = ang{:};
	S0 = [alt, Umag, gamma, chi, lat, lon, ph, th, ps, p, q, r, delta0];
	S0 = S0(1:en.NS-1);
end

function json = json2struct(filename)
	[inputdir, name, ext] = fileparts(filename);
	if isempty(inputdir)
		inputdir = 'json/'; % default inputs directory
	end
	if isempty(ext)
		ext = '.json';
	end

	filepath = fullfile(inputdir, [name ext]);
	str = fileread(filepath);
	json = jsondecode(str);
end
