---------------
--  Options  --
---------------

options.timeout = 120
options.subscribe = true


----------------
--  Accounts  --
----------------

server = IMAP {
    server = 'imap.gmail.com',
    username = 'mail@example.com',
    password = 'p4ssw0rd',
    ssl = 'ssl3',
}

mailboxes, folders = server:list_all()

for i,m in pairs (mailboxes) do
    --messages = server[m]:is_unseen() -- + server[m]:is_new ()
    filter = server[m]:is_unseen() *
                server[m]:contain_body("https:gist.github.com")
    --subjects = server[m]:fetch_fields({ 'subject' }, filter)
    result = server[m]:fetch_message(filter)
    if result ~= nil then
        --print (m)
        for j, s in pairs (result) do
            -- okundu olarak isaretle kismi eklenecek !
            --print (string.format("\t%s", s))
            -- dosyaya yazdirmak mantikli degil ama baska yontemi bulmak
            -- hizimi kesecek. TODO
            local file = io.open("content.txt", "w")
            file:write(s)
            file:close()
            -- alt kisim generic olacak sekilde duzenlenecek.
            os.execute("ruby ~/github/ben/bitbot/bitbot.rb")
        end
    end
end

-- http://blogs.igalia.com/vjaquez/2009/08/09/the-true-imap-usage-imapfilter/
-- https://github.com/lefcha/imapfilter/blob/master/samples/config.lua
