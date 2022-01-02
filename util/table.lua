
function TableLength(T)
    if T == nil then
        return 0
    end
    
    local count = 0
    for _ in pairs(T) do 
        count = count + 1
    end
    
    return count
end  

function TableMean(T)
    local sum = 0
    local count = 0
    if T == nil then return 0 end
    for k, v in pairs(T) do
        if type(v) == 'number' then
            sum = sum + v
            count = count + 1
        end
    end
    return (sum / count)
end

function TableMinKey(T)
    local min = nil

    for k, v in pairs(T) do
        if min == nil then min = k end
        if type(k) == "number" and k < min then
        min = k
        end
    end

    return min
end