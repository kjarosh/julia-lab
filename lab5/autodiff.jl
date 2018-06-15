# Kamil Jarosz

function simplify(ex)
	# jeżeli nie znamy wyrażenia to go nie upraszczamy
	ex
end

function simplify(ex::Expr)
	if ex.head != :call
		return ex
	end
	
	op = ex.args[1]
	# argumenty po uproszczeniu
	args = map(simplify, ex.args[2:end])
	
	if op == :+
		# nie sumujemy zer
		args = filter(a -> a != 0, args)
		
		# suma z 0 składników to 0
		if length(args) == 0
			return 0
		end
		
		# stałe sumujemy w jedną
		constant = 0
		args2 = []
		
		for arg in args
			if isa(arg, Number)
				constant += arg
			else
				push!(args2, arg)
			end
		end
		
		# jeśli stała nie jest 0 to ją dodajemy do wynikowych argumentów
		if constant != 0
			push!(args2, constant)
		end
		
		if length(args2) == 1
			return args2[1]
		else
			return Expr(:call, :+, args2...)
		end
	elseif op == :-
		a = args[1]
		b = args[2]
		
		if isa(a, Number) && isa(b, Number)
			# liczba - liczba
			return a - b
		elseif a == 0
			# 0 - b
			# tutaj b nie jest stałą bo warunek
			#   wyżej byłby prawdziwy
			return :(-$(b))
		elseif b == 0
			# a - 0
			return a
		else
			return :($(a) - $(b))
		end
	elseif op == :*
		# jedynki ignorujemy
		args = filter(v -> v != 1, args)
		
		if length(args) == 0
			# iloczyn 0 składników to 1
			return 1
		elseif any(v -> v == 0, args)
			# iloczyn 0*[...] to 0
			return 0
		end
		
		# stałe mnożymy w jedną
		constant = 1
		args2 = []
		
		for arg in args
			if isa(arg, Number)
				constant *= arg
			else
				push!(args2, arg)
			end
		end
		
		# jeśli stała nie jest 1 to ją dodajemy do wynikowych argumentów
		if constant != 1
			push!(args2, constant)
		end
		
		if length(args2) == 1
			return args2[1]
		else
			return Expr(:call, :*, args2...)
		end
	elseif op == :/
		a = args[1]
		b = args[2]
		
		# z upraszczaniem dzielenia jest taki problem, że
		#   możemy przez przypadek usunąć błąd dzielenia
		#   przez zero, dlatego generalnie nie skracamy
		
		if isa(a, Number) && isa(b, Number)
			# liczba / liczba
			return a/b
		else
			# to tutaj zachowamy błąd
			return :($(a)/$(b))
		end
	else
		# nieznany operator to nie upraszczamy
		return ex
	end
end

function autodiff(ex::Number, sym::Symbol)::Number
	# pochodna z liczby po symbolu to 0
	0
end

function autodiff(ex::Symbol, sym::Symbol)::Number
	if ex == sym
		# pochodna z x po x to 1
		return 1
	else
		# pochodna z symbolu po x to 0
		return 0
	end
end

function autodiff(ex::Expr, sym::Symbol)::Expr
	if ex.head != :call
		throw(ArgumentError("Unknown expression: " * string(ex)))
	end
	
	op = ex.args[1]
	args = ex.args[2:end]
	
	if op == :+ || op == :-
		# pochodna sumy to suma pochodnych
		return Expr(:call, op, map(a -> autodiff(a, sym), args)...)
	elseif op == :*
		# pochodna iloczynu
		ret = []
		
		for (i, a) in enumerate(args)
			# args[i] = a
			toMultiply = [autodiff(a, sym), args[1:end .!= i]...]
			push!(ret, Expr(:call, :*, toMultiply...))
		end
		
		return Expr(:call, :+, ret...)
	elseif op == :/
		# pochodna ilorazu
		a = args[1]
		ap = autodiff(a, sym)
		b = args[2]
		bp = autodiff(b, sym)
		
		numerator = :($(ap)*$(b)-$(a)*$(bp))
		denominator = :($(a)*$(b)*$(a)*$(b))
		return :($(numerator)/$(denominator))
	elseif op == :^
		# pochodna potęgi
		a = args[1]
		ap = autodiff(a, sym)
		b = args[2]
		bp = autodiff(b, sym)
		
		return :($(a)^$(b) * ($(b)*$(ap)/$(a) + $(bp)*log($(a))))
	else
		throw(ArgumentError("Unknown operator: " * string(op)))
	end
end

function test_diff(expr, sym)
	dexpr = autodiff(expr, sym)
	#println(dexpr)
	
	dexpr = simplify(dexpr)
	println(dexpr)
	
	println()
	#dump(dexpr)
end

test_diff(:(1/x*5+(2+2)), :x)
test_diff(:(1/3*x^8 + 12*x^2 + 7), :x)
test_diff(:(2*x*y*z + 2*y + x^x), :x)

