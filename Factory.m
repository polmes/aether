classdef Factory < handle
	properties (Constant, Abstract, Access = protected)
		% Default type-constructor pairs, e.g. {'type', @Constructor, ...}
		defaults;

		% Message for constructor exception errors
		exception;
	end

	methods
		% Factory Constructor
		function self = Factory(cellarr)
			if ~isempty(cellarr)
				arr = cellarr{1};
				map = containers.Map(arr(1:2:end), arr(2:2:end));
				self.dictionary(map);
			elseif isempty(self.dictionary)
				map = containers.Map(self.defaults(1:2:end), self.defaults(2:2:end));
				self.dictionary(map);
			end
		end

		% Object Constructor
		function obj = constructor(self, key, varargin)
			try
				dict = self.dictionary;
				constructor = dict(key);
				obj = constructor(varargin{:});
			catch
				util.exception(self.exception);
			end
		end

		% Expose append method to easily add new constructors
		function append(self, key, val)
			dict = self.dictionary;
			keys = [dict.keys key];
			vals = [dict.values {val}];

			map = containers.Map(keys, vals);
			self.dictionary(map)
		end
	end

	methods (Abstract)
		sth = generate(self, data);
	end

	methods (Static, Abstract)
		out = dictionary(in);
	end
end
