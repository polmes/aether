classdef EngineXYZ < Engine
	methods (Static)
		% Generate initial conditions S0
		function S0 = prepare(S, pl)
			% Call superclass method
			% [rad; lat; lon; q0; q1; q2; q3; u; v; w; p; q; r];
			S0 = prepare@Engine(S, pl);

			% XYZ from coordinates
			rad = S0(1); lat = S0(2); lon = S0(3);
			x =  rad * cos(lat) * sin(lon);
			z = -rad * cos(lat) * cos(lon);
			y = -rad * sin(lat);

			% Replace RLL with XYZ
			% [x; y; z; q0; q1; q2; q3; u; v; w; p; q; r];
			S0 = [x; y; z; S0(4:13)];
		end
	end

	methods (Access = protected)
		% 6-DOF equations of motion
		function [dS, dU] = motion(self, t, S, sc, pl)
			% sc = [Spacecraft]
			% pl = [Planet]

			% State variables
			Ss = num2cell(S);
			[x, y, z, q0, q1, q2, q3, u, v, w, p, q, r] = Ss{:};

			% Useful state vectors
			X = [x; y; z];
			self.Q = [q0; q1; q2; q3];
			self.U = [u; v; w];
			self.W = [p; q; r];

			% Additional state scalars
			self.rad = norm(X);
			self.lat = asin(-y / self.rad);
			self.lon = asin(x / (self.rad * cos(self.lat)));
			self.alt = self.rad - pl.R;

			% Quaternion Rotation (B -> I)
			Lq = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2-q0*q3)    , 2*(q0*q2+q1*q3)     ;
			      2*(q1*q2+q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q2*q3-q0*q1)     ;
			      2*(q1*q3-q0*q2)    , 2*(q0*q1+q2*q3)    , q0^2-q1^2-q2^2+q3^2];
			Lq(abs(Lq) < 1e-12) = 0; % for numerical stability
			Lbi = Lq;
			Lib = Lq.';

			% Position (inertial, inertial axes)
			dX = Lbi * self.U;
			dx = dX(1); dy = dX(2); dz = dX(3);

			% Rotation (body w.r.t. inertial)
			Wq = [0, -p, -q, -r ;
			      p,  0,  r, -q ;
			      q, -r,  0,  p ;
			      r,  q, -p,  0];
			dQ = 1/2 * Wq * self.Q;
			dq0 = dQ(1); dq1 = dQ(2); dq2 = dQ(3); dq3 = dQ(4);

			% Gravity force (body axes)
			g = pl.gravity(self.rad, self.lat, self.lon);
			Fg = Lib * (-sc.m * g) * (X / self.rad);

			% Aerodynamic forces (body axes)
			[Fa, Ma] = self.aerodynamics(t, sc, pl);

			% Control moments (body axes)
			Mc = self.controls(t, sc);

			% Velocity (inertial, body axes)
			F = Fg + Fa;
			dU = F / sc.m - cross(self.W, self.U);
			du = dU(1); dv = dU(2); dw = dU(3);

			% Angular velocity (body)
			M = Ma + Mc;
			dW = sc.I \ (M - cross(self.W, sc.I * self.W));
			dp = dW(1); dq = dW(2); dr = dW(3);

			dS = [dx; dy; dz; dq0; dq1; dq2; dq3; du; dv; dw; dp; dq; dr];
		end
	end
end
