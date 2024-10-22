classdef PlanetRotating < Planet
	properties
		W; % angular velocity [rad/s]
		lon0; % initial longitude offset [rad]
	end

	methods
		% Constructor
		function self = PlanetRotating(data)
			% Call superclass constructor
			self@Planet(data);

			% Append rotation properties
			self.W = 2*pi / data.T;
			self.lon0 = self.W * seconds(timeofday(data.datetime));
		end

		% ECI -> ECEF (vectorized)
		function [xe, ye, ze, Lie] = xyz2ecef(self, x, y, z, t)
			% Indices for sparse rotation matrix
			N = numel(t);
			i1 = 1:3:(1+(N-1)*3);
			i2 = 2:3:(2+(N-1)*3);
			i3 = 3:3:(3+(N-1)*3);
			i = [i1, i2, i3, i1, i3];
			j = [i1, i2, i3, i3, i1];

			% ECI -> ECEF
			Wt = self.lon0 + self.W * t;
			k = [cos(Wt); ones(N, 1); cos(Wt); sin(Wt); -sin(Wt)];
			Lie = sparse(i, j, k);
			Xi = reshape([x, y, z].', [3*N, 1]);
			Xe = Lie * Xi;

			% Vectors
			xe = Xe(1:3:end);
			ye = Xe(2:3:end);
			ze = Xe(3:3:end);
		end

		% ECI -> ECEF
		function Xe = X2ecef(self, X, t)
			Wt = self.lon0 + self.W * t;
			Lie = [ cos(Wt), 0, sin(Wt) ;
			              0, 1,       0 ;
			       -sin(Wt), 0, cos(Wt)];
			Xe = Lie * X;
		end

		% ECEF -> ECI
		% Note: this is only called at initial timestep
		function [x, y, z, Lei] = ecef2xyz(self, xe, ye, ze)
			Lei = [cos(self.lon0), 0, -sin(self.lon0) ;
			                    0, 1,              0  ;
			       sin(self.lon0), 0,  cos(self.lon0)];
			X = Lei * [xe; ye; ze];
			x = X(1); y = X(2); z = X(3);
		end
	end

	methods (Sealed)
		% Atmosphere rotates with the planet
		function vel = atmspeed(self, rad, lat)
			vel = self.W * rad .* cos(lat);
		end
	end
end
