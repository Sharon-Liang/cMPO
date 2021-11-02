#module PhysicalObservables
#include("Setup.jl")

function make_operator(Op::AbstractArray, dim::Int)
    eye = Matrix(1.0I, dim, dim)
    return eye ⊗ Op ⊗ eye
end

function make_operator(Op::AbstractArray, ψ::cmps)
    eye = Matrix(1.0I, size(ψ.Q))
    return eye ⊗ Op ⊗ eye
end

"""
The thermal average of local opeartors ===============================
"""
function thermal_average(Op::AbstractArray, ψ::cmps, W::cmpo, β::Real)
    #eye = Matrix(1.0I, size(ψ.Q))
    #Op = eye ⊗ Op ⊗ eye
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(-β*K)
    m = maximum(e)
    Op = v' * Op * v
    den = exp.(e .- m) |> sum
    num = exp.(e .- m) .* diag(Op) |> sum
    return num/den
end

function thermal_average(Op::AbstractArray, ψ::cmps, β::Real)
    K = ψ * ψ |> symmetrize |> Hermitian
    e, v = eigen(-β*K)
    m = maximum(e)
    Op = v' * Op * v
    den = exp.(e .- m) |> sum
    num = exp.(e .- m) .* diag(Op) |> sum
    return num/den
end

"""
Thermal dynamic quanties =============================================
"""
function partitian(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    num = trexp(-β*K)
    den = trexp(-β*H)
    return exp(num.max - den.max) * num.res/den.res
end

function partitian!(ψ::cmps, W::cmpo, β::Real)
    """
    no correspondence to a physical partitian function
    (ψ is not a normalized eigen state)
    """
    K = ψ * W * ψ |> symmetrize |> Hermitian
    return trexp(-β*K)
end

function free_energy(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    res = logtrexp(-β*K)- logtrexp(-β*H)
    return -1/β * res
end

function free_energy(param::Array{T,3} where T<:Number, W::cmpo, β::Real)
    free_energy(tocmps(param), W, β)
end

function energy(ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    H = ψ * ψ |> symmetrize |> Hermitian
    eng = thermal_average(K, ψ, W, β) - thermal_average(H, ψ, β)
    return eng
end

function specific_heat(ψ::cmps, W::cmpo, β::Real; method::Symbol = :ndiff)
    if method == :adiff
        K = ψ * W * ψ |> symmetrize |> Hermitian
        H = ψ * ψ |> symmetrize |> Hermitian
        K2 = K * K
        H2 = H * H
        c = thermal_average(K2, ψ, W, β) - thermal_average(K, ψ, W, β)^2
        c -= thermal_average(H2, ψ, β) - thermal_average(H, ψ, β)^2
    elseif method == :ndiff
        e = b -> energy(ψ, W, b)
        c = -central_fdm(5, 1)(e, β)
    else @error "method should be :adiff or :ndiff"
    end
    return β^2 * c
end


function entropy(ψ::cmps, W::cmpo, β::Real)
    s = energy(ψ,W,β) - free_energy(ψ,W,β)
    return β*s
end


"""
The local two-time correlation functions
"""
function correlation_2time(τ::Number, A::AbstractArray,B::AbstractArray,
                           ψ::cmps, W::cmpo, β::Real)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        num += exp(-β*e[i]- m + τ*(e[i] - e[j])) * A[i,j] * B[j,i]
    end
    return num/den
end

function check_anomalous_term(A::AbstractArray,B::AbstractArray,
    ψ::cmps, W::cmpo, β::Real)
    #check anomalous term of bosonic Masubara correlations
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum

    c = 0.
    for i = 1: length(e), j = 1: length(e)
        if e[i] == e[j]
            c +=β*exp(-β*e[j]-m) * A[i,j] * B[j,i]
        end
    end
    return c       
end

function f(b::Real, e1::Real, e2::Real, m::Real)
    #e^(-b*e1) - e^(-b*e2) / (e2 - e1)
    if abs(e2 - e1) < 1.e-10
        return exp(-b*e1 - m) * b
    else
        num = exp(-b*e1 - m) - exp(-b*e2 - m)
        den = e2 - e1
        return num/den
    end
end

function Masubara_freq_GF(n::Integer, A::AbstractArray,B::AbstractArray,
                        ψ::cmps, W::cmpo, β::Real)
    # masubara frequency Green's functions for bosonic operators
    ωn = Masubara_freq(n,β,type=:b)
    λ = 1.0
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    if ωn != 0
        for i = 1: length(e), j = 1: length(e)
            up = exp(-β*e[i]-m) - λ*exp(-β*e[j]-m)
            up = up * A[i,j] * B[j,i]
            down = 1.0im * ωn - e[j] + e[i]
            num += up/down
        end
    else
        for i = 1: length(e), j = 1: length(e)
            num -= A[i,j]*B[j,i]*f(β,e[i],e[j],m)
        end
    end
    return num/den
end

function Masubara_freq_T1(n::Integer, A::AbstractArray,B::AbstractArray,
    ψ::cmps, W::cmpo, β::Real)
    # ∑_mn Cmn(iωn)/(Em - En) for bosonic operators
    if n == 0 @error "Error: n should not be 0." end
    ωn = Masubara_freq(n,β,type=:b)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        up = A[i,j] * B[j,i] * f(β,e[i],e[j],m)
        down = 1.0im * ωn - e[j] + e[i]
        num += up/down
    end
    return num/den
end

function spectral_density(ω::Real,A::AbstractArray,B::AbstractArray,
                             ψ::cmps, W::cmpo, β::Real; η::Float64 = 0.05)
    # ρ(ω) = 2Imχ(ω) = -2ImG(ω)
    K = ψ * W * ψ |> symmetrize |> Hermitian
    e, v = eigen(K)
    m = maximum(-β * e)
    A = v' * A * v
    B = v' * B * v
    den = exp.(-β * e .- m) |> sum
    num = 0.0
    for i = 1: length(e), j = 1: length(e)
        res = exp(-β*e[i]-m) - exp(-β*e[j]-m)
        res = res * A[i,j] * B[j,i] * delta(ω+e[i]-e[j],η)
        num += res
    end
    return 2π*num/den
end

function structure_factor(ω::Real, A::AbstractArray,B::AbstractArray,
                        ψ::cmps, W::cmpo, β::Real; η::Float64 = 0.05, method::Symbol=:S)
    if method == :S
        K = ψ * W * ψ |> symmetrize |> Hermitian
        e, v = eigen(K)
        m = maximum(-β * e)
        A = v' * A * v
        B = v' * B * v
        den = exp.(-β * e .- m) |> sum
        num = 0.0
        for i = 1: length(e), j = 1: length(e)
            num += exp(-β*e[i]-m)*A[i,j]*B[j,i]*delta(ω+e[i]-e[j], η)
        end
        return num/den * 2π
    elseif method == :F 
        if ω != 0
            fac = 2/(1 - exp(-β*ω))
            K = ψ * W * ψ |> symmetrize |> Hermitian
            e, v = eigen(K)
            m = maximum(-β * e)
            A = v' * A * v
            B = v' * B * v
            den = exp.(-β * e .- m) |> sum
            num = 0.0
            for i = 1: length(e), j = 1: length(e)
                res = exp(-β*e[i]-m) - exp(-β*e[j]-m)
                res = res * A[i,j] * B[j,i] * delta(ω+e[i]-e[j],η)
                num += res
            end
            return fac*π*num/den
        else
            @error "ω should not be 0!"
        end
    else
        @error "method should be :S for 'spectral representation' 
                or :F for 'fluctuation-dissipation theorem'."
    end       
end

#end  # module PhysicalObservables
