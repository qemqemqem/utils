# Use "type my_alias" to see what an alias refers to

alias bashupdate='source ~/.bashrc'
alias bashedit='ne ~/.bash_aliases && bashupdate'

alias bazel="/home/keenan/Downloads/bazelisk-linux-amd64"

alias runegansimple="while true; do bazel build src:egan || break; ./bazel-bin/src/egan ; sleep 0; done"
# alias runegan="while true; do kill $(lsof -t -i:5000); bazel build src:egan || break; sleep 0.1; ./bazel-bin/src/egan ; sleep 0.1; done"
alias runegan="while true; do kill $(lsof -t -i:5000); bazel build //worlds/egan || break; sleep 0.1; ./bazel-bin/worlds/egan/egan ; sleep 0.1; done"

alias debugegan="bazel build //worlds/egan; gdb ./bazel-bin/worlds/egan"
alias compegan="bazel build //worlds/egan"

# sshtunnel astera
alias astera-sshuttle='sshuttle --method nft --dns -r astera 192.168.1.0/24'

alias gs="git status"
alias gc="git commit -am"
