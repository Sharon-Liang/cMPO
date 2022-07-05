"""
`ln(Tr[exp(tM)])` function for a hermitian matrix `M`, `t` is a number
"""
function logtrexp end
    
function logtrexp(t::Real, M::AbstractMatrix)
    M = symmetrize(M)
    vals, _ = eigensolver(M)
    return logsumexp(t*vals)
end

logtrexp(t::Real, M::CMPSMatrix{T}) where T = logtrexp(t, Matrix(M))

function logtrexp(t::Real, M::CMPSMatrix{T}, method::Function) where T
    sign(t) == 1 ? which = :LR : which=:SR
    e0, _, _ = eigsolve(M, size(M,1), 1, which, ishermitian = true)
    e0 = e0[1]
    expr = e -> exp(t * (e - e0))
    res = method(M, expr)[1]
    return log(res) + t*e0
end