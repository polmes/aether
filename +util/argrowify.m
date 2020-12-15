function argrowify(varargin)
	% util.argrowify(h1, h2, ...)
	%   Take figure handles h1, h2, ... and make all their axes match
	%   by taking the minum/maximum limits
	%
	% util.argrowify(hs)
	%   Take array of figure handles hs and make all their axes match
	%   by taking the minum/maximum limits
	%
	% Example:
	%   To argrowify all open figures, run:
	%   util.argrowify(findobj('type', 'figure'))

	% Get array of figure handles
	if numel(varargin) > 1
		fs = [varargin{:}];
	else
		fs = varargin{1};
	end

	% Get axes and their limits
	ax = findall(fs, 'Type', 'axes');
	[xmin, xmax, xidx] = cellfun(@onlynumeric, get(ax, 'XLim'));
	[ymin, ymax, yidx] = cellfun(@onlynumeric, get(ax, 'YLim'));
	[zmin, zmax, zidx] = cellfun(@onlynumeric, get(ax, 'ZLim'));

	% Set new limits to min/max for each axis
	set(ax(xidx), 'XLim', [min(xmin) max(xmax)]);
	set(ax(yidx), 'YLim', [min(ymin) max(ymax)]);
	set(ax(zidx), 'ZLim', [min(zmin) max(zmax)]);

	% Helper function to select only numeric axes
	function [minl, maxl, idx] = onlynumeric(lim)
		if isnumeric(lim)
			lim = double(lim);
			minl = lim(1);
			maxl = lim(2);
			idx = true;
		else
			minl = NaN;
			maxl = NaN;
			idx = false;
		end
	end
end
