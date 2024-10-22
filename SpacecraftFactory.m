classdef SpacecraftFactory < Factory
	properties (Constant, Access = protected)
		defaults = {'Capsule', @SpacecraftCapsule};
		exception = 'Unkown spacecraft type provided';
	end

	methods
		function self = SpacecraftFactory(varargin)
			self@Factory(varargin);
		end

		function sc = generate(self, data)
			%   data  :=  'spacecraft' structure from case *.json

			% Generate Spacecraft (note: first argument defines type)
			sc = self.constructor(data.type, data);
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
