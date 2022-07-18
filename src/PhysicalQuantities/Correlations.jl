#module Correlations
"""
    The local two-time correlation functions: C(τ) = -G(τ) = ⟨A(τ)B(0)⟩
"""
function correlation_2time(τ::Number, A::AbstractMatrix,B::AbstractMatrix,
                            ψl::AbstractCMPS, ψr::AbstractCMPS, W::AbstractCMPO, β::Real)
    K = ψl * W * ψr 
    K = symmetrize(K)
    e, v = eigensolver(K)
    min = minimum(e); e = e .- min
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        num += exp(-β*e[i] + τ*(e[i] - e[j])) * A[i,j] * B[j,i]
    end
    return num/den
end
correlation_2time(τ::Number, A::AbstractMatrix, B::AbstractMatrix, ψ::AbstractCMPS, W::AbstractCMPO, β::Real) = 
    correlation_2time(τ, A, B, ψ, ψ, W, β)


"""
    Masubara frequency Green's functions: defalt type = :b
    G(iωn) = 1/Z ∑ Anm Bmn (exp(-βEn) - λexp(-βEm)) / (iωn - Em + En)
"""
function LehmannGFKernel(z::Number, En::Real, Em::Real, β::Real; type::OperatorType = Bose)
    type == Bose ? λ = 1.0 : λ = -1.0
    if type == Bose && z==0 && abs(En - Em) < 1.e-10
        return -β*exp(-β*Em)
    else
        num = exp(-β*En) - λ*exp(-β*Em)
        den = z - Em + En
        return num/den
    end
end

function Masubara_freq_GF(n::Integer, A::AbstractMatrix,B::AbstractMatrix,
                        ψl::AbstractCMPS, ψr::AbstractCMPS, W::AbstractCMPO, β::Real; 
                        type::OperatorType = Bose)
    K = ψl * W * ψr
    e, v = symeigen(K)
    min = minimum(e); e = e .- min
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e) |> sum
    num = 0.0
    iωn = 1.0im * Masubara_freq(n,β,type=type)
    for i = 1: length(e), j = 1: length(e)
        num += A[i,j] * B[j,i] * LehmannGFKernel(iωn, e[i], e[j], β, type=type)
    end
    return num/den
end
Masubara_freq_GF(n::Integer, A::AbstractMatrix,B::AbstractMatrix, 
    ψ::AbstractCMPS, W::AbstractCMPO, β::Real; type::OperatorType = Bose) =
    Masubara_freq_GF(n, A, B, ψ, ψ, W, β, type = type)


"""
    Lehmann representation of spectral function
"""
function Lehmann_spectral_function(ω::Real, A::AbstractMatrix,B::AbstractMatrix,
                                ψl::AbstractCMPS, ψr::AbstractCMPS, W::AbstractCMPO, β::Real; 
                                η::Real=0.01, 
                                type::OperatorType = Bose)
    type == Bose ? λ = 1.0 : λ = -1.0
    K = ψl * W * ψr
    e, v = symeigen(K)
    min = minimum(e); e = e .- min
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        num += A[i,j] * B[j,i] * 
                (exp(-β*e[i]) - λ*exp(-β*e[j])) * 
                delta(ω - e[j] + e[i], η)
    end
    return 2π*num/den
end
Lehmann_spectral_function(ω::Real, A::AbstractMatrix,B::AbstractMatrix, 
    ψ::AbstractCMPS, W::AbstractCMPO, β::Real; η::Real=0.01, type::OperatorType = Bose) =
    Lehmann_spectral_function(ω, A, B, ψ, ψ, W, β, η=η, type = type)
Lehmann_A = Lehmann_spectral_function


"""
    Lehmann representation of the structure factor
"""
function Lehmann_structure_factor(ω::Real, A::AbstractMatrix,B::AbstractMatrix,
        ψl::AbstractCMPS, ψr::AbstractCMPS, W::AbstractCMPO, β::Real; 
        η::Real=0.01, 
        type::OperatorType = Bose)
    type == Bose ? λ = 1.0 : λ = -1.0
    K = ψl * W * ψr
    e, v = symeigen(K)
    min = minimum(e); e = e .- min
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        num += A[i,j] * B[j,i] * exp(-β*e[i]) * delta(ω - e[j] + e[i], η)
    end
    return 2π*num/den
end
Lehmann_structure_factor(ω::Real, A::AbstractMatrix,B::AbstractMatrix, 
        ψ::AbstractCMPS, W::AbstractCMPO, β::Real; η::Real=0.01, type::OperatorType = Bose) =
    Lehmann_structure_factor(ω, A, B, ψ, ψ, W, β, η=η, type = type)
Lehmann_S = Lehmann_structure_factor

#end  # module Correlations
