classdef AtmosphereFactory < Factory
	properties (Constant, Access = protected)
		defaults = {'GRAM', @nasa.AtmosphereGRAM, 'FastGRAM', @nasa.AtmosphereFastGRAM, 'MSIS', @AtmosphereMSIS, 'COESA', @AtmosphereCOESA, 'Std76', @AtmosphereStd76, 'Wind', @nasa.AtmosphereWindGRAM, 'WindGRAM', @nasa.AtmosphereWindGRAM};
		exception = 'Unkown atmosphere model provided';
	end

	methods
		function self = AtmosphereFactory(varargin)
			self@Factory(varargin);
		end

		function at = generate(self, model, dateandtime)
			%   atmosphere  :=  'atmosphere' structure from case *.json
			%   dateandtime :=  Datetime string, e.g. '1967/11/09 20:00:00'

			% Generate Atmosphere (note: first argument defines class)
			at = self.constructor(model, dateandtime);
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
