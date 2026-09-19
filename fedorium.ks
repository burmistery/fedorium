network --bootproto=dhcp --device=link --activate

clearpart --all --initlabel
autopart

rootpw --lock

bootc --source-imgref=registry:ghcr.io/burmistery/fedorium:latest --target-imgref=ghcr.io/burmistery/fedorium:latest
