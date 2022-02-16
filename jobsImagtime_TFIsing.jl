using Printf

function writeln(io::IO, xs...)
    write(io, xs...)
    write(io,"\n")
end

betaRange = [1.0, 2.0, 4.0, 6.0, 8.0, 10.0, 20.0, 30.0, 40.0]
gRange =[1.0]

#CREAT LOG FOLDER
logdir = "/home/sliang/JuliaCode/mycMPO/log/ising/imagtime"
isdir(logdir) || mkdir(logdir)

#CLEAR LOG FOLDER
if length(readdir(logdir))!=0
    for file in readdir(logdir)
    run(```rm $(logdir)/$(file)```) end
end

for j = 1:length(gRange)
    g = @sprintf "%.1f" gRange[j]
    for b in 1:length(betaRange)
        beta = @sprintf "%.1f" betaRange[b]
        R = rand(Int)
        io = open("tmp$(R).sh","w+")
        writeln(io,"#!/bin/bash -l")
        writeln(io,"#SBATCH --partition=a100")
        writeln(io,"#SBATCH --nodes=1")
        writeln(io,"#SBATCH --time=999")
        writeln(io,"#SBATCH --job-name=Imagtime_TFIsing")
        writeln(io,"#SBATCH --output=$(logdir)/g_$(g)_beta_$(beta).log")
        writeln(io,"#SBATCH --error=$(logdir)/g_$(g)_beta_$(beta).log")
        writeln(io,"julia --project=/home/sliang/JuliaCode/mycMPO /home/sliang/JuliaCode/mycMPO/Imagtime_TFIsing.jl --g $(g) --beta $(beta)")
        close(io)
        println("Run: tmp$(R).sh")
        run(```sbatch tmp$(R).sh```)
        sleep(0.1)
        rm("tmp$(R).sh")
    end
end

    
