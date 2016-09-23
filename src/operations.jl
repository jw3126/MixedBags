
@generated function Base.getindex{T}(bag::AbstractMixedBag, ::Type{T})
    :(bag.$(fieldname(T, eltypes(bag))))
end

function Base.push!(bag::AbstractMixedBag, item)
    T = typeof(item)
    push!(bag[T], item)
    bag
end

function Base.append!(bag::AbstractMixedBag, iter)
    T = eltype(iter)
    append!(bag[T], iter)
    bag
end

# comparison
@generated function fieldwise_equality(x, y)
    @assert fieldnames(x) == fieldnames(y)  # better look at typeof(x).types ?
    args = [:(x.$f == y.$f || return false) for f in fieldnames(x)]
    Expr(:block, args..., :(return true))
end

import Base.==
(==)(x::AbstractMixedBag, y::AbstractMixedBag) = fieldwise_equality(x, y)

# collect
function collect_impl(Bag)
    args = map(fname -> :(bag.$(fname)) ,fieldnames(Bag))
    Expr(:call, :vcat, args...)
end
@generated Base.collect(bag::AbstractMixedBag) = collect_impl(bag)

# mapreduce

import Base.mapreduce
@generated mapreduce(f, op, v0, bag::AbstractMixedBag) = mapreduce_impl(f, op, v0, bag)
@generated mapreduce(f, op, bag::AbstractMixedBag) = mapreduce_impl(f, op, bag)

function mapreduce_impl(f, op, v0, Bag)
    fnames = fieldnames(Bag)
    N = length(fnames)
    v(i) = Symbol("v$i")
    args = map((i,fname) -> :($(v(i+1)) = mapreduce(f, op, $(v(i)), bag.$fname) ), 0:(N-1), fnames)
    retarg = :(return $(v(N)))
    Expr(:block, args..., retarg)
end

function mapreduce_impl(f, op, Bag)
    fnames = fieldnames(Bag)
    N = length(fnames)
    v(i) = Symbol("v$i")
    fname1 = fnames[1]
    arg1 = :( $(v(1)) = mapreduce(f, op, bag.$fname1) )
    args = map((i,fname) -> :( $(v(i+1)) = mapreduce(f, op, $(v(i)), bag.$fname) ), 1:(N-1), fnames[2:N])
    retarg = :(return $(v(N)))
    Expr(:block, arg1, args..., retarg)
end

# foreach
Base.foreach{T}(f, bag::AbstractMixedBag, ::Type{T}) = foreach(f, bag[T])
@generated Base.foreach(f, bag::AbstractMixedBag) = foreach_impl(f, bag)
function foreach_impl(f, bag)
    typs = map(eltype, bag.types)
    args = map(T -> :(foreach(f, bag, $T)), typs)
    Expr(:block, args...)
end
