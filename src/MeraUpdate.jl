"""
    adaptive_mera_update: update the isometry using iterative SVD update with line search.
    `interpolate_isometry(p1,p2,θ)`: interpolate between two isometries
"""
function interpolate_isometry(p1::AbstractMatrix, p2::AbstractMatrix, θ::Real)
    """ interpolate two isometries
        θ = π/2 : mix = p1
        θ = 0   : mix = p2
    """
    mix = sin(θ) * p1 + cos(θ) * p2
    F = svd(mix)
    return F.U * F.Vt 
end


function adaptive_mera_update(ψ0::AbstractCMPS, χ::Integer, β::Real; 
    options::MeraUpdateOptions = MeraUpdateOptions(trace_estimator=nothing))
    @unpack (atol, ldiff_tol, maxiter, interpolate,
            store_trace, show_trace, trace_estimator) = options
    step = 1
    #logfidelity0 = logfidelity(ψ0, ψ0, β)
    logfidelity0 = 9.9e9
    loss(p_matrix) = logfidelity(project(ψ0, p_matrix), ψ0, β, trace_estimator)

    Q = symmetrize(ψ0.Q)
    _, v = eigensolver(Q)
    p_current = v[:, end-χ+1:end]
    
    loss_previous = 9.9e9
    loss_current = loss(p_current)
    adiff = abs(loss_current - logfidelity0)
    ldiff = abs(loss_current - loss_previous)
    
    trace = MeraUpdateTrace()
    step_info = MeraUpdateStep(step, π, ldiff, exp(-adiff))
    if options.store_trace push!(trace, step_info) end
    if options.show_trace
        println("-----------------------------MERA update------------------------------")
        println("step           θ                 loss_diff             fidelity      \n")
        println("----  -------------------  --------------------   -------------------\n")
        println(step_info) 
    end

    while step < options.maxiter
        step += 1   
        grad = Zygote.gradient(x -> loss(x), p_current)[1]
        F = svd(grad)
        p_next = F.U * F.Vt
 
        #https://mathoverflow.net/questions/262560/natural-ways-of-interpolating-unitary-matrices
        #https://groups.google.com/forum/#!topic/manopttoolbox/2zhx67doXaU
        #interpolate between unitary matrices
        θ = π
        proceed = options.interpolate
        while proceed
            θ = θ/2
            if θ < π/(1.9^12) #12-times bisection, cos(θ) = 0.9999989926433588
                p_next = p_current
                proceed = false
            else
                p_interpolate = interpolate_isometry(p_next, p_current, θ)
                loss_interpolate = logfidelity(project(ψ0, p_interpolate), ψ0, β, trace_estimator)
                if loss_interpolate > loss_current
                    p_next = p_interpolate
                    proceed = false
                end
            end     
        end
        p_current = p_next
        
        loss_current = loss(p_current)
        adiff = abs(loss_current - logfidelity0)
        ldiff = abs(loss_current - loss_previous)
        loss_previous = loss_current

        #store_trace
        step_info = MeraUpdateStep(step, θ, ldiff, exp(-adiff))
        if options.store_trace push!(trace, step_info) end 
        if options.show_trace println(step_info) end

        if adiff < options.atol || ldiff < options.ldiff_tol break end
    end
    ψ = project(ψ0, p_current)
    return MeraUpdateResult(ψ, trace)
end