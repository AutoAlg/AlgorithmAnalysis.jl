#########################################################
# CONVEX
#########################################################
export Subdifferential

struct Subdifferential <: Trait
    subdifferential::Object
    
    function Subdifferential(F::Space, s::Space, subdifferential::Symbol = :adjoint)
        F ∈ SingleValued(domain(s), codomain(s))
        register!(new(Object(F → (domain(s) ⇒ domain(s)), label = subdifferential)))
    end
end

show(io::IO, ::Subdifferential) = print(io, "Subdifferential")

trait_objects(t::Subdifferential) = Objects([t.subdifferential])
