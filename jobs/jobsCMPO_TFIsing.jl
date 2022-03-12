using Printf

beta_min = 1.0
beta_max = 40.0
beta_step = 0.1
J_Range = [1.0]
Γ_Range = [1.0]
bondD_Range = [8.0]

power = [0, 100]

#CREAT LOG FOLDER
logdir = "/data/sliang/log/CMPO"
isdir(logdir) || mkdir(logdir)
logdir = logdir*"/TFIsing"
isdir(logdir) || mkdir(logdir)

#CLEAR LOG FOLDER
#if length(readdir(logdir))!=0
#    for file in readdir(logdir)
#    run(```rm $(logdir)/$(file)```) end
#end


for j = 1:length(J_Range), g = 1:length(Γ_Range), d = 1:length(bondD_Range)
    J = @sprintf "%.2f" J_Range[j]
    Γ = @sprintf "%.2f" Γ_Range[g]
    bondD = @sprintf "%02i" bondD_Range[d]
    for p in 1:length(power)
        power_step = power[p]
        power_step == 0 ? job_name = "CMPO_TFIsing_J_$(J)_G_$(Γ)_D_$(bondD)" : 
            job_name = "CMPO_TFIsing_Power_J_$(J)_G_$(Γ)_D_$(bondD)"
        log_file_path = "$(logdir)/$(job_name).log"
    
        R = rand(Int)
        io = open("tmp$(R).sh","w+")
        write(io,"#!/bin/bash -l \n\
            #SBATCH --partition=a100 \n\
            #SBATCH --time=999 \n\
            #SBATCH --job-name=$(job_name) \n\
            #SBATCH --output=$(log_file_path) \n\
            #SBATCH --error=$(log_file_path) \n\
            julia --project=/home/sliang/JuliaCode/mycMPO \
                /home/sliang/JuliaCode/mycMPO/jobs/CMPO_TFIsing.jl \
                --J $(J) --gamma $(Γ) \
                --beta_min $(beta_min) --beta_max $(beta_max) --beta_step $(beta_step) \
                --bondD $(bondD) --power_step $(power_step)"
            )
        close(io)
        println("Run: tmp$(R).sh")
        run(```sbatch tmp$(R).sh```)
        sleep(0.1)
        rm("tmp$(R).sh")
    end
end

# \n\ 换行顶格，后一个\之后不能有任何空格