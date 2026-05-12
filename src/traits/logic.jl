########################################################
# LOGIC
########################################################

export PropositionalLogic, PredicateLogic

struct PropositionalLogic <: Trait
    Prop::Space
    conjunction::Object
    disjunction::Object
    implication::Object
    biconditional::Object
    negation::Object

    function PropositionalLogic(Prop::Space, conjunction::Symbol = :∧, disjunction::Symbol = :∨, implication::Symbol = :⟹, biconditional::Symbol = :⟺, negation::Symbol = :¬)
        register!(new(Prop,
            Object(Prop × Prop → Prop, label = conjunction),
            Object(Prop × Prop → Prop, label = disjunction),
            Object(Prop × Prop → Prop, label = implication),
            Object(Prop × Prop → Prop, label = biconditional),
            Object(Prop → Prop, label = negation),
        ))
    end
end

space(t::PropositionalLogic) = t.Prop

show(io::IO, t::PropositionalLogic) = print(io, "PropositionalLogic($(t.Prop), $(t.conjunction), $(t.disjunction), $(t.implication), $(t.biconditional), $(t.negation))")

trait_objects(t::PropositionalLogic) = Objects([t.conjunction, t.disjunction, t.implication, t.biconditional, t.negation])

struct PredicateLogic <: Trait
    space::Space
    Prop::Space
    forall::Object
    exists::Object

    function PredicateLogic(S::Space, Prop::Space, forall::Symbol = :∀, exists::Symbol = :∃)
        register!(new(S, Prop,
            Object(Bind(S × Prop → Prop), label = forall),
            Object(Bind(S × Prop → Prop), label = exists)
        ))
    end
end

space(t::PredicateLogic) = t.space

show(io::IO, t::PredicateLogic) = print(io, "PredicateLogic($(space(t)))")

trait_objects(t::PredicateLogic) = Objects([t.forall, t.exists])
