
--@section NewBuffer
function NewBuffer(maxlen)
    local buffer = {}
    buffer.maxlen = maxlen
    buffer.values = {}

    function buffer.Push(item)
        table.insert(buffer.values, 1, item)
        buffer.values[buffer.maxlen + 1] = nil
    end

    function buffer.PrintAll()
        data = ""
        for i, v in pairs(buffer.values) do
            data = data .. v
            if i < #buffer.values then data = data .. "," end
        end

        print(data)
    end
    return buffer
end
--@endsection