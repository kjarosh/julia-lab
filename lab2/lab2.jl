import Base.*
import Base.convert
import Base.promote_rule

# Hierarchia typow

function type_hierarchy(t)
    if(t != Any)
        type_hierarchy(supertype(t))
        print(" -> ")
    end
    
    print(t)
end

type_hierarchy(Float32)


# Struktura

struct G{N} <: Integer
    x::Int
    
    function G(m)
        if(m >= N)
            m = m % N
        end
        
        if(m < 0 || gcd(m, N) != 1)
            throw(DomainError())
        end
        
        new(m)
    end
end

# Mnozenie

function *{N}(a::G{N}, b::G{N})
    return G{N}((a.x * b.x) % N)
end

function *{N}(a::G{N}, b::Integer)
    return a * G{N}(b)
end

function *{N}(a::Integer, b::G{N})
    return G{N}(a) * b
end

# Konwersja

function convert{N}(::Type{G{N}}, v::Int64)
    return G{N}(v)
end

# Promocja

promote_rule(::Type{G{N}}, ::Type{T}) where {T <: Integer, N} = G{N}

# Potegowanie

function ^{N}(a::G{N}, b::Integer)
    ret::G{N} = 1
    for i = 1:b
       ret = ret * a
    end
    return ret
end

function ^{N,K}(a::G{N}, b::G{K})
    return a ^ b.x
end

# Okres

function period{N}(a::G{N})
    for i = 1:N
        if a ^ i == 1
            return i
        end
    end
    
    return -1
end

# Element odwrotny

function inverse{N}(a::G{N})
    for i = 1:N
        try
            if a * i == 1
                return G{N}(i)
            end
        catch
            continue
        end
    end
    
    throw(DomainError())
end

# Moc zbioru elementów

function card{N}(::Type{G{N}})
    count = 0
    
    for i = 0:N
        try
            G{N}(i)
            count += 1
        catch
            continue
        end
    end
    
    return count
end

# Testowanie

println(G{13}(7) * G{13}(3))

println(promote_type(G{5}, Int8))

println(G{7}(5)^5)

println(period(G{1023}(1022)))

println(inverse(G{1023}(1019)))

println(card(G{1029}))


# RSA

N = 55
c = G{N}(17)
b = G{N}(4)

r = period(b)
println(r)

d = inverse(c)
println(d)

a = b ^ d
println(a)

println(b, " ", (a ^ c))

