@with_kw struct EvaluateOptions{Tinit<:Union{AbstractCMPS, Nothing}, 
                                Tsolver<:Function, 
                                Ttrace<:EstimatorType,
                                Thermitian<:Union{Bool, Nothing},
                                Tcontinue<:Union{Bool, Integer},
                                Tcompress<:CompressOptions,
                                Toptim<:Optim.Options}
    init::Tinit = nothing
    solver::Tsolver = cpu_solver
    trace_estimator::Ttrace = nothing
    hermitian::Thermitian = nothing
    Continue::Tcontinue = false
    max_pow_step::Integer = 100
    group::Integer = 1
    tag::String = Dates.format(now(), "yyyy-mm-dd")
    show_trace::Bool = false
    store_trace::Bool = true
    compress_options::Tcompress = CompressOptions(CompressOptions(),
                        show_trace = show_trace,
                        store_trace = store_trace,
                        trace_estimator = trace_estimator)
    #optim option for hermitian_evaluate
    optim_options::Toptim = Optim.Options(f_tol = eps(), 
                                  g_tol = 1.e-8,
                                  iterations = 10000, 
                                  store_trace = store_trace,
                                  show_trace = show_trace, 
                                  show_every = 10)
end