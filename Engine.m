classdef Engine < handle
	properties
		opts = odeset();
		integrator;
		showwarnings;
		eventmssgs = {'Crashed into planet', 'Escaped the atmosphere', 'Reached escape velocity'};
	end

	methods % Public
		% Constructor
		function self = Engine(varargin)
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
			if numel(S) < 12
				% [alt, Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r]
				S0 = self.prepare(S, pl);
			elseif numel(S) == 13
				% [rad, lat, lon, q0, q1, q2, q3, u, v, w, p, q, r]
				S0 = S;
			else
				ME = MException('Engine:integrate:input', 'Unexpected length of array: %d', numel(S));
				throw(ME);
			end

			self.opts.Events = @(t, S) self.events(t, S, pl);
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
				def = [sqrt(pl.mu / rad), 0, 0, 0, 0, 0, 0, pi/2, 0, 0, 0];

				% Complete input state with defaults
				Sc = num2cell([S(2:end), def(numel(S(2:end))+1:11)]);
				[Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r] = Sc{:};

				% Velocity components
				u =  Uinf * cos(gamma) * cos(chi);
				v =  Uinf * cos(gamma) * sin(chi);
				w = -Uinf * sin(gamma);

				% Euler -> Quaternions
				Q = [cos(ph/2)*cos(th/2)*cos(ps/2) + sin(ph/2)*sin(th/2)*sin(ps/2) ;
				     sin(ph/2)*cos(th/2)*cos(ps/2) - cos(ph/2)*sin(th/2)*sin(ps/2) ;
				     cos(ph/2)*sin(th/2)*cos(ps/2) + sin(ph/2)*cos(th/2)*sin(ps/2) ;
				     cos(ph/2)*cos(th/2)*sin(ps/2) - sin(ph/2)*sin(th/2)*cos(ps/2)];
				q0 = Q(1); q1 = Q(2); q2 = Q(3); q3 = Q(4);

				S0 = [rad; lat; lon; q0; q1; q2; q3; u; v; w; p; q; r];
			else
				ME = MException('Engine:prepare:input', 'Unexpected length of array: %d', numel(S));
				throw(ME);
			end
		end
	end

	methods (Access = protected)
		% 6-DOF equations of motion
		function dS = motion(~, ~, S, sc, pl)
			% sc = [Spacecraft]
			% pl = [Planet]

			% State variables
			Sc = num2cell(S);
			[rad, lat, ~, q0, q1, q2, q3, u, v, w, p, q, r] = Sc{:}; % ~ = lon

			% Useful state vectors
			Q = [q0; q1; q2; q3];
			U = [u; v; w];
			W = [p; q; r];

			% Quaternion Rotation (B -> V)
			Lq = [q0^2+q1^2-q2^2-q3^2, 2*(q1*q2-q0*q3)    , 2*(q0*q2+q1*q3)     ;
			      2*(q1*q2+q0*q3)    , q0^2-q1^2+q2^2-q3^2, 2*(q2*q3-q0*q1)     ;
			      2*(q1*q3-q0*q2)    , 2*(q0*q1+q2*q3)    , q0^2-q1^2-q2^2+q3^2];
			Lq(abs(Lq) < 1e-12) = 0; % for numerical stability
			Lbv = Lq;
			Lvb = Lq.';

			% Position (inertial, inertial axes)
			Uv = Lbv * U;
			drad = -Uv(3);
			dlat = Uv(1) / rad;
			dlon = Uv(2) / (rad * cos(lat));

			% Rotation (body w.r.t. local horizon)
			Wbv = W - Lvb * [dlon * cos(lat); -dlat; -dlon * sin(lat)];
			pbv = Wbv(1); qbv = Wbv(2); rqv = Wbv(3);
			Wq = [0  , -pbv, -qbv, -rqv ;
			      pbv,  0  ,  rqv, -qbv ;
			      qbv, -rqv,  0  ,  pbv ;
			      rqv,  qbv, -pbv,   0 ];
			dQ = 1/2 * Wq * Q;
			dq0 = dQ(1); dq1 = dQ(2); dq2 = dQ(3); dq3 = dQ(4);

			% Gravity force (body axes)
			Fg = Lvb * [0; 0; pl.mu * sc.m / rad^2];
			% Fg = self.gravity(t, )

			% Aerodynamic forces (body axes)
			Fa = [0; 0; 0];
			Ma = [0; 0; 0];
			% [Fa, Ma] = self.aerodynamics(t, )
			% Uinf = norm(U);
			% Udir = U / Uinf;
			% CD = 1.2; % 0.4;
			% alt = rad - pl.R;
			% [~, ~, ~, rho] = atmoscoesa(alt, 'None');
			% FD = 1/2 * rho * Uinf^2 * sc.S * CD;
			% Fa = -FD * Udir;

			% Velocity (inertial, body axes)
			F = Fg + Fa;
			dU = F / sc.m - cross(W, U);
			du = dU(1); dv = dU(2); dw = dU(3);

			% Angular velocity (body)
			M = Ma;
			dW = sc.I \ (M - cross(W, sc.I * W));
			dp = dW(1); dq = dW(2); dr = dW(3);

			dS = [drad; dlat; dlon; dq0; dq1; dq2; dq3; du; dv; dw; dp; dq; dr];
		end

		function [val, ter, dir] = events(~, ~, S, pl)
			% Can be extended by overriding / concatenating to its results
			rad = S(1);
			alt = rad - pl.R;
			Uinf = norm(S(8:10)); % u, v, w
			Uesc = sqrt(2 * pl.mu / rad);
			val = [alt - 0; alt - pl.atm.lim; Uinf - Uesc];
			dir = [-1; +1; +1];
			ter = [true; true; true];
		end

		% function Fg = gravity()

		% end

		% function [Fa, Ma] = aerodynamics(S, pl)
		% 	alpha =
		% 	beta = % = 0 in pitch-plane case
		% 	if
		% 	alpha
		% 	beta

		% end
	end
end
