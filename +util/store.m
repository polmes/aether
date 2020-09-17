function store(name, varargin)
	% util.store(name, a, b, ...)
	% Save variables a, b, ... in mat/name.mat
	%
	% util.store(name, 'A', a, 'B', b, 'ProvidedNames', true)
	% Save variables a, b, ... with provided names 'A', 'B', ...
	%
	% util.store(..., Name, Value)
	% Pass additional options that can be specified:
	%   'DataDir'       (String)    Directory in which to save data (relative to project root)
	%   'DateStamp'     (Boolean)   Append date in format '_yyy-MM-dd' to file name (default: false)
	%   'AsStructure'   (Boolean)   Save all the variables in a structured called data (default: false)
	%   'OverWrite'     (Boolean)   Allow overwriting files with the same name (default: false)

	disp('Saving data...');

	% Parse key-value argument pairs, separate the rest
	opts = {'DataDir', 'DateStamp', 'AsStructure', 'ProvidedNames', 'OverWrite'};
	vals = {'mat/', false, false, false, false}; % default values
	rest = true(1, nargin-1); % rest of arguments are variables to save
	for i = 1:numel(opts)
		if any(strcmp(varargin, opts{i}))
			idx = find(strcmp(varargin, opts{i}));
			vals{i} = varargin{idx + 1};
			rest([idx, idx+1]) = false;
		end
	end
	[datadir, datestamp, asstructure, providednames, overwrite] = vals{:};
	varsin = varargin(rest);

	% Save as...
	if ~datestamp
		filename = name;
	else
		filename = [name '_' char(datetime('now', 'Format', 'yyy-MM-dd'))];
	end

	% Avoid overwriting files...
	if ~overwrite && exist([datadir filename '.mat'], 'file')
		uid = 0;
		while exist(['mat/' filename '.mat'], 'file')
			uid = uid + 1;
			filename = [name '_' num2str(uid)];
		end
		warning(['File with specified name already exists. Saving with modified name: "' filename '"...']);
	end

	% Create directory if it does not exist
	if ~exist(datadir, 'dir')
		mkdir(datadir);
	end

	% Create temporary structure...
	if ~providednames
		fields = cell(1, numel(varsin));
		idxs = find(rest) + 1;
		for i = 1:numel(varsin)
			fields{i} = inputname(idxs(i));
		end
		vars = varsin;
	else
		fields = varsin(1:2:end);
		vars = varsin(2:2:end);
	end
	data = cell2struct(vars, fields, 2);

	% ... and save
	if ~asstructure
		save([datadir filename '.mat'], '-struct', 'data', '-v7.3');
	else
		save([datadir filename '.mat'], 'data', '-v7.3');
	end
	disp('Data saved.');
end
