
function f1()
	s = Vector{String}(100000)
	
	for i = 1:length(s)
		s[i] = string(i)
	end
end

function f2()
	s = Vector{String}(10000)
	
	for i = 1:length(s)
		s[i] = string(i)
	end
end


function test()
	for i = 1:500
		f1()
		f2()
	end
end

test()
@time test()

Profile.init(n=10^7, delay = 0.00001)
@profile test()
Profile.print(format=:flat)

# Wyniki:
# 
# delay   | f1 count | f2 count | f1 %
# -------------------------------------
# 0       | N/A      | N/A      | 90.00
# -------------------------------------
# 0.5     | 6        | 1        | 85.71
# 0.3     | 6        | 1        | 85.71
# 0.1     | 32       | 5        | 86.48
# 0.1     | 33       | 2        | 94.28
# 0.05    | 64       | 7        | 90.14
# 0.05    | 65       | 6        | 91.54
# 0.01    | 377      | 30       | 92.62
# 0.01    | 329      | 32       | 91.13
# 0.005   | 671      | 59       | 91.91
# 0.005   | 671      | 61       | 91.66
# 0.001   | 3554     | 318      | 91.78
# 0.001   | 3613     | 290      | 92.56
# 0.0001  | 61467    | 5249     | 92.13
# 0.0001  | 54516    | 4809     | 91.89
# 0.00001 | 208978   | 18508    | 91.86

