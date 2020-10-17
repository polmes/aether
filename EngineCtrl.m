classdef EngineCtrl < EngineAero
	properties (Access = protected)
		% New state scalars
		bank = false;
		hold = false;
		back = false;
		free = false;
		dir = +1;
		count = 1;
		t0 = 0;
		Q0 = zeros(4, 1);
		Qir = zeros(4, 1);
		Qir0 = zeros(4, 1);
		alpha0 = 0;
		MRP = zeros(3, 1);
	end

	properties (Access = protected, Constant)
		tolbeta = 0.02;
		tolMRP = 0.001;
	end

	methods (Access = protected)
		function Mc = controls(self, t, Ma, sc)
			% Common
			Wdir = self.Urel / norm(self.Urel);

			% Rate
			Wref = zeros(3, 1) + self.bank * self.dir * sc.W * Wdir;
			dWref = zeros(3, 1);
			deltaW = self.W - Wref;

			% Attitude - reference w.r.t. inertial (by adding body @ t0 w.r.t. inertial @ t0 + reference @ t w.r.t. body @ t0)
			PRA = self.dir * sc.W * (t - self.t0);
			PRV = Wdir;
			q0 = cos(PRA/2); q1 = PRV(1) * sin(PRA/2); q2 = PRV(2) * sin(PRA/2); q3 = PRV(3) * sin(PRA/2);
			Qref = [q0, -q1, -q2, -q3;
			        q1,  q0,  q3, -q2;
			        q2, -q3,  q0,  q1;
			        q3,  q2, -q1,  q0];
			Qri = Qref * self.Q0; % quaternion addition
			self.Qir = zeros(4, 1) + self.bank * [Qri(1); -Qri(2:4)] + self.hold * self.Qir; % inertial w.r.t. reference

			% Attitude - body w.r.t. reference
			q0 = self.Q(1); q1 = self.Q(2); q2 = self.Q(3); q3 = self.Q(4);
			Qref = [q0, -q1, -q2, -q3 ;
			        q1,  q0,  q3, -q2 ;
			        q2, -q3,  q0,  q1 ;
			        q3,  q2, -q1,  q0];
			Qbr = Qref * self.Qir;
			self.MRP = Qbr(2:4) / (1 + Qbr(1)); % Quaternions -> Modified Rodrigues Parameters

			% Lyapunov-derived control law
			ID = self.free * diag([true; false; true]) + ~self.free * eye(3);
			Mext = ID * Ma;
			Mc = sc.I * (dWref - cross(self.W, Wref)) + cross(self.W, sc.I * self.W) - ID * diag(sc.hold) * self.MRP - diag(sc.damp) * deltaW - Mext;

			% Limit RCS torque to max
			% if any(abs(Mc) > sc.maxMc) && self.bank
			% 	Mc = Mc * min(sc.maxMc ./ abs(Mc));
			% else
			% 	Mc(abs(Mc) > sc.maxMc) = sign(Mc(abs(Mc) > sc.maxMc)) .* sc.maxMc(abs(Mc) > sc.maxMc);
			% end
		end

		function [val, ter, dir] = event(self, t, sc, pl)
			% Call superclass method
			[val, ter, dir] = event@Engine(self, t, sc, pl);

			% Start/stop bank angle rotations
			% States:
			%   bank = while rotating
			%   hold = while holding attitude
			%   back = while rotating back
			%   free = while free-pitching
			if ~self.bank && t >= sc.tref(self.count)
				% Start new bank angle rotation, remembering initial attitude
				self.bank = true;
				self.hold = false;
				self.free = false;
				self.t0 = t;
				self.Q0 = self.Q;
				self.alpha0 = self.alpha;
				self.dir = mod(self.count, 2) * 2 - 1;
				if self.dir > 0
					self.Qir0 = [self.Q0(1); -self.Q0(2:4)];
					self.back = false;
				else
					self.back = true;
				end
				self.count = self.count + 1;
			elseif self.bank && sign(self.alpha) ~= sign(self.alpha0) && abs(self.beta) < self.tolbeta
				% Reached final attitude, now hold to keep beta ~ 0
				self.bank = false;
				self.hold = true;
				if self.back
					self.Qir = self.Qir0;
				end
			elseif self.hold && ~self.back && abs(self.beta) > self.tolbeta
				% While holding, attitude has been perturbed - fix it
				self.bank = true;
				self.hold = false;
				self.t0 = t;
				self.Q0 = self.Q;
				self.dir = -sign(self.alpha) * sign(self.beta);
			elseif ~self.free && self.hold && self.back && max(self.MRP) < self.tolMRP
				% Reached stable attitude, stop holding pitch
				self.free = true;
			end

			% Append new event outputs
			val = [val; self.bank];
			ter = [ter; false];
			dir = [dir; 0];
		end
	end
end
