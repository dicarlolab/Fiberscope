classdef TestClass < handle
    properties
        A = [];
    end
    methods
        function updateA(obj, val)
            obj.A = val;
        end
    end
end