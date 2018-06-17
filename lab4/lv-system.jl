using CSV, DataFrames, Query
using Gadfly
using DifferentialEquations

println("Loaded libraries")

function lotka_volterra(du, u, p, t)
	du[1] = p[1] * u[1] - p[2] * u[1] * u[2]
	du[2] = -p[3] * u[2] + p[4] * u[1] * u[2]
end

function solve_lotka_volterra(p, u0, tspan)
	prob = ODEProblem(lotka_volterra, u0, tspan, p)
	return solve(prob, RK4(), dt = 0.005, dtmin = 0.001, dtmax = 0.01)
end

function experiment(id, p, u0)
	solution = solve_lotka_volterra(p, u0, (0.0, 10.0))
	dataframe = DataFrame(
		time = solution.t,
		x = map(row -> row[1], solution.u),
		y = map(row -> row[2], solution.u),
		experiment = "exp$(id)"
	)
	
	CSV.write("exp$(id).csv", dataframe, header=true)
end

function gather_results(ids...)
	results = DataFrame(
		time=Float64[],
		x=Float64[],
		y=Float64[],
		experiment=String[]
	)
	
	for id in ids[1:end]
		df = CSV.read("exp$(id).csv")
		results = vcat(results, df)
	end
	
	return results
end

function plot_results(results)
	set_default_plot_size(40cm, 15cm)
	plot(results, xgroup="experiment",
		Guide.manual_color_key("Legend",
			["pred", "prey", "diff"],
			["red", "green", "lightblue"]
		),
		Geom.subplot_grid(
			layer(x="time", y="diff", Geom.line, Theme(default_color=colorant"lightblue")),
			layer(x="time", y="pred", Geom.line, Theme(default_color=colorant"red")),
			layer(x="time", y="prey", Geom.line, Theme(default_color=colorant"green"))
		),
		Guide.xlabel("time")
	)
end

function plot_phase_space(results)
	set_default_plot_size(20cm, 20cm)
	plot(results,
		x="prey", y="pred",
		color="experiment",
		Geom.path
	)
end

println("Solving the ODE")

experiment(1, [4, 4, 1, 1], [1.0; 2.0])
experiment(2, [6, 2, 1, 2], [2.0; 4.0])
experiment(3, [3, 5, 5, 6], [2.0; 1.0])
experiment(4, [2, 3, 5, 7], [3.0; 1.0])

println("ODE solved")

gathered = gather_results(1, 2, 3, 4)

summary_table = by(gathered, :experiment, df -> DataFrame(
	prey_mean = mean(df[:x]),
	pred_mean = mean(df[:y]),
	prey_min = minimum(df[:x]),
	pred_min = minimum(df[:y]),
	prey_max = maximum(df[:x]),
	pred_max = maximum(df[:y])
))

println("Summary:")
println(summary_table)

with_difference = @from r in gathered begin
	@select {
		time = r.time,
		prey = r.x,
		pred = r.y,
		diff = r.x - r.y,
		experiment = r.experiment
	}
	@orderby time
	@collect DataFrame
end

set_default_plot_size(30cm, 40cm)
vstack(
	plot_results(with_difference),
	plot_phase_space(with_difference)
)

