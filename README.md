#### db-allocator: a variable-sized bin packing implementation
This project consists of a JuMP implementation of the variable-sized bin packing problem. It is applied on database allocation on existing cloud virtual machines, minimizing the overall cost.

The entities on the source code are named after the context where it is applied, but the mathematical model is on its standard form.

To run it you must have Julia environment installed on your machine.
Additionally, you need to execute the following commands on Julia's REPL to add the required packages:

```
Pkg.add("JuMP");
Pkg.add("GLPK");
```
