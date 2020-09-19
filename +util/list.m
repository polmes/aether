function files = list(pattern, varargin)
	% util.list(pattern)
	% List files that start with pattern* in mat/
	%
	% util.list(..., Name, Value)
	% Pass additional options that can be specified:
	%   'DataDir'       (String)    Directory in which to look for files (relative to project root)
	%   'StartsWith'    (Boolean)   Whether to look for names that start with provided pattern
	%                               or take pattern as complete

	% Parse key-value argument pairs
	opts = {'DataDir', 'StartsWith'}; % possible keys
	vals = {'mat/', true}; % default values
	[datadir, startswith] = util.parse(opts, vals, varargin);

	% Use provided path if available
	[filedir, name, ext] = fileparts(pattern);
	if isempty(filedir)
		filedir = datadir;
	end
	if ~strcmp(ext, '.mat')
		name = [name ext];
		ext = '.mat';
	end

	% Build query
	if startswith
		filename = [name '*' ext];
	else
		filename = [name ext];
	end

	% List files
	filepath = fullfile(filedir, filename);
	files = dir(filepath);
end
