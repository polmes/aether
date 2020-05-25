function Y = LHS(inputs, NS, dim)
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

	% LHS sampling algorithm
	Y = zeros(NS, d);
	for i = 1:n
		% Generate equiprobability partitions
		part = inputs(i).partition(NS);

		% Find corresponding dimensions, generate RVs, and randomly rearrange them
		k = sum(dvec(1:i-1));
		for j = (k+1):(k + dvec(i))
			perm = randperm(NS);
			Y(perm,j) = part(1:NS) + (part(2:NS+1) - part(1:NS)) .* rand(1, NS);
		end
	end
end
