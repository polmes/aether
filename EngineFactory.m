classdef EngineFactory < Factory
	properties (Constant, Access = protected)
		defaults = {'', @Engine, 'XYZ', @Engine, 'RLL', @EngineRLL, 'Aero', @EngineAero, 'AeroDelta', @EngineAeroDelta, 'Ctrl', @EngineCtrl, 'Control', @EngineCtrl, 'Guid', @EngineGuid, 'Guidance', @EngineGuid, 'GuidRate', @EngineGuidRate, 'GuidanceRate', @EngineGuidRate, 'GuidAlt', @EngineGuidAlt, 'GuidanceAltitude', @EngineGuidAlt};
		exception = 'Unkown engine type provided';
		opts = {'RelTol', 'AbsTol', 'ShowWarnings', 'Integrator'};
	end

	methods
		function self = EngineFactory(varargin)
			self@Factory(varargin);
		end

		function sc = generate(self, data)
			%   data  :=  'integration' structure from case *.json

			% Generate Engine (note: first argument defines class)
			% Note: key-value options are left untouched
			sc = self.constructor(data.engine);
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
