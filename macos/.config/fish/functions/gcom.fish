function gcom 
        set branch_name (git rev-parse --abbrev-ref HEAD | sed 's/.*\///')
        set split (string split '-' $branch_name)
        git commit -am "$split[1]-$split[2] | $argv[1]"
end
