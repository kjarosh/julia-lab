module GraphsOpt

using StatsBase

export GraphVertex, NodeType, Person, Address,
		generate_random_graph, get_random_person,
		get_random_address, generate_random_nodes,
		convert_to_graph,
		bfs, check_euler, partition,
		graph_to_str, node_to_str,
		test_graph

# Główne optymalizacje:
# 1. Generowanie grafu bezpośrednio do postaci użytkowej,
#    bez użycia macierzy.
# 2. Użycie IOBuffer dla zamiany na string.
# 3. Przekazywanie N i K jako parametry funkcji.
# 4. Podanie konkretnych typów.
# 5. Ustalenie struktur jako niemodyfikowalne.

# Czas wykonania przed optymalizacją: ~14.0s
# Czas wykonania po optymalizacji:    ~ 0.3s

abstract type NodeType end

struct Person <: NodeType
	name ::String
end

struct Address <: NodeType
	streetNumber ::Int8
end

function str_node(n::Person)
	string("Person: ", n.name)
end

function str_node(n::Address)
	string("Street nr: ", n.streetNumber)
end

mutable struct GraphVertex
	value ::NodeType
	neighbors ::Vector{GraphVertex}
end

function get_random_person()
	Person(randstring())
end

function get_random_address()
	Address(rand(1:100))
end

function random_graph(N::Int64, K::Int64)
	graph = Vector{GraphVertex}(N)
	
	for i = 1:length(graph)
		node = rand() > 0.5 ? get_random_person() : get_random_address()
		graph[i] = GraphVertex(node, GraphVertex[])
	end
	
	for s in sample(1:N*N, K, replace=false)
		i, j = ind2sub((N, N), s)
		push!(graph[i].neighbors, graph[j])
		push!(graph[j].neighbors, graph[i])
	end
	
	graph
end

function is_connected(graph::Vector{GraphVertex})
	remaining = Set(graph)
	bfs(Set{GraphVertex}(), remaining)
	return isempty(remaining)
end

function bfs{T}(visited::Set{T}, remaining::Set{T})
	first = next(remaining, start(remaining))[1]
	
	q::Set{T} = Set()
	push!(q, first)
	
	push!(visited, first)
	delete!(remaining, first)

	while !isempty(q)
		v = pop!(q)

		for n in v.neighbors
			if !(n in visited)
				push!(q, n)
				push!(visited, n)
				delete!(remaining, n)
			end
		end
	end
end

function check_euler(graph::Vector{GraphVertex})
	if is_connected(graph)
		return all(map(v -> iseven(length(v.neighbors)), graph))
	end
		"Graph is not connected"
end

function graph_to_str(buf::IOBuffer, graph::Vector{GraphVertex})
	graph_str::String = ""
	for v in graph::Vector{GraphVertex}
		println(buf, "****")
		println(buf, str_node(v.value))
		print(buf, "Neighbors: ")
		println(buf, string(length(v.neighbors)))
	end
end

function test_graph()
	buf::IOBuffer = IOBuffer()
	
	N = 800
	K = 10000
	
	for i = 1:100
		graph = random_graph(N, K)
		
		graph_to_str(buf, graph)
		println(check_euler(graph))
	end
end

test_graph()

Profile.clear()
@profile test_graph()
@time test_graph()
Profile.print(format=:flat)

end

