export @MixedBag, eltypes, AbstractMixedBag

abstract AbstractMixedBag


Base.eachindex(iter::SimpleVector) = 1:length(iter)
function firstindex(condition, iter)
    for i in eachindex(iter)
        condition(iter[i]) && return i
    end
    throw(error("No index satisfying condition=$condition in iter=$iter"))
end

function fieldname(T, types)
    for i in eachindex(types)
        (types[i] == T) && return Symbol("_$i")
    end
    throw(error("No field T=$T in types=$types"))
end

function mixedbag_fields(types)
    fields = []
    for T in types
        fname = fieldname(T, types)
        field = :($(fname) :: Vector{$T})
        push!(fields, field)
    end
    fields
end

function typedef_mixedbag(name::Symbol, types)
    mutablility = false
    fields = mixedbag_fields(types)
    fieldblock = Expr(:block,fields...)
    Expr(:type, mutablility, :($name <: MixedBags.AbstractMixedBag), fieldblock)
end

eltypes{Bag <: AbstractMixedBag}(::Type{Bag}) = map(eltype, Bag.types)
eltypes(b::AbstractMixedBag) = eltypes(typeof(b))


# constructors
function empty_constructor_impl(name, types)
    args = [:($T[]) for T in types]
    rhs = Expr(:call, name, args...)
    lhs = Expr(:call, name, )
    Expr(Symbol("="), lhs, rhs)
end

# copy constructor
(::Type{Bag}){Bag <: AbstractMixedBag}(b::Bag) = b

function (::Type{Bag}){Bag <: AbstractMixedBag}(args...)
    b = Bag()
    for arg in args
        push!(b, arg)
    end
    b
end


macro MixedBag(name, types...)
    Expr(:block,
        typedef_mixedbag(name, types),
        empty_constructor_impl(name, types)
    ) |> esc
end
