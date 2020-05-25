function [lambda, phi, d] = KLE(l, a, d, t, err)
	% [X, d] = uq.KLE(l, a, d, t, NS, mu, err)
	% Performs the Karhunen--Loève Expansion (KLE)
	% of a random process X(t,w) with exponential covariance
	% of the form Cxx = exp(-abs(t1-t2)/l), with t in [-a, +a]
	%
	% Input arguments:
	%	l   - Correlation length
	%	a   - Limits of range of t in [-a, +a]
	%	d   - Either the number of eigenvalues to use, d (e.g., 10),
	%	      or the mean-square error allowed, alpha (e.g., 0.99)
	%	t   - Number of "timesteps" in variable t of the process,
	%	      or array of "timesteps" in which to evaluate X(t,w)
	%	err - Logical to distinguish between taking d as the number
	%	      of eigenvalues (false) or the error (true)
	%	      (default: false)
	%
	% Output values:
	%	lambda - Eigenvalues of the KLE [1 x d]
	%	phi    - Eigenfunctions of the KLE [NT x d]
	%	d      - Minimum number of eigenvalues to satisfy err constraints

	%% INPUT PARSING

	% Handle optional/default arguments
	if nargin < 4
		error('Expected at least 4 arguments');
	elseif nargin < 6
		if nargin < 5 || isempty(err)
			err = false; % explicit d by default
		end
	else
		error('Expected a max of 5 arguments');
	end

	% Switch d and alpha depending on mode
	if err
		alpha = d;
		d = 500;
		k = 50;
	end

	% Points t in which to evaluate random process
	if isscalar(t)
		NT = t;
		t = linspace(-a, a, NT).'; % default to linear spacing
	elseif isvector(t)
		if size(t, 1) == 1 && size(t, 2) > 1
			t = t.'; % transpose to fix dimensions
		end
		NT = numel(t);
	else
		error('Unexpected dimension for t');
	end

	%% ANALYTICAL SOLUTION OF THE EIGENPROBLEM

	% Init
	w = zeros(1, d);
	opts = optimset('Display', 'off');

	% Odd i
	odds = 1:2:d;
	eq = @(w) 1/l - w * tan(w * a); % == 0
	for i = odds
		w(i) = fsolve(eq, pi/(8*a) + pi/(2*a) * (i-1), opts);
	end

	% Even i
	evens = 2:2:d;
	eq = @(w) w + 1/l * tan(w * a); % == 0
	for i = evens
		w(i) = fsolve(eq, pi/(8*a) + pi/(2*a) * (i-1), opts);
	end

	% Eigenvalues
	lambda = 2 * l ./ (l^2 * w.^2 + 1);
	if err
		i = 1;
		now = lambda(i);
		all = sum(lambda(1:k));
		while now/all < alpha
			i = i + 1;
			now = now + lambda(i);
			all = all + lambda(i+k);
		end
		d = i;
		lambda = lambda(1:d);
		odds = 1:2:d;
		evens = 2:2:d;
	end

	% Eigenfunctions
	phi = zeros(NT, d);
	phi(:, odds) = cos(w(odds) .* t) ./ sqrt(a + sin(2 * w(odds) * a) ./ (2 * w(odds)));
	phi(:, evens) = sin(w(evens) .* t) ./ sqrt(a - sin(2 * w(evens) * a) ./ (2 * w(evens)));
end
