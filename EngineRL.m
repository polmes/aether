classdef EngineRL < rl.env.MATLABEnvironment & EngineGuidRate
	% Reinforcement Learning Engine - based on MATLAB's RL environment

	properties (Access = protected)
		% New state vectors
		S;
		S0;
		ev;
		ref;

		% New state scalars
		t;
		t0;
		acc;
		Umag;
		rate;
		prevU;
		prevH;

		% Initial conditions
		maxU;
		rad0;
		lat0;
		lon0;

		% Flags
		done;
		integrating;

		% New objects
		pl;
		sc;
		odefun;

		% Reinforcement Learning
		penalty;

		% For simulation only
		n;
		ts;
		Ss;
		policy;
	end

	properties (Access = protected, Constant)
		% Reinforcement Learning
		steprew = 0;

		% Percentage above maxU at which to stop integration (just in case)
		overU = 1.1;

		% For simulation only
		datadir = 'constants/';
	end

	methods
		% Contructor method creates an instance of the environment
		function self = EngineRL()
			% Initialize Observation settings
			ObservationInfo = rlNumericSpec([3 1]);
			ObservationInfo.Name = 'RL States';
			ObservationInfo.Description = 'alt, acc, Umag';

			% Initialize Action settings
			ActionInfo = rlFiniteSetSpec([1 0]);
			ActionInfo.Name = 'RL Actions';
			ActionInfo.Description = 'Roll: yes, no';

			% Call superclass method
			self@rl.env.MATLABEnvironment(ObservationInfo, ActionInfo);

			% Set global properties
			self.integrating = false;
		end

		function initial(self, S0, sc, pl, targetreward)
			% Define properties for all episodes
			self.sc = sc;
			self.pl = pl;
			self.S0 = self.prepare(S0, self.pl);

			% Maximum velocity allowed
			self.maxU = self.overU * norm(self.S0(8:10));

			% Reference state vector
			self.ref = [self.pl.atm.lim; self.maxU; self.gmax * self.g0];

			% Rewards
			self.penalty = -targetreward;

			% ODE solver
			self.odefun = @(t, S) self.motion(t, S, self.sc, self.pl);
			self.opts.Events = @(t, S) self.event(t, self.sc, self.pl);

			% For range computation
			[self.lat0, self.lon0, ~, self.rad0] = self.pl.xyz2lla(self.S0(1), self.S0(2), self.S0(3), 0);
		end

		function options(self, varargin)
			% 'RelTol', 'AbsTol', 'Integrator' key-value argument pairs
			p = inputParser;
			p.KeepUnmatched = true;
			if ~self.init
				p.addParameter('TimeStep', 0.001);
				p.addParameter('MaxTime', 2000);
				p.addParameter('MaxLoad', 40);
				p.addParameter('Policy', 'trained_upto8000');
				self.init = true;
			else
				p.addParameter('TimeStep', self.opts.TimeStep);
				p.addParameter('MaxTime', self.T);
				p.addParameter('MaxLoad', self.gmax);
				p.addParameter('Policy', self.opts.Agent);
			end
			p.parse(varargin{:});

			% Standard
			self.opts.TimeStep = p.Results.TimeStep;
			self.T = p.Results.MaxTime;
			self.gmax = p.Results.MaxLoad;

			% Reinforcement Learning
			self.opts.Agent = p.Results.Policy;
			try
				self.policy = util.open(self.opts.Agent, 'DataDir', self.datadir);
			catch
				warning('Failed to load provided policy. It is only required for simulation, ignore if training.')
			end
		end

		function Nmax = maxsteps(self)
			Nmax = ceil(self.T / self.opts.TimeStep);
		end

		% Reset environment to initial state and output initial observation
		function observation = reset(self)
			% Call existing reset method to "zero" properties
			self.initreset();

			% Initial conditions
			self.t = 0;
			self.S = self.S0.';

			% For rates
			self.prevU = norm(self.S0(8:10));
			self.prevH = self.pl.atm.lim;

			% Call ODE once to start
			self.ev = self.RK4();

			% Initial observation from state
			observation = [self.alt; self.rate; self.acc] ./ self.ref;
		end

		% Simulates the environment with the given action for one step.
		function [observation, reward, done, logs] = step(self, action)
			% Always start by calling ODE (at least once)
			[val, ter, sgn] = self.RK4();

			% Return observation from current state
			observation = [self.alt; self.rate; self.acc] ./ self.ref;

			% Check whether we need to roll or not
			% if action == 0
			if action == 1
				% Initiate roll...
				self.initroll();
				self.t0 = self.t;
				if self.showwarnings
					disp(['t = ' num2str(self.t0, '%6.2f') ' s, h = ' num2str(self.alt/1e3, '%6.2f') ' km, w = ' num2str(self.rate/1e3, '%6.2f') ' km/s, a = ' num2str(self.acc/self.g0, '%6.2f') ' g0']);
				end

				% ... and integrate to the end
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

			% Exceeded allowed time?
			done = self.t > self.T;
			if done
				warning('Exceeded maximum allowed integration time: %d s', self.T);
			end

			% Check for terminal condition + determine reward
			idx = sign(val) ~= sign(self.ev) & sign(val) == sgn;
			if any(ter(idx))
				ie = find(idx, 1);
				if self.showwarnings
					disp(['Terminal event: ' num2str(ie)]);
				end
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
			self.ev = val;

			% For compatibility
			logs = [];
		end

		function [t, S, ie] = integrate(self, S, sc, pl)
			% Reset variables for next integration
			self.initreset();

			% Initial conditions
			self.initial(S, sc, pl, 1000); % default penalty to -1000 (must be numeric)

			% Initialize arrays
			self.n = 0;
			self.ts = zeros(self.maxsteps, 1);
			self.Ss = zeros(self.maxsteps, self.NS);
			self.integrating = true;

			% Run simulation
			simulation = rlSimulationOptions('MaxSteps', self.maxsteps);
			exp = self.sim(self.policy, simulation);

			% Outputs
			t = self.ts(1:self.n);
			S = self.Ss(1:self.n,:);
			if exp.Reward.Data(end) == self.penalty
				ie = 2; % (not 1)
			else
				ie = 1;
			end
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

			% Keep track of rate of descent
			self.rate = (self.alt - self.prevH) / self.opts.TimeStep;
			self.prevH = self.alt;

			% Keep track of acceleration magnitude = rate of velocity magnitude
			self.Umag = norm(self.U);
			self.acc = (self.Umag - self.prevU) / self.opts.TimeStep;
			self.prevU = self.Umag;

			% Append velocity-based events
			val = [val; abs(self.acc/self.g0) - self.gmax; self.Umag - self.maxU; any(isnan(self.S))];
			ter = [ter; true; true; true];
			sgn = [sgn; +1; +1; +1];

			% Guidance commands
			if self.count == 2 && (t - self.t0) >= sc.tref(1)
				self.initroll();
				self.t0 = t;
			elseif self.bank && self.PRA == self.target && (max(abs(self.MRP)) < self.tolMRP || t - self.t0 - self.offtime > pi/sc.maxW)
				self.stoproll();
			elseif self.bank && (t - self.t0) > 0
				self.rateroll(sc.maxW * (t - self.t0));
			end

			% For simulation only
			if self.integrating
				self.n = self.n + 1;
				self.ts(self.n) = self.t;
				self.Ss(self.n,:) = self.S;
			end
		end

		function initreset(self)
			% Call superclass method
			initreset@EngineGuidRate(self);

			% State scalars that must be reset each time
			self.t0 = 0;
			self.done = false;
		end
	end
end
