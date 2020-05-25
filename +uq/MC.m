function Y = MC(inputs, NS, dim)
	if nargin < 3
		dim = 1;
	end

	% Total number of dimensions
	n = numel(inputs);
	if isscalar(dim)
		d = dim * n;
		dvec = repelem(dim, n);
	else
		d = sum(dim);
		dvec = dim;
	end

	% Generate random samples with corresponding distribution
	Y = zeros(NS, d);
	for i = 1:n
		k = sum(dvec(1:i-1));
		idx = (k+1):(k + dvec(i));
		Y(:,idx) = inputs(i).random(NS, dvec(i));
	end
end
