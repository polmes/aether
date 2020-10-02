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
			if numel(S) < 13
				% [alt, Uinf, gamma, chi, lat, lon, ph, th, ps, p, q, r]
				S0 = self.prepare(S, pl);
			elseif numel(S) == 13
				% [rad, lat, lon, q0, q1, q2, q3, u, v, w, p, q, r]
				S0 = S;
			else
				util.exception('Unexpected length of array: %d', numel(S));
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
				util.exception('Unexpected length of array: %d', numel(S));
			end
		end
	end

	methods (Abstract, Access = protected)
		% 6-DOF equations of motion
		dS = motion(self, t, S, sc, pl);
	end

	methods (Access = protected)
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
