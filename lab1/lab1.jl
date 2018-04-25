function qsort(n, from, to)
    if from >= to
        return
    end
    
    pivot = n[from]
    
    j = from
    for i = (from + 1):to
        if n[i] < pivot
            t = n[j]
            n[j] = n[i]
            n[i] = t
            
            j += 1
        end
        
        i += 1
    end
    
    n[j] = pivot
    
    qsort(n, from, j-1)
    qsort(n, j+1, to)
    
    return n
end

function quicksort(n)
    return qsort(n, 1, length(n))
end

println(quicksort([5, 6, 3, 2, 8]))

