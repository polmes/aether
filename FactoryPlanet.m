classdef FactoryPlanet < Factory
	properties (Constant, Access = protected)
		defaults = {'Spherical', @Planet};
		exception = 'Unkown planetary model provided';
		datadir = 'constants/';
	end

	methods
		function self = FactoryPlanet(varargin)
			self = self@Factory(varargin);
		end

		function pl = generate(self, data, at)
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
				catch
					ME = MException(class(self), 'Custom planetary body is missing some properties');
					throw(ME);
				end
			else
				%   "body": "Earth" or "Mars" or ...
				try
					known = util.open('solarsystem', 'DataDir', self.datadir);
					body = known.table(upper(data.body),:);
					argdata.R = body.radius;
					argdata.M = body.mass;
				catch
					ME = MException(class(self), 'Unknown planetary body with name: %s', data.body);
					throw(ME);
				end
			end
			argdata.atm = at;

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
