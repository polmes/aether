classdef PlanetFactory < Factory
	properties (Constant, Access = protected)
		defaults = {'Spherical', @PlanetSpherical, 'Rotating', @PlanetSphericalRotating, 'SphericalRotating', @PlanetSphericalRotating, 'WGS', @PlanetWGS};
		exception = 'Unkown planetary model provided';
		datadir = 'constants/';
	end

	methods
		function self = PlanetFactory(varargin)
			self@Factory(varargin);
		end

		function pl = generate(self, data, at, dateandtime)
			%   data    :=  'planet' structure from case *.json
			%   at      :=  Atmosphere object from FactoryAtmosphere

			% Note: data *will* have the following properties since they are taken from defaults if not provided
			argdata = struct();
			if isstruct(data.body)
				%   "body": {
				%       "radius": 6371e3,
				%       "mass": 5.97237e24
				%   }
				try
					argdata.R = data.body.radius;
					argdata.M = data.body.mass;
					argdata.T = data.body.period;
				catch
					util.exception('Custom planetary body is missing some properties');
				end
			else
				%   "body": "Earth" or "Mars" or ...
				try
					known = util.open('solarsystem', 'DataDir', self.datadir);
					body = known(upper(data.body),:);
					argdata.R = body.radius;
					argdata.M = body.mass;
					argdata.T = body.period;
				catch
					util.exception('Unknown planetary body with name: %s', data.body);
				end
			end
			argdata.atm = at;
			argdata.datetime = datetime(dateandtime, 'InputFormat', 'yyyy/MM/dd HH:mm:ss');

			% Generate Planet (note: first argument defines class)
			pl = self.constructor(data.type, argdata);
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
