-- Auto-execute SQL on resource start using oxmysql
AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local sqlFile = 'sql/install.sql'
    local file = LoadResourceFile(GetCurrentResourceName(), sqlFile)
    if file then
        local queries = {}
        for query in string.gmatch(file, '([^;]+);') do
            if query:find('%S') then -- skip empty queries
                table.insert(queries, query)
            end
        end
        for _, query in ipairs(queries) do
            exports.oxmysql:execute(query, {}, function() end)
        end
        print('[Z-MDT] SQL install.sql executed via oxmysql.')
    else
        print('[Z-MDT] sql/install.sql not found!')
    end
end)
