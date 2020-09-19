classdef FactoryAtmosphere < Factory
	properties (Constant, Access = protected)
		defaults = {'GRAM', @AtmosphereGRAM, 'NRLMSISE', @AtmosphereNRLMSISE, 'COESA', @AtmosphereCOESA, 'Std76', @AtmosphereStd76};
		exception = 'Unkown atmosphere model provided';
	end

	methods
		function self = FactoryAtmosphere(varargin)
			self = self@Factory(varargin);
		end

		function at = generate(self, atmosphere, dateandtime)
			%   atmosphere  :=  'atmosphere' structure from case *.json
			%   dateandtime :=  Datetime string, e.g. '1967/11/09 20:00:00'

			% Append additional information to constructor input argument
			argdata = atmosphere;
			argdata.dateandtime = dateandtime;

			% Generate Atmosphere (note: first argument defines class)
			at = self.constructor(atmosphere.model, argdata);
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
