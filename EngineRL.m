classdef EngineRL < rl.env.MATLABEnvironment & EngineGuidRate
	% Reinforcement Learning Engine - based on MATLAB's RL environment

	properties (Access = protected)
		% New state vectors
		S;
		S0;
		ev;

		% New state scalars
		% n;
		t;
		t0;
		rad0;
		lat0;
		lon0;
		maxU;
		done;

		% New objects
		pl;
		sc;
		odefun;
	end

	properties (Access = protected, Constant)
		steprew =  0;
		penalty = -1000;
	end

	methods
		% Contructor method creates an instance of the environment
		% Change class name and constructor name accordingly
		function self = EngineRL()
			% Initialize Observation settings
			ObservationInfo = rlNumericSpec([2 1]);
			ObservationInfo.Name = 'RL States';
			ObservationInfo.Description = 'alt, decel';

			% Initialize Action settings
			ActionInfo = rlFiniteSetSpec([1 0]);
			ActionInfo.Name = 'RL Actions';

			% Call superclass method
			self@rl.env.MATLABEnvironment(ObservationInfo, ActionInfo);
		end

		function initial(self, S0, sc, pl)
			% Define properties for all episodes
			self.sc = sc;
			self.pl = pl;
			self.S0 = self.prepare(S0, self.pl);

			% Maximum velocity allowed
			self.maxU = 1.1 * norm(self.S0(8:10));

			% ODE solver
			self.odefun = @(t, S) self.motion(t, S, self.sc, self.pl);
			self.opts.Events = @(t, S) self.event(t, self.sc, self.pl);

			% For range computation
			[self.lat0, self.lon0, ~, self.rad0] = self.pl.xyz2lla(self.S0(1), self.S0(2), self.S0(3), 0);
		end

		function Nmax = maxsteps(self)
			Nmax = ceil(self.T / self.opts.TimeStep);
		end

		% Apply system dynamics and simulates the environment with the
		% given action for one step.
		function [observation, reward, done, logs] = step(self, action)
			% Always start by calling ODE (at least once)
			[val, ter, sgn] = self.RK4();

			% Check whether we need to roll or not
			% if action == 0
			if action == 1
				% Roll and integrate until maneuver is completed
				self.initroll();
				self.t0 = self.t;
				goal = self.count + 1;
				while self.count < goal
					[val, ter, sgn] = self.RK4();
				end
			elseif action ~= 0
				util.exception('Unexpected action value');
			end

			% If we have completed roll, integrate to the end
			if self.count == 3
				done = false;
				while ~done
					[val, ter, sgn] = self.RK4();
					if any(ter(sign(val) ~= sign(self.ev) & sign(val) == sgn))
						% done = true;
						break; % to avoid overwriting ev
					end
					done = self.t > self.T;
					self.ev = val;
				end
			end

			% Return observation from current state
			observation = [self.alt; norm(self.dU)];

			% Exceeded allowed time?
			done = self.t > self.T;
			if done
				warning('Exceeded maximum allowed integration time: %d s', self.T);
			end

			% Check for terminal condition + determine reward
			idx = sign(val) ~= sign(self.ev) & sign(val) == sgn;
			if any(ter(idx))
				ie = find(idx);
				% disp(['Terminal: ' num2str(ie)]);
				if ie == 1
					% Reached deploy altitude
					ran = self.pl.greatcircle(self.rad0, self.lat0, self.lon0, self.rad, self.lat, self.lon);
					reward = ran/1e3; % [km]
				elseif ie >= 2
					% Skipped the atmosphere or exceeded velocity limit
					reward = self.penalty;
				else
					util.exception('How did we get here?');
				end
				done = true;
			else
				reward = self.steprew; % self.opts.TimeStep;
			end

			% Update counters
			% self.n = self.n + 1;
			self.ev = val;

			% For compatibility
			logs = [];
		end

		% Reset environment to initial state and output initial observation
		function observation = reset(self)
			% Call existing reset method to "zero" properties
			self.initreset();

			% Initial conditions
			% self.n = 1;
			self.t = 0;
			self.S = self.S0.';

			% Call ODE once to start
			self.ev = self.RK4();

			% Initial observation from state
			observation = [self.alt; norm(self.dU)];
		end
	end

	methods (Access = protected)
		function [val, ter, sgn] = RK4(self)
			% Fixed and constant timestep
			dt = self.opts.TimeStep;

			% 4th-order Runge-Kutta
			k1 = self.odefun(self.t, self.S).';
			k2 = self.odefun(self.t + dt/2, self.S + k1 * dt/2).';
			k3 = self.odefun(self.t + dt/2, self.S + k2 * dt/2).';
			k4 = self.odefun(self.t + dt, self.S + k3 * dt).';

			% Update
			self.S = self.S + 1/6 * dt * (k1 + 2*k2 + 2*k3 + k4);
			self.t = self.t + dt;

			% Check for events
			self.odefun(self.t, self.S); % force update of Engine properties
			[val, ter, sgn] = self.opts.Events(self.t, self.S);
		end

		function [val, ter, sgn] = event(self, t, sc, pl)
			% Call super-superclass method
			[val, ter, sgn] = event@EngineAero(self, t, sc, pl);

			% Append velocity-based event
			val = [val; norm(self.dU)/9.80665 - 20; any(isnan(self.S))];
			ter = [ter; true; true];
			sgn = [sgn; +1; +1];

			% Only keep stop / rate limiting conditions
			if self.bank && self.PRA == self.target && (max(abs(self.MRP)) < self.tolMRP || t - self.t0 - self.offtime > pi/sc.maxW)
				self.stoproll();
			elseif self.bank && (t - self.t0) > 0
				self.rateroll(sc.maxW * (t - self.t0));
			end
		end

		function initreset(self)
			% Call superclass method
			initreset@EngineGuidRate(self);

			% New state vector
			self.S = zeros(13, 1);

			% New state scalar
			self.t0 = 0;
			self.done = false;
		end
	end
end
