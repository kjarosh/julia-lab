
@generated function harmonic(nums...)
	n = length(nums)
	
	args = [];
	
	for i in 1:length(nums)
		push!(args, :(1/nums[$(i)]))
	end
	
	sum = Expr(:call, :+, args...)
	
	return :($(n)/($(sum)))
end

println(harmonic(1,2,3))

