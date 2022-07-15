"""
    rrule for logtrexp(tM) function where `typeof(M)=CMPSMatrix`, 
    `trace_estimator = replaced_FTLM`
"""
function ChainRules.rrule(::typeof(logtrexp), 
                          t::Real, M::CMPSMatrix{Ts,T,S,U}, 
                          trace_estimator::TraceEstimator{Tf, To}
                          ) where {Ts,T,S,U,Tf<:typeof(replaced_FTLM),To}
    @unpack options = trace_estimator
    @unpack distr, Nr, Nk, Ne, processor = options
    @unpack ψl, ψr = M
    solver = solver_function(processor)

    Ns = size(M, 1)
    Ne = min(Ne, Ns)
    χl, χr = size(ψl.Q, 1), size(ψr.Q, 1)
    
    sign(t) == 1 ? which = :LR : which=:SR
    processor == CPU ? x0 = rand(T,Ns) : x0 = CUDA.rand(T, Ns)
    e0, _, _ = eigsolve(M, x0, 1, which, ishermitian = true)
    e1 = e0[1]
    expr_Λ = e -> exp(t*(e-e1))
    expr_∂y_∂t = e -> e * exp(t*(e-e1))
    expr = (expr_Λ, expr_∂y_∂t)

    krylovdim = max(30, Ne+1)
    vals, vecs, _ = eigsolve(M, x0, Ne, which, ishermitian = true, krylovdim=krylovdim)
    eigen_vals = solver(x->x, vals[1:Ne])
    eigen_vecs = hcat(vecs[1:Ne]...)

    res = zeros(2)
    ∂y_∂Ql, ∂y_∂Qr = zeros(size(ψl.Q)), zeros(size(ψr.Q))
    ∂y_∂Rl, ∂y_∂Rr = zeros(size(ψl.R)), zeros(size(ψr.R))
    
    Nk = max(Nk, Ne)
    for r = 1: Nr
        v0 = random_unit_vector(Ns, distr)
        v0 = solver(x->x, v0)
        @unpack init_vector, weight, values, vectors = 
                itFOLM(M, init_vector = v0, Nk = Nk) |> eigensolver
        Nk = size(values,1)
        
        eigen_weight = ein"i,ij->j"(conj(v0), eigen_vecs)
        weight = vcat(eigen_weight, weight[Ne+1:end])
        values = vcat(eigen_vals, values[Ne+1:end])

        func = f -> begin
            Λ = map(f, values)
            Z = ein"i,i,i -> "(Λ, weight, conj(weight))
            return Array(Z)[1]
        end
        res = map(+, res, map(func, expr))

        Λ = map(expr_Λ, values)
        vecs = reshape(vectors, χr, χl, Nk)
        v0 = reshape(init_vector, χr, χl)

        Onel = ones(χl, χl); Onel = convert(S, Onel)
        Oner = ones(χr, χr); Oner = convert(S, Oner)
        ∂y_∂Ql_temp = -t * ein"n,n,kbn,ka,kk -> ab"(Λ, weight, conj(vecs), v0, Oner)
        ∂y_∂Qr_temp = -t * ein"n,n,bkn,ak,kk -> ab"(Λ, weight, conj(vecs), v0, Onel)
        ∂y_∂Ql = map(+, ∂y_∂Ql, ∂y_∂Ql_temp)
        ∂y_∂Qr = map(+, ∂y_∂Qr, ∂y_∂Qr_temp)

        if U <: AbstractMatrix
            ∂y_∂Rl_temp = -t * ein"n,n,kl,lbn,ka,kl -> ab"(Λ, weight, ψr.R, conj(vecs), v0, Oner)
            ∂y_∂Rr_temp = -t * ein"n,n,kl,bln,ak,kl -> ab"(Λ, weight, ψl.R, conj(vecs), v0, Onel)
        else
            Onel = ones(χl, χl, size(ψ.R,3)); Onel = convert(U, Onel)
            Oner = ones(χr, χr, size(ψ.R,3)); Oner = convert(U, Oner)
            ∂y_∂Rl_temp = -t * ein"n,n,klm,lbn,ka,klm -> ab"(Λ, weight, ψr.R, conj(vecs), v0, Oner)
            ∂y_∂Rr_temp = -t * ein"n,n,klm,bln,ak,klm -> ab"(Λ, weight, ψl.R, conj(vecs), v0, Onel)
        end
        ∂y_∂Rl = map(+, ∂y_∂Rl, ∂y_∂Rl_temp)
        ∂y_∂Rr = map(+, ∂y_∂Rr, ∂y_∂Rr_temp)
    end
    
    factor = Ns/Nr
    y, ∂y_∂t = map(x -> x * factor, res)
    ∂y_∂Ql, ∂y_∂Qr, ∂y_∂Rl, ∂y_∂Rr = map(x -> x * factor, (∂y_∂Ql, ∂y_∂Qr, ∂y_∂Rl, ∂y_∂Rr))

    function logtrexp_pullback(ȳ)
        ∂y_∂t, ∂y_∂Ql, ∂y_∂Qr, ∂y_∂Rl, ∂y_∂Rr = map(x -> x/y, (∂y_∂t, ∂y_∂Ql, ∂y_∂Qr, ∂y_∂Rl, ∂y_∂Rr))

        t̄ = ȳ * ∂y_∂t

        Q̄l = ȳ * ∂y_∂Ql
        R̄l = ȳ * ∂y_∂Rl
        Q̄r = ȳ * ∂y_∂Qr
        R̄r = ȳ * ∂y_∂Rr
        ψ̄l = CMPS_generate(Q̄l, R̄l)
        ψ̄r = CMPS_generate(Q̄r, R̄r)
        M̄ = CMPSMatrix(ψ̄l, ψ̄r)
        return ChainRules.NoTangent(), t̄, M̄, ChainRules.NoTangent()
    end
    return y, logtrexp_pullback
end