function render(hfig, name, varargin)
	% util.render(hfig, name)
	% Save figure with handle hfig in EPS format as fig/name.eps
	%
	% util.render(..., Name, Value)
	% Pass additional options that can be specified:
	%   'DataDir'       (String)    Directory in which to save figure (relative to project root)
	%   'OverWrite'     (Boolean)   Allow overwriting files with the same name (default: true)
	%   'Format'        (String)    Save figure in a different format
	%                               Options:
	%                                   'fig'   MATLAB Figure (*.fig)
	%                                   'epsc'  EPS color (*.eps)
	%                                   'pdf'   PDF color (*.pdf)
	%                                   'png'   PNG 24-bit (*.png)
	%                                   'jpeg'  JPEG 24-bit (*.jpg)

	% Parse key-value argument pairs
	opts = {'DataDir', 'OverWrite', 'Format'}; % possible keys
	vals = {'fig/', true, 'epsc'}; % default values
	[datadir, overwrite, f] = util.parse(opts, vals, varargin);

	% Format extensions
	extK = {'fig', 'epsc', 'pdf', 'png', 'jpeg'};
	extV = {'.fig', '.eps', '.pdf', '.png', '.jpg'};
	ext = containers.Map(extK, extV);

	% Create directory if it does not exist
	if ~exist(datadir, 'dir')
		mkdir(datadir);
	end

	% Just the file name
	filename = name;

	% Avoid overwriting files...
	if ~overwrite && exist([datadir filename ext(f)], 'file')
		uid = 0;
		while exist([datadir filename ext(f)], 'file')
			uid = uid + 1;
			filename = [name '_' num2str(uid)];
		end
	end

	% Full file path, name, and extension
	filepath = [datadir name ext(f)];

	% Render figure with specified format
	saveas(hfig, filepath, f);

	disp(['Saved figure: ' filepath]);
end
