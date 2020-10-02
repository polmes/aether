classdef AtmosphereStochastic < Factory
	properties (Constant, Access = protected)
		defaults = {'GRAM', @nasa.AtmosphereStochasticGRAM, 'FastGRAM', @nasa.AtmosphereStochasticFastGRAM};
		exception = 'Unkown stochastic atmosphere model provided';
	end

	methods
		function self = AtmosphereStochastic(varargin)
			self@Factory(varargin);
		end

		function at = generate(self, obj)
			%   obj :=  (Non-stochastic) Atmosphere object of a supported class

			% Generate (stochastic) Atmosphere (note: first argument defines class)
			cls = class(obj);
			model = cls((strfind(cls, 'Atmosphere') + numel('Atmosphere')):end);
			at = self.constructor(model, obj);
		end
	end

	methods (Static)
		% Static property: DICTIONARY
		function out = dictionary(in)
			persistent DICTIONARY;
			if nargin
				DICTIONARY = in;
			end
			out = DICTIONARY;
		end
	end
end
