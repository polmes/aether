function [t, S, te, Se, ie] = RK4(odefun, Ts, S0, opts)
	% Extract relevant options
	dts = opts.TimeStep;
	if numel(dts) > 1
		dts = reshape(dts, 2, []).';
		dts(1,1) = dts(1,1) + eps;
		NT = ceil(sum(diff([dts(:,1); Ts(2)]) ./ dts(:,2))) + 1;
	else
		dts = [eps dts];
		NT = ceil(Ts(2) / dts(1,2)) + 1;
	end

	% Initialize arrays
	t = zeros(NT, 1);
	S = zeros(NT, numel(S0));
	te = zeros(floor(NT/100), 1);
	Se = zeros(floor(NT/100), numel(S0));
	ie = zeros(floor(NT/100), 1);

	% Set initial values
	S(1,:) = S0;
	t(1) = Ts(1);

	% Set initial event values by calling ODE to set Engine properties
	odefun(t(1), S(1,:));
	ev = opts.Events(t(1), S(1,:));

	% Iterate
	m = 1;
	dt = dts(1,2);
	for n = 1:NT-1
		% 4th order Runge-Kutta
		k1 = odefun(t(n), S(n,:)).';
		k2 = odefun(t(n) + dt/2, S(n,:) + k1 * dt/2).';
		k3 = odefun(t(n) + dt/2, S(n,:) + k2 * dt/2).';
		k4 = odefun(t(n) + dt, S(n,:) + k3 * dt).';

		% Update
		S(n+1,:) = S(n,:) + 1/6 * dt * (k1 + 2*k2 + 2*k3 + k4);
		t(n+1) = t(n) + dt;

		% Check for events
		odefun(t(n+1), S(n+1,:)); % force update of Engine properties
		[val, ter, sgn] = opts.Events(t(n+1), S(n+1,:));
		idx = sign(val) ~= sign(ev) & sign(val) == sgn;
		if any(idx)
			Ne = sum(idx);
			ie(m:m+Ne) = find(idx);
			te(m:m+Ne) = repmat(t(n+1), [Ne, 1]);
			Se(m:m+Ne,:) = repmat(S(n+1), [Ne, 1]);
			if any(ter(idx))
				break;
			end
			m = m + Ne;
		end
		ev = val;

		% New dt?
		dt = dts(find(mod(t(n+1), dts(:,1)) ~= t(n+1), 1, 'last'), 2);
	end

	% Truncate arrays
	t(n+2:end) = [];
	S(n+2:end,:) = [];
	ie(m+1:end) = [];
	te(m+1:end) = [];
	Se(m+1:end,:) = [];
end
