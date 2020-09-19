function varargout = parse(opts, vals, varsin)
	% [a, b, ...] = util.parse(opts, vals, varsin)
	% Simple parser of function key-value input arguments
	%
	% Inputs:
	%   opts    :=  Character cell array of possible keys
	%   vals    :=  Cell array of default values
	%   varsin  :=  Given varargin input (every other element must be a char)
	%
	% Outputs:
	%   varargout   :=  Given values [a, b, ...] to the possible keys

	% Case insensitivity
	opts = lower(opts);
	varsin(1:2:end) = lower(varsin(1:2:end));

	% Parse key-value argument pairs
	[~, idxo, idxv] = intersect(opts, varsin);
	vals(idxo) = varsin(idxv + 1);

	% Return new values
	varargout = vals;
end
