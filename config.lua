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
    filter = server[m]:is_unseen() *
                server[m]:contain_body("https:gist.github.com") *
                server[m]:contain_to("bitbot@bil.omu.edu.tr")
    result = server[m]:fetch_message(filter)
    if result ~= nil then
        for j, s in pairs (result) do
            local file = io.open("content.txt", "w")
            file:write(s)
            file:close()
            os.execute("ruby ~/github/ben/bitbot/bitbot.rb")
        end
    filter:mark_seen()
    end
end

-- http://blogs.igalia.com/vjaquez/2009/08/09/the-true-imap-usage-imapfilter/
-- https://github.com/lefcha/imapfilter/blob/master/samples/config.lua
