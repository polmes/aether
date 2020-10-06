classdef Engine < handle
	properties (Access = protected)
		opts = odeset();
		init = false;
		integrator;
		showwarnings;
		eventmssgs = {'Reached deploy altitude', 'Skipped the atmosphere'};

		% State scalars
		rad;
		lat;
		lon;
		alt;

		% State vectors
		Q = zeros(4, 1);
		U = zeros(3, 1);
		W = zeros(3, 1);
	end

	methods % (Access = public)
		% Constructor
		function self = Engine(varargin)
			self.options(varargin{:});
		end

		function options(self, varargin)
			% 'RelTol', 'AbsTol', 'Integrator' key-value argument pairs
			p = inputParser;
			if ~self.init
				p.addParameter('RelTol', 1e-12);
				p.addParameter('AbsTol', 1e-13);
				p.addParameter('Integrator', @ode113); % or @ode45
				p.addParameter('ShowWarnings', true);
				self.init = true;
			else
				p.addParameter('RelTol', self.opts.RelTol);
				p.addParameter('AbsTol', self.opts.AbsTol);
				p.addParameter('Integrator', self.integrator);
				p.addParameter('ShowWarnings', self.showwarnings);
			end
			p.parse(varargin{:});

			self.opts.RelTol = p.Results.RelTol;
			self.opts.AbsTol = p.Results.AbsTol;
			self.integrator = p.Results.Integrator;
			self.showwarnings = p.Results.ShowWarnings;
		end

		% Main method called to integrate in time
		function [t, S, ie] = integrate(self, T, S, sc, pl)
			% Prepare S0 if necessary
			if numel(S) < self.NS
				% [alt, Umag, gamma, chi, lat, lon, ph, th, ps, p, q, r, ...]
				S0 = self.prepare(S, pl);
			elseif numel(S) == self.NS
				% [rad, lat, lon, q0, q1, q2, q3, u, v, w, p, q, r, ...]
				S0 = S;
			else
				util.exception('Unexpected length of initial conditions array: %d', numel(S));
			end

			self.opts.Events = @(t, S) self.event(sc, pl);
			[t, S, ~, ~, ie] = self.integrator(@(t, S) self.motion(t, S, sc, pl), [0, T], S0, self.opts);

			if ~isempty(ie) && self.showwarnings
				warning(self.eventmssgs{ie});
			end
		end
	end

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

			% Inertial position and radial distance
			[x, y, z, Lei] = pl.lla2xyz(lat, lon, alt);
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

			% Euler -> Quaternions (body w.r.t. vehicle)
			Q = [cos(ph/2)*cos(th/2)*cos(ps/2) + sin(ph/2)*sin(th/2)*sin(ps/2) ;
					sin(ph/2)*cos(th/2)*cos(ps/2) - cos(ph/2)*sin(th/2)*sin(ps/2) ;
					cos(ph/2)*sin(th/2)*cos(ps/2) + sin(ph/2)*cos(th/2)*sin(ps/2) ;
					cos(ph/2)*cos(th/2)*sin(ps/2) - sin(ph/2)*sin(th/2)*cos(ps/2)];
			q0 = Q(1); q1 = Q(2); q2 = Q(3); q3 = Q(4);

			% Rotations
			Lvb = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2+q0*q3)    , 2*(q1*q3-q0*q2)     ;
					2*(q1*q2-q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q0*q1+q2*q3)     ;
					2*(q0*q2+q1*q3)    , 2*(q2*q3-q0*q1)    , q0^2-q1^2-q2^2+q3^2];
			Lev = [          cos(lon),         0,          sin(lon) ;
					-sin(lat)*sin(lon),  cos(lat), sin(lat)*cos(lon) ;
					-cos(lat)*sin(lon), -sin(lat), cos(lat)*cos(lon)];
			Lie = Lei.';
			Lib = Lvb * Lev * Lie;

			% Rotation -> Quaternions (body w.r.t. inertial)
			q0 = 1/2 * sqrt(trace(Lib) + 1);
			q1 = (Lib(2,3) - Lib(3,2)) / (4 * q0);
			q2 = (Lib(3,1) - Lib(1,3)) / (4 * q0);
			q3 = (Lib(1,2) - Lib(2,1)) / (4 * q0);

			% Velocity components (body frame)
			U = Lvb * [u; v; w];
			u = U(1); v = U(2); w = U(3);

			S0 = [x; y; z; q0; q1; q2; q3; u; v; w; p; q; r];
		end

		function NS = NS()
			NS = 13;
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
			[self.lat, self.lon, self.alt, self.rad] = pl.xyz2lla(x, y, z, t);

			% Quaternion Normalization
			self.Q = 1/norm(self.Q) * self.Q;
			q0 = self.Q(1); q1 = self.Q(2); q2 = self.Q(3); q3 = self.Q(4);

			% Quaternion Rotation (B -> I)
			Lbi = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2-q0*q3)    , 2*(q0*q2+q1*q3)     ;
			       2*(q1*q2+q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q2*q3-q0*q1)     ;
			       2*(q1*q3-q0*q2)    , 2*(q0*q1+q2*q3)    , q0^2-q1^2-q2^2+q3^2];
			Lib = Lbi.';

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
			g = pl.gravity(self.rad, self.lat, self.lon, self.alt);
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

		% Basic aerodynamics
		function [Fa, Ma] = aerodynamics(self, t, sc, pl)
			% Angle of Attack
			Uinf = norm(self.U);
			alpha = atan2(self.U(3), self.U(1));
			beta = asin(self.U(2) / Uinf);

			% Environment
			[rho, MFP, a] = pl.atm.trajectory(t, self.alt, self.lat, self.lon);
			Kn = MFP / sc.L;
			M = Uinf / a;

			% Aerodynamic coefficients
			CL = sc.Cx('CL', alpha, M, Kn);
			CD = sc.Cx('CD', alpha, M, Kn);
			Cm = sc.Cx('Cm', alpha, M, Kn) + sc.Cx('Cmq', alpha, M, Kn) * self.W(2) * sc.L / (2 * Uinf);

			% Forces and Moments
			qS = 1/2 * rho * Uinf^2 * sc.S;
			FL = qS * CL;
			FD = qS * CD;
			FC = 0;
			ML = 0;
			MM = qS * sc.L * Cm;
			MN = 0;

			% Vectors in body frame (W -> B)
			Lwb = [cos(alpha)*cos(beta), -cos(alpha)*sin(beta), -sin(alpha) ;
			       sin(beta)           ,  cos(beta)           ,  0          ;
			       sin(alpha)*cos(beta), -sin(alpha)*sin(beta),  cos(alpha)];
			Fa = Lwb * -[FD; FC; FL];
			Ma = [ML; MM; MN];
		end

		% Basic controls (damping)
		function Mc = controls(self, ~, sc)
			Mc = sc.damp * self.W;
		end

		% ODE event function
		function [val, ter, dir] = event(self, sc, pl)
			% Can be extended by overriding / concatenating to its results
			% Note: [DeployAltitude, SkipAtmosphere]
			Umag = norm(self.U);
			Ucir = sqrt(pl.mu / self.rad);
			skip = ~(self.alt > pl.atm.lim && Umag > Ucir); % EI + velocity
			val = [self.alt - sc.deploy; skip];
			dir = [-1; -1];
			ter = [true; true];
		end
	end
end
