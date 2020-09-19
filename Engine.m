classdef Engine < handle
	properties
		opts = odeset();
		integrator;
		showwarnings;
		eventmssgs = {'Reached deploy altitude', 'Skipped the atmosphere'}; % , 'Reached escape velocity'};

		% State vectors
		X = zeros(3, 1);
		Q = zeros(4, 1);
		U = zeros(3, 1);
		W = zeros(3, 1);
	end

	methods % Public
		% Constructor
		function self = Engine(varargin)
			self.options(varargin{:});
		end

		function options(self, varargin)
			% 'RelTol', 'AbsTol', 'Integrator' key-value argument pairs
			p = inputParser;
			p.addParameter('RelTol', 1e-12);
			p.addParameter('AbsTol', 1e-13);
			p.addParameter('Integrator', @ode113); % or @ode45
			p.addParameter('ShowWarnings', true);
			p.parse(varargin{:});

			self.opts.RelTol = p.Results.RelTol;
			self.opts.AbsTol = p.Results.AbsTol;
			self.integrator = p.Results.Integrator;
			self.showwarnings = p.Results.ShowWarnings;
		end

		% Main method called to integrate in time
		function [t, S, ie] = integrate(self, T, S, sc, pl)
			% Prepare S0 if necessary
			if numel(S) < 13
				% [alt, Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r]
				S0 = self.prepare(S, pl);
			elseif numel(S) == 13
				% [rad, lat, lon, q0, q1, q2, q3, u, v, w, p, q, r]
				S0 = S;
			else
				ME = MException('Engine:integrate:input', 'Unexpected length of array: %d', numel(S));
				throw(ME);
			end

			self.opts.Events = @(t, S) self.events(t, S, sc, pl);
			[t, S, ~, ~, ie] = self.integrator(@(t, S) self.motion(t, S, sc, pl), [0, T], S0, self.opts);

			if ~isempty(ie) && self.showwarnings
				warning(self.eventmssgs{ie});
			end
		end
	end

	methods (Static)
		% Generate initial conditions S0
		function S0 = prepare(S, pl)
			if numel(S) < 13
				% [alt, Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r]

				% Full radius
				if numel(S) > 0
					alt = S(1);
				else
					alt = pl.atm.lim; % default: atmosphere limit
				end
				rad = pl.R + alt;

				% Rest of defaults using (circular) orbital speed
				% def = [sqrt(pl.mu / rad), 0, 0, 0, 0, 0, 0, pi/2, 0, 0, 0];
				def = [sqrt(pl.mu / rad), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

				% Complete input state with defaults
				Ss = num2cell([S(2:end), def(numel(S(2:end))+1:11)]);
				[Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r] = Ss{:};

				% Velocity components (vehicle frame)
				u =  Uinf * cos(gamma) * cos(chi);
				v =  Uinf * cos(gamma) * sin(chi);
				w = -Uinf * sin(gamma);

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
			else
				ME = MException('Engine:prepare:input', 'Unexpected length of array: %d', numel(S));
				throw(ME);
			end
		end
	end

	methods (Access = protected)
		% 6-DOF equations of motion
		function dS = motion(self, t, S, sc, pl)
			% sc = [Spacecraft]
			% pl = [Planet]

			% State variables
			Ss = num2cell(S);
			[rad, lat, lon, q0, q1, q2, q3, u, v, w, p, q, r] = Ss{:};

			% Useful state vectors
			self.X = [rad; lat; lon];
			self.Q = [q0; q1; q2; q3];
			self.U = [u; v; w];
			self.W = [p; q; r];

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
			dlat = Uv(1) / rad;
			dlon = Uv(2) / (rad * cos(lat));

			% Rotation (body w.r.t. local horizon)
			Wbv = self.W - Lvb * [dlon * cos(lat); -dlat; -dlon * sin(lat)];
			pbv = Wbv(1); qbv = Wbv(2); rqv = Wbv(3);
			Wq = [0  , -pbv, -qbv, -rqv ;
			      pbv,  0  ,  rqv, -qbv ;
			      qbv, -rqv,  0  ,  pbv ;
			      rqv,  qbv, -pbv,   0 ];
			dQ = 1/2 * Wq * self.Q;
			dq0 = dQ(1); dq1 = dQ(2); dq2 = dQ(3); dq3 = dQ(4);

			% Gravity force (body axes)
			Fg = Lvb * [0; 0; pl.mu * sc.m / rad^2];

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

		% function Fg = gravity(self, ~, sc, pl)
		% end

		function [Fa, Ma] = aerodynamics(self, t, sc, pl)
			% Angle of Attack
			Uinf = norm(self.U);
			alpha = atan2(self.U(3), self.U(1));
			beta = asin(self.U(2) / Uinf);

			% Environment
			[rho, MFP, a] = pl.atm.trajectory(t, self.X(1) - pl.R, self.X(2), self.X(3));
			Kn = MFP / sc.L;
			M = Uinf / a;

			% Aerodynamic coefficients
			CL = sc.Cx('CL', alpha, M, Kn);
			CD = sc.Cx('CD', alpha, M, Kn);
			Cm = sc.Cx('Cm', alpha, M, Kn) + sc.Cx('Cmq', alpha, M, Kn) * self.W(2);

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

		function [val, ter, dir] = events(~, ~, S, sc, pl)
			% Can be extended by overriding / concatenating to its results
			% Note: [DeployAltitude, SkipAtmosphere, EscapeVelocity]
			rad = S(1);
			alt = rad - pl.R;
			Uinf = norm(S(8:10)); % u, v, w
			Ucir = sqrt(pl.mu / rad);
			% Uesc = sqrt(2) * Ucir; % sqrt(2 * pl.mu / rad);
			skip = ~(alt > pl.atm.lim && Uinf > Ucir); % EI + velocity
			val = [alt - sc.deploy; skip]; % Uinf - Uesc];
			dir = [-1; -1]; % +1];
			ter = [true; true]; % true];
		end
	end
end
