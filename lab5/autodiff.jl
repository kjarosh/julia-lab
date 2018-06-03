
function simplify(ex)
	ex
end

function simplify(ex::Expr)
	if ex.head != :call
		return ex
	end
	
	op = ex.args[1]
	args = map(simplify, ex.args[2:end])
	if op == :+
		args = filter(a -> a != 0, args)
		
		if length(args) == 0
			return 0
		end
		
		constant = 0
		args2 = []
		
		for arg in args
			if isa(arg, Number)
				constant += arg
			else
				push!(args2, arg)
			end
		end
		
		if constant != 0
			push!(args2, constant)
		end
		
		if length(args2) == 1
			return args2[1]
		else
			return Expr(:call, :+, args2...)
		end
	elseif op == :-
		a = simplify(args[1])
		b = simplify(args[2])
		
		if isa(a, Number) && isa(b, Number)
			return a - b
		elseif a == 0
			return Expr(:call, :-, b)
		elseif b == 0
			return a
		else
			return Expr(:call, :-, args...)
		end
	elseif op == :*
		args = map(simplify, args)
		args = filter(v -> v != 1, args)
		
		if length(args) == 0
			return 1
		elseif any(v -> v == 0, args)
			return 0
		end
		
		if length(args) == 1
			return args[1]
		else
			return Expr(:call, :*, args...)
		end
	elseif op == :/
		a = simplify(args[1])
		b = simplify(args[2])
		
		if isa(a, Number) && isa(b, Number)
			return a/b
		elseif a == 0
			return 0
		else
			return :($(a)/$(b))
		end
	end
end

function autodiff(ex::Number, sym::Symbol)::Number
	0
end

function autodiff(ex::Symbol, sym::Symbol)::Number
	if ex == sym
		return 1
	else
		return 0
	end
end

function autodiff(ex::Expr, sym::Symbol)::Expr
	if ex.head != :call
		throw(DomainError())
	end
	
	op = ex.args[1]
	args = ex.args[2:end]
	if op == :+ || op == :-
		return Expr(:call, op, map(a -> autodiff(a, sym), args)...)
	elseif op == :*
		ret = []
		
		for (i, a) in enumerate(args)
			toMultiply = [autodiff(a, sym), args[1:end .!= i]...]
			push!(ret, Expr(:call, :*, toMultiply...))
		end
		
		if length(ret) == 0
			return Expr(:call, :+, 0)
		end
		
		return Expr(:call, :+, ret...)
	elseif op == :/
		a = args[1]
		ap = autodiff(a, sym)
		b = args[2]
		bp = autodiff(b, sym)
		
		numerator = :($(ap)*$(b)+$(a)*$(bp))
		denominator = :($(a)*$(b)*$(a)*$(b))
		return :($(numerator)/$(denominator))
	end
end

expr = :(1/x*5+(2+2))
sym = :x
dexpr = simplify(autodiff(expr, sym))

println(dexpr)
dump(dexpr)
x = 2
println(eval(dexpr))

