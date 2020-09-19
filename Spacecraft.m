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
				self.deploy = data.deploy;

				% Inertia can be either diagonal or full tensor
				I = data.inertia;
				if numel(I) == 3
					% [Ixx; Iyy; Izz]
					self.I = diag(data.inertia);
				elseif numel(I) == 6
					% [Ixx; Iyy; Izz; Ixy; Iyz; Ixz]
					self.I = diag(I(1:3)) + diag(I(4:5), 1) + diag(I(4:5), -1) + diag(I(6), 2) + diag(I(6), -2);
				elseif numel(I) == 9
					% [Ixx; Ixy; Ixz; Ixy; Iyy; Iyz; Ixz; Iyz; Izz]
					self.I = reshape(I, [3 3]).';
				else
					ME = MException('Spacecraft:constructor', 'Unexpected length of inertia vector');
					throw(ME);
				end


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
