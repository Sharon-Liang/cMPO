using Printf
include("/home/sliang/JuliaCode/JuliaCMPO/jobs/bright90.jl")

phys_model = "XXZ"
env = "/home/sliang/JuliaCode/JuliaCMPO"
prog = env * "/jobs/CMPO_$(phys_model).jl"

bi = 8.5
bf = 20.0
bstep = 0.1
init = bi - bstep
Continue = true

Jzlist = [1.0]
Jxylist = [1.0]

bondDlist = [16]

#CREAT LOG FOLDER
logdir = "/data/sliang/log/JuliaCMPO"
isdir(logdir) || mkdir(logdir)

for Jz in Jzlist, Jxy in Jxylist, bondD in bondDlist
    args = Dict("Jz"=>Jz,
                "Jxy"=>Jxy,
                "bondD"=>bondD,
                "bi"=>bi,
                "bf"=>bf,
                "bstep"=>bstep,
                "init"=>init,
                "Continue"=>Continue)
    jobname = logdir * "/" * phys_model
    isdir(jobname) || mkdir(jobname)
    jobname = @sprintf "%s/Jz_%.2f_Jxy_%.2f_wid_01" jobname Jz Jxy
    isdir(jobname) || mkdir(jobname)
    jobname = @sprintf "%s/bondD_%02i" jobname bondD
    isdir(jobname) || mkdir(jobname)
    jobname = @sprintf "%s/bi_%.2f_bf_%.2f_bstep_%.2f" jobname bi bf bstep

    jobid = submitJob(env, prog, args, jobname, Run = true)   
end