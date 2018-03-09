function likelihood(vm::VectorModel, doc::DenseArray{Tw},
		window_length::Int, min_prob::Float64=1e-5)

	N = length(doc)
	if N == 1 return (0., 0) end

	z = zeros(T(vm))

	m = MeanCounter(Float64)

	for i in 1:N
		x = doc[i]

		window = window_length
		z[:] = 0.

		expected_pi!(z, vm, x)

		for j in max(1, i - window):min(N, i + window)
			if i == j continue end

			y = doc[j]

			local_ll = Kahan(Float64)
			for s in 1:T(vm)
				if z[s] < min_prob continue end
				In = view(vm, x, s)

				add!(local_ll, z[s] * exp(Float64(log_skip_gram(vm, x, s, y))))
			end
			add!(m, log(sum(local_ll)))
		end
	end
	return mean(m), m.n
end

function likelihood(vm::VectorModel, dict::Dictionary, f::IO,
		window_length::Int; batch::Int=16777216)
	buffer = zeros(Int32, batch)
	j = 0
	ll = 0.
	while !eof(f)
		doc = read_words(f, dict, buffer, length(buffer), -1)
		if length(doc) == 0 break end
		#println(j)
		local_ll, n = likelihood(vm, doc, window_length)
		ll += local_ll
		j += n
	end
	return ll / j
end
