using AlgorithmAnalysis

foobar_handle = @generate_test_handle function foobar()
    1 == 1
end

baz_bar_handle = @generate_test_handle function bazbar()
    3 == 3
end

TestFileDescriptor(
    file_contents=raw"""# Demo Test file
some normal text asdasjndasjdasdjasdj
latex:     
```math
    \rho = 1-2\alpha mL/(L+m) \quad \text{if} \quad 0 < \alpha \leq \frac{2}{L+m}.
```

julia code block
```julia
print("foobar");
```
    
\n\n this is a sample body of the file
""",
    named_tests=["foobarnamed" => foobar_handle, "barbaz!" => baz_bar_handle],
    references=[]
)