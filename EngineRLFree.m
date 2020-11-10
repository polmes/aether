classdef EngineRLFree < EngineRL
	methods
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
				disp(['t = ' num2str(self.t0, '%6.2f') ' s, h = ' num2str(self.alt/1e3, '%6.2f') ' km, w = ' num2str(self.rate/1e3, '%6.2f') ' km/s, a = ' num2str(self.acc/self.g0, '%6.2f') ' g0']);

				% ... and integrate until maneuver is completed
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

			% Exceeded allowed time?
			done = self.t > self.T;
			if done
				warning('Exceeded maximum allowed integration time: %d s', self.T);
			end

			% Check for terminal condition + determine reward
			idx = sign(val) ~= sign(self.ev) & sign(val) == sgn;
			if any(ter(idx))
				ie = find(idx);
				disp(['Terminal event: ' num2str(ie)]);
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
	end

	methods (Access = protected)
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
			val = [val; abs(self.acc/self.g0) - self.maxG; self.Umag - self.maxU; any(isnan(self.S))];
			ter = [ter; true; true; true];
			sgn = [sgn; +1; +1; +1];

			% Guidance commands
			% Only keep stop / rate limiting conditions
			if self.bank && self.PRA == self.target && (max(abs(self.MRP)) < self.tolMRP || t - self.t0 - self.offtime > pi/sc.maxW)
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
	end
end
