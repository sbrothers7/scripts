#!/usr/bin/env zsh

ok()    { print -P "%B%F{green}✔ $*%f%b"; }
warn()  { print -P "%F{yellow}$*%f"; }
err()   { print -P "%B%F{red}✖ $*%f%b"; }
info()  { print -P "%B%F{blue}$*%f%b"; }
dim()   { print -P "%F{black}$*%f"; }

typeset choice subchoice
gitslowloris=false
menus=("Server Load Test")
submenus=("wrk slowloris")
titles=("Server Load Test")


displaymenu() {
    clear
    info "============ sbro7 Network Tools ============"
    local i
    for i in {1..${#menus[@]}}; do
        print "    ${i}. ${menus[i]}"
    done 
    info "============================================="
    
    print -n -- "Enter selection: "
    read -k1 choice
}

displaysubmenu() {
    clear
    local i
    inner=(${=submenus[$1]})
    # print -l $inner

    info "============ ${titles[$1]} ============"
    for i in {1..${#inner[@]}}; do
        print "    ${i}. ${inner[$i]}"
    done 
    info "============================================="
    
    print -n -- "Enter selection: "
    read -k1 subchoice
    
    case $subchoice in;
        b) displaymenu
    esac

}

is_digit() { [[ "$1" == <-> ]]; } 


typeset submenuinputret
submenuinput() { # (default, submenu#)
    local input
    read input
    case $input in;
        '')
            info "Defaulting value to ${1}"
            submenuinputret=$1
            ;;
        "b") displaysubmenu $2;;
        *)
            submenuinputret=$input
    esac
}

loadtest() {
    displaysubmenu 1
    
    case $subchoice in;
        1)
            local default=(4 10000 "1m")
            local defaulttxt=(
                "Enter number of threads to use: " 
                "Enter number of connections to use: " 
                "Enter duration: " 
            )
            local target i
            local param=()

            clear
            for ((i=1; i<4; i++)); do
                print -n -- "${defaulttxt[$i]}"
                submenuinput $default[$i] 1

                if ((i == 2)); then
                    maxfiles=$(sysctl -n kern.maxfilesperproc)
                    if ((submenuinputret > maxfiles)); then
                        err "Exceeded maximum files per process"
                        info "Setting number of connections to 90%% of maximum value..."
                        param+=$((maxfiles * 90 / 100))
                    else
                        param+="$submenuinputret"
                    fi
                else
                    param+="$submenuinputret"
                fi
            done

            print -n -- "Enter target: https://"
            read target
            if [[ $target == 'b' ]]; then 
                displaysubmenu 1
            fi
            print
            
            wrk -t"${param[1]}" -c"${param[2]}" -d"${param[3]}" "https://${target}"
            ;;
        2)
            clear
            local sockets target
            print -n -- "Enter number of sockets: "
            read sockets
            print -n -- "Enter interval: "
            read sleep
            print -n -- "Enter target: https://"
            read target
            print

            if $gitslowloris; then
                cd $HOME/scripts/slowloris
                python3 slowloris.py -s $sockets -ua --sleeptime $sleep "https://${target}"
            else
                slowloris -s $sockets -ua --sleeptime $sleep "https://${target}"
            fi
            ;;
        q)
            info "\nExiting..."
            exit 1
    esac
}

clear
info "Checking compatibility..."

compat() {
    info "Checking homebrew installation..."
    if ! command -v brew >/dev/null 2>&1; then
        err "Homebrew is not installed."
        info "Attempting to install homebrew..."
       
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh -o /tmp/install_homebrew.sh
        chmod +x /tmp/install_homebrew.sh
        /bin/bash /tmp/install_homebrew.sh

        info "Setting PATH for homebrew..."
        print >> $HOME/.zprofile
        print 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"

        ok "Successfully installed homebrew. Continuing installation..."
    else
        ok "Found homebrew installation. Continuing..."
    fi

    if command -v python3 >/dev/null 2>&1; then
        ok "Python is installed"
    else
        err "Python is NOT installed"
        exit 1
    fi

    if command -v pip3 >/dev/null 2>&1; then
        ok "pip is installed"
    else
        err "pip is NOT installed"
        info "Make sure to initialize a python virtual environment in the directory if you have installed python with homebrew."

        exit 1
    fi

    if python3 -m pip show slowloris >/dev/null 2>&1; then
        ok "slowloris is installed"
    else
        err "slowloris is NOT installed"
        local option

        if [ -d $HOME/scripts/slowloris ]; then
            ok "Detected slowloris files. Continuing..."
            gitslowloris=true
        else
            print -n -- "Use git instead? (y/N): "
            read -k1 option
            print

            if [[ "$option" == [Yy] ]]; then
                git clone https://github.com/gkbrk/slowloris.git $HOME/scripts/slowloris
                gitslowloris=true
            else 
                info "Attempting to install slowloris..."
                pip3 install slowloris
            fi
        fi
    fi
}

compat
displaymenu
while true; do
    case $choice in;
        1) loadtest;;
        q) 
            info "\nExiting..."
            exit 1
            ;;
        *)
            displaymenu
    esac
done

# wrk -t8 -c200 -d120s http://211.119.252.77/
