function [sc, pl, S0, T, en, opts] = pre(casefile, analysisfile)
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
	%   T       :=  Max ingeration time
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

	% Load defaults
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

	% Append analysis inputs if available
	if hasanalysis
		try
			analysisdata = json2struct(analysisfile);
			data.analysis = analysisdata;
			opts = data.analysis;
		catch
			ME = MException('util:pre', 'Error loading analysis data');
			throw(ME);
		end
	end

	% Generate Spacecraft object
	sf = FactorySpacecraft;
	sc = sf.generate(data.spacecraft);

	% Generate Atmosphere object
	af = FactoryAtmosphere;
	at = af.generate(data.planet.atmosphere, data.initial.datetime);

	% Generate Planet object
	pf = FactoryPlanet;
	pl = pf.generate(data.planet, at);

	% Generate array of initial conditions
	% Note: data will *always* have the following fields
	IC = data.initial;
	alt = IC.altitude;
	Uinf = IC.velocity;
	gamma = deg2rad(IC.flightpath);
	chi = deg2rad(IC.heading);
	lat = deg2rad(IC.latitude);
	lon = deg2rad(IC.longitude);
	att = num2cell(deg2rad(IC.attitude));
	[ph, th, ps] = att{:};
	ang = num2cell(IC.angular);
	[p, q, r] = ang{:};
	S0 = [alt, Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r];


	% Generate Engine object
	ef = FactoryEngine;
	en = ef.generate(data.integration);

	% Max integration time
	T = data.integration.maxtime;
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
