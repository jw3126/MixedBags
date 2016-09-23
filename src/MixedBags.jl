module MixedBags

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
    i = firstindex(S -> S==T,types)
    Symbol("_$i")
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

function (::Type{Bag}){Bag <: AbstractMixedBag}(args...)
    b = Bag()
    for arg in args
        push!(b, arg)
    end
    b
end

@generated function Base.getindex{T}(bag::AbstractMixedBag, ::Type{T})
    :(bag.$(fieldname(T, eltypes(bag))))
end



function Base.push!(bag::AbstractMixedBag, item)
    T = typeof(item)
    push!(bag[T], item)
    bag
end

Base.foreach{T}(f, bag::AbstractMixedBag, ::Type{T}) = foreach(f, bag[T])
@generated Base.foreach(f, bag::AbstractMixedBag) = foreach_impl(f, bag)
function foreach_impl(f, bag)
    typs = map(eltype, bag.types)
    args = map(T -> :(foreach(f, bag, $T)), typs)
    Expr(:block, args...)
end

@generated function fieldwise_equality(x, y)
    @assert fieldnames(x) == fieldnames(y)
    args = [:(x.$f == y.$f || return false) for f in fieldnames(x)]
    Expr(:block, args..., :(return true))
end

# comparison
import Base.==
(==)(x::AbstractMixedBag, y::AbstractMixedBag) = fieldwise_equality(x, y)


import Base.mapreduce
@generated function mapreduce(f, op, v0, bag::AbstractMixedBag)
    mapreduce_impl(f, op, v0, bag)
end

function mapreduce_impl(f, op, v0, T)
    fnames = fieldnames(T)
    N = length(fnames)
    v(i) = Symbol("v$i")
    args = map((i,fname) -> :($(v(i+1)) = mapreduce(f, op, $(v(i)), bag.$fname) ), 0:(N-1), fnames)
    retarg = :(return $(v(N)))
    Expr(:block, args..., retarg)
end

macro MixedBag(name, types...)
    Expr(:block,
        typedef_mixedbag(name, types),
        empty_constructor_impl(name, types)

    ) |> esc
end

end # module
