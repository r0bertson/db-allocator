using JuMP, GLPK

#=
Problem short definition:
    Allocate a set of N databases on a set of M cloud virtual machines minimizing the cost paid.
    The VMs are already allocated, so it is a matter of reallocating the databases and shutting down the idle ones to save money.

Problem model:
    B = BINS (VM)
    I = ITEMS (Database)

    MIN 
        SUM(W_j * B_j)			                                  (Minimize VM utilization times cost)
    ST
        SUM[i = 1 to len(I)](X_i_j * W_i) <= C_j * B_j ∀ j ∈ B    (VM capacity is respected)
        SUM[i = 1 to len(I)](X_i_j) = 1 ∀ j ∈ B	                  (Every database is in one VM)
        X_i_j, B_j ∈ {0,1} ∀ i ∈ I, j ∈ B		                  (Binary)

=#


#= 
space_for_growth will increase each database size based on its value in percentage. 
This will keep "reserved" space for growth to each database entry allocated to a VM.
Although this is a workaround, it is useful to avoid the complexity of handling it inside the problem definition.
If only part of the set of databases need this reserved space, it can be precalculated and used as the original db_size.
=#

function db_allocation_problem(; verbose = true, space_for_growth = nothing)
    #TODO: A WAY TO IMPORT A FILE WITH INSTANCE SPECS OF A PROBLEM
    vm_names = ["SMALL", "MEDIUM", "LARGE"]
    vm_capacity = [1, 4, 10]
    vm_cost = [100, 300, 350]
    
    db_names = ["A", "B", "C", "D", "E", "F", "G"]
    db_sizes = [0.4, 0.7, 4.3, 4.6, 2.7, 0.1, 0.5]
    #batch_pr = [0 ,   1,   0,   1,   0,   0,   0]

    if space_for_growth != nothing
        db_sizes = db_sizes * (1 + space_for_growth / 100)
    end
    
    num_vm = length(vm_names)
    num_item = length(db_names)

    model = Model(with_optimizer(GLPK.Optimizer))

    @variable(model, vm_usage[1:num_vm], Bin)
    @variable(model, X[1:num_item, 1:num_vm], Bin)
    @variable(model, vm_load[1:num_vm] >= 0)

    # Constraint 1 - Every database must be in only one VM
    @constraint(model, [i in 1:num_item], sum(X[i,j] for j in 1:num_vm) == 1 )
    
    # Constraint 2 - The sum of the db sizes in one VM must be equal to the VM load
    @constraint(model, [j in 1:num_vm], sum(X[i,j] * db_sizes[i] for i in 1:num_item) == vm_load[j]) 

    # Constraint 3 - VM load must be less then or equal to its capacity, if the VM is used on the solution.
    @constraint(model, [j in 1:num_vm], vm_load[j] <= vm_usage[j] * vm_capacity[j])
    
    # Objective - Minimize cost of VM allocation
    @objective(model, Min, sum(vm_usage[j] * vm_cost[j] for j in 1:num_vm))

    JuMP.optimize!(model)

    println("Objective value is: ", JuMP.objective_value(model))
    println("Solution status: ",JuMP.termination_status(model))
    
    if verbose
        println("You can save ", sum(vm_cost[j] for j in 1:num_vm) - JuMP.objective_value(model), " if you use the following solution: ")
        println("VMs used: ")
        for j in 1:num_vm 
            if JuMP.value(vm_usage[j]) == 1
                print(string("VM[$j] ", vm_names[j] ," - LOAD = ", JuMP.value(vm_load[j]) / vm_capacity[j], "%\n"))
                #print("% \n")
            end
        end

        println("\nDatabases in each VM: ")

        for j in 1:num_vm
            if JuMP.value(vm_usage[j]) == 1
                print("VM[$j] = ")
                for i in 1:num_item
                    if JuMP.value(X[i,j]) == 1
                        print(db_names[i], " ")
                    end
                end
            end
            println()
        end
    end
end

db_allocation_problem(verbose = true)
#db_allocation_problem(verbose = true, space_for_growth = 20)