classdef Spacecraft < handle
	properties
		m; % mass [kg]
		L; % characteristic length or diameter [m]
		R; % nose radius [m]
		S; % reference surface area [m^2]
		I; % inertia matrix [kg.m^2]
		db; % struct with aerodynamic coefficients f(alpha, M, Kn)
		deploy; % altitude at which to deploy drogue/parachutes [m]
	end

	properties (Constant, Access = protected)
		datadir = 'constants/';
	end

	methods
		% Constructor
		function self = Spacecraft(data)
			if nargin
				% Note: data *will* have the following properties since they are taken from defaults if not provided
				self.m = data.mass;
				self.L = data.length;
				self.R = data.nose;
				self.I = diag(data.inertia);
				self.deploy = data.deploy;

				% Store database as struct
				self.db = util.open(data.database, 'DataDir', self.datadir);
			end
		end

		% Aerodynamic coefficients interpolant
		function Cx = Cx(self, str, alpha, M, Kn)
			Cx = interpn(self.db.alpha, self.db.M, self.db.Kn, self.db.(str), alpha, M, Kn);
		end
	end
end
