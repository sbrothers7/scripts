#!/usr/bin/env zsh

ok()    { print -P "%B%F{green}✔ $*%f%b"; }
warn()  { print -P "%F{yellow}$*%f"; }
err()   { print -P "%B%F{red}✖ $*%f%b"; }
info()  { print -P "%B%F{blue}$*%f%b"; }
dim()   { print -P "%F{black}$*%f"; }

typeset choice subchoice
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

loadtest() {
    displaysubmenu 1
    
    case $subchoice in;
        1)
            clear
            local threads connections duration target
            print -n -- "Enter number of threads to use: "
            read -k1 threads
            print -n -- "\nEnter number of connections to use: "
            read connections
            print -n -- "Enter duration: "
            read duration
            print -n -- "Enter target: https://"
            read target
            print
            
            wrk -t"${threads}" -c"${connections}" -d"${duration}" "https://${target}"
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

            slowloris -s $sockets -ua --sleeptime $sleep "https://${target}"
            ;;
        q)
            info "Exiting..."
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
        print -n -- "Use git instead? (y/N)"
        read option

        if $option -eq [Yy]; then
            print "Currently in development"
            exit 1
        fi

        info "Attempting to install slowloris..."
        pip3 install slowloris
    fi
}

compat
displaymenu
while true; do
    case $choice in;
        1) loadtest;;
        q) 
            info "Exiting..."
            exit 1
            ;;
    esac
done

# wrk -t8 -c200 -d120s http://211.119.252.77/
