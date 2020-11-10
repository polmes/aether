classdef EngineFactory < Factory
	properties (Constant, Access = protected)
		defaults = {
			'', @Engine, ...
			'XYZ', @Engine, ...
			'RLL', @EngineRLL, ...
			'Aero', @EngineAero, ...
			'AeroDelta', @EngineAeroDelta, ...
			'Ctrl', @EngineCtrl, 'Control', @EngineCtrl, ...
			'Guid', @EngineGuid, 'Guidance', @EngineGuid, ...
			'GuidRate', @EngineGuidRate, 'GuidanceRate', @EngineGuidRate, ...
			'GuidAlt', @EngineGuidAlt, 'GuidanceAltitude', @EngineGuidAlt, ...
			'GuidAltPoly', @EngineGuidAltPoly, 'GuidanceAltitudePolynomial', @EngineGuidAltPoly, ...
			'RL', @EngineRL, 'ReinforcementLearning', @EngineRL, ...
			'RLFree', @EngineRLFree, 'ReinforcementLearningFree', @EngineRLFree, ...
			'RLStochastic', @EngineRLStochastic, 'ReinforcementLearningStochastic', @EngineRLStochastic
		};
		exception = 'Unkown engine type provided';
	end

	methods
		function self = EngineFactory(varargin)
			self@Factory(varargin);
		end

		function en = generate(self, data)
			%   data  :=  'integration' structure from case *.json

			% Generate Engine (note: first argument defines class)
			% Note: key-value options are left untouched
			en = self.constructor(data.engine);

			% Basic options
			en.options('RelTol', data.reltol, 'AbsTol', data.abstol, 'TimeStep', data.timestep, 'MaxTime', data.maxtime, 'ShowWarnings', data.verbose, 'Policy', data.policy);

			% Check if integrator is a valid function
			integrator = str2func(data.solver);
			try
				nargin(integrator);
				en.options('Integrator', integrator);
			catch
				integrator = str2func(['util.' data.solver]);
				try
					nargin(integrator);
					en.options('Integrator', integrator);
				catch
					warning('Invalid integrator function provided. Reverting back to default...');
				end
			end
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
