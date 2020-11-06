function data = open(filename, varargin)
	% util.store(name)
	% Load variables defined in file mat/filename.mat
	%
	% util.open(..., Name, Value)
	% Pass additional options that can be specified:
	%   'DataDir'       (String)    Directory from where to load data (relative to project root)

	% Parse key-value argument pairs
	opts = {'DataDir'}; % possible keys
	vals = {'mat/'}; % default values
	datadir = util.parse(opts, vals, varargin);

	% Use provided path if necessary
	[filedir, name, ext] = fileparts(filename);
	if isempty(filedir)
		filedir = datadir;
	end
	if isempty(ext)
		ext = '.mat';
	end

	% Load data
	filepath = fullfile(filedir, [name ext]);
	data = load(filepath);

	% If there's only one field, return it directly
	if numel(fieldnames(data)) == 1
		data = struct2array(data);
	end
end
