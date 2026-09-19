network --bootproto=dhcp --device=link --activate

clearpart --all --initlabel
autopart

rootpw --lock

bootc \
    --source-imgref=registry:dhcr.io/burmistery/fedorium:latest \
    --target-imgref=dhcr.io/burmistery/fedorium:latest
