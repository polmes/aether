classdef EngineRLL < Engine
	methods (Static)
		% Generate initial conditions S0
		function S0 = prepare(S, pl)
			% [alt, Umag, gamma, chi, lat, lon, ph, th, ps, p, q, r]

			% Altitude defaults to atmosphere limit
			if numel(S) > 0
				alt = S(1);
			else
				alt = pl.atm.lim;
			end

			% Other defaults
			% [gamma, chi, lat, lon, ph, th, ps, p, q, r]
			def = zeros(1, 10);

			% Complete input state with defaults
			Ss = num2cell([S(3:end), def(numel(S(3:end))+1:10)]);
			[gamma, chi, lat, lon, ph, th, ps, p, q, r] = Ss{:};

			% Full radius
			[x, y, z] = pl.lla2xyz(lat, lon, alt);
			rad = norm([x; y; z]);

			% Inertial velocity magnitude defaults to (circular) orbital speed
			if numel(S) > 1
				Umag = S(2);
			else
				Umag = sqrt(pl.mu / rad);
			end

			% Velocity components (vehicle frame)
			u =  Umag * cos(gamma) * cos(chi);
			v =  Umag * cos(gamma) * sin(chi);
			w = -Umag * sin(gamma);

			% Euler -> Quaternions
			Q = [cos(ph/2)*cos(th/2)*cos(ps/2) + sin(ph/2)*sin(th/2)*sin(ps/2) ;
				sin(ph/2)*cos(th/2)*cos(ps/2) - cos(ph/2)*sin(th/2)*sin(ps/2) ;
				cos(ph/2)*sin(th/2)*cos(ps/2) + sin(ph/2)*cos(th/2)*sin(ps/2) ;
				cos(ph/2)*cos(th/2)*sin(ps/2) - sin(ph/2)*sin(th/2)*cos(ps/2)];
			q0 = Q(1); q1 = Q(2); q2 = Q(3); q3 = Q(4);

			% Velocity components (body frame)
			Lvb = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2+q0*q3)    , 2*(q1*q3-q0*q2)     ;
				2*(q1*q2-q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q0*q1+q2*q3)     ;
				2*(q0*q2+q1*q3)    , 2*(q2*q3-q0*q1)    , q0^2-q1^2-q2^2+q3^2];
			U = Lvb * [u; v; w];
			u = U(1); v = U(2); w = U(3);

			S0 = [rad; lat; lon; q0; q1; q2; q3; u; v; w; p; q; r];
		end
	end

	methods (Access = protected)
		function dS = motion(self, t, S, sc, pl)
			% sc = [Spacecraft]
			% pl = [Planet]

			% State variables
			Ss = num2cell(S);
			[self.rad, self.lat, self.lon, q0, q1, q2, q3, u, v, w, p, q, r] = Ss{:};

			% Useful state vectors
			self.Q = [q0; q1; q2; q3];
			self.U = [u; v; w];
			self.W = [p; q; r];

			% Additional state scalars
			self.alt = self.rad - pl.R;

			% Quaternion Rotation (B -> V)
			Lq = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2-q0*q3)    , 2*(q0*q2+q1*q3)     ;
			      2*(q1*q2+q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q2*q3-q0*q1)     ;
			      2*(q1*q3-q0*q2)    , 2*(q0*q1+q2*q3)    , q0^2-q1^2-q2^2+q3^2];
			Lq(abs(Lq) < 1e-12) = 0; % for numerical stability
			Lbv = Lq;
			Lvb = Lq.';

			% Position (inertial, inertial axes)
			Uv = Lbv * self.U;
			drad = -Uv(3);
			dlat = Uv(1) / self.rad;
			dlon = Uv(2) / (self.rad * cos(self.lat));

			% Rotation (body w.r.t. local horizon)
			Wbv = self.W - Lvb * [dlon * cos(self.lat); -dlat; -dlon * sin(self.lat)];
			pbv = Wbv(1); qbv = Wbv(2); rqv = Wbv(3);
			Wq = [0  , -pbv, -qbv, -rqv ;
			      pbv,  0  ,  rqv, -qbv ;
			      qbv, -rqv,  0  ,  pbv ;
			      rqv,  qbv, -pbv,   0 ];
			dQ = 1/2 * Wq * self.Q;
			dq0 = dQ(1); dq1 = dQ(2); dq2 = dQ(3); dq3 = dQ(4);

			% Gravity force (body axes)
			g = pl.gravity(self.rad, self.lat, self.lon, self.alt);
			Fg = Lvb * [0; 0; sc.m * g];

			% Aerodynamic forces (body axes)
			[Fa, Ma] = self.aerodynamics(t, sc, pl);

			% Velocity (inertial, body axes)
			F = Fg + Fa;
			dU = F / sc.m - cross(self.W, self.U);
			du = dU(1); dv = dU(2); dw = dU(3);

			% Angular velocity (body)
			M = Ma;
			dW = sc.I \ (M - cross(self.W, sc.I * self.W));
			dp = dW(1); dq = dW(2); dr = dW(3);

			dS = [drad; dlat; dlon; dq0; dq1; dq2; dq3; du; dv; dw; dp; dq; dr];
		end
	end
end
