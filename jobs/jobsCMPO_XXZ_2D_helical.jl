using Printf, Dates
include("/home/sliang/JuliaCode/JuliaCMPO/jobs/bright90.jl")

phys_model = "XXZ_2D_helical"
env = "/home/sliang/JuliaCode/JuliaCMPO"
prog = env * "/jobs/CMPO_$(phys_model).jl"

Wait = nothing
cpu_per_task = 16
tag = Dates.format(now(), "yyyy-mm-dd")

βlist = [16.0]
Jzlist = [1.0]
Jxylist = [1.0]
bondDlist = [16]
widlist = [1]
Continue = 0  #Continue > max_pow_step,  Continue = true
max_pow_step = 100

#CREAT LOG FOLDER
logdir = "/data/sliang/log/JuliaCMPO"
isdir(logdir) || mkdir(logdir)

for bondD in bondDlist
    for Jxy in Jxylist, Jz in Jzlist, width in widlist, β in βlist
        args = Dict("Jz"=>Jz,
                    "Jxy"=>Jxy,
                    "bondD"=>bondD,
                    "width"=>width,
                    "beta"=>β,
                    "max_pow_step"=>max_pow_step,
                    "Continue"=>Continue
                    )
        jobname = logdir * "/" * phys_model
        isdir(jobname) || mkdir(jobname)
        jobname = @sprintf "%s/Jz_%.2f_Jxy_%.2f_wid_%02i" jobname Jz Jxy width
        isdir(jobname) || mkdir(jobname)
        jobname = @sprintf "%s/bondD_%02i_%s" jobname bondD tag
        isdir(jobname) || mkdir(jobname)
        jobname = @sprintf "%s/beta_%.2f" jobname β

        jobid = submitJob(env, prog, args, jobname, 
                            cpu_per_task = cpu_per_task,
                            Run = true, 
                            Wait = Wait)
    end   
end      
