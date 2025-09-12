#!/usr/bin/env zsh

ok()    { print -P "%B%F{green}✔ $*%f%b"; }
warn()  { print -P "%F{yellow}$*%f"; }
err()   { print -P "%B%F{red}✖ $*%f%b"; }
info()  { print -P "%F{blue}$*%f"; }
infobold() { print -P "%B%F{blue}$*%f%b"; }
inputprompt() { print -Pn "%B$*%b"; }
dim()   { print -P "%F{black}$*%f"; }

typeset choice subchoice
gitslowloris=false
menus=("Server Load Test")
submenus=("wrk slowloris")
titles=("Server Load Test")


displaymenu() {
    clear
    infobold "============ sbro7 Network Tools ============"
    local i
    for i in {1..${#menus[@]}}; do
        print "    ${i}. ${menus[i]}"
    done 
    infobold "============================================="
    
    inputprompt "Enter selection ([q]uit [h]elp): "
    read -k1 choice
}

displaysubmenu() {
    clear
    local i
    inner=(${=submenus[$1]})
    # print -l $inner

    infobold "============ ${titles[$1]} ============"
    for i in {1..${#inner[@]}}; do
        print "    ${i}. ${inner[$i]}"
    done 
    infobold "============================================="
    
    inputprompt "Enter selection ([b]ack [h]elp): "
    read -k1 subchoice
    
    case $subchoice in;
        b) displaymenu;;
        h) subhelp
    esac

}

is_digit() { [[ "$1" == <-> ]]; } 


typeset submenuinputret
submenuinput() { # (default, submenu#)
    local input
    read input
    case $input in;
        '')
            if $newedit; then
                err "Please enter a value to edit"
                inputprompt $3
                submenuinput $1 $2 $3
            else
                info "Defaulting value to ${1}"
                submenuinputret=$1
            fi
            ;;
        "b") 
            if $newedit; then
                err "Use the e key instead to edit values at specific indexes"
                inputprompt $3
                submenuinput $1 $2 $3
            else
                editval $1 $2 $3
            fi
            ;;
        "q")
            loadtest;;
        *)
            submenuinputret=$input
    esac
}

newedit=false
editval() {
    local editi=$3

    if ((i == 1)); then 
        err "No previous value"
        inputprompt ${defaulttxt[1]}
        submenuinput $1 $2
        newedit=false
        return
    fi

    local prevval=${param[editi]}
    infobold "======================================"
    info "Editing value..."
    newedit=true
    inputprompt ${defaulttxt[editi - 1]}
    submenuinput $1 $2 ${defaulttxt[editi - 1]}

    warn "Overrid value of ${param[editi - 1]} to ${submenuinputret}"
    infobold "======================================"
}

loadtest() {
    displaysubmenu 1
    param=()
    
    case $subchoice in;
        1)
            local logicalcpus=$(sysctl -n hw.logicalcpu)
            local maxfiles=$(sysctl -n kern.maxfilesperproc)
            local defcpus=$((logicalcpus / 2))

            local default=($defcpus $((defcpus * 1000)) "5m")
            local defaulttxt=(
                "Enter number of threads to use: " 
                "Enter number of connections to use: " 
                "Enter duration: " 
            )
            local target
            local i=1
            
            clear
            cmdhelp

            while ((i < 4)); do
                inputprompt "${defaulttxt[$i]}"
                submenuinput "$default[$i]" 1 i

                if $newedit; then
                    ((i--))
                fi
                
                case $i in;
                    1)
                        if ((submenuinputret > logicalcpus)); then
                            err "Exceeded maximum number of threads present on device"
                            info "Setting number of threads to number of cores..."
                            param[1]=$logicalcpus
                            ok "Set thread count to $param[1]"
                        fi
                        param+=("$submenuinputret")
                        ;;
                    2) 
                        ulimval=$(ulimit -n)
                        if ((ulimval < maxfiles)); then
                            ulimit -n $maxfiles
                        fi

                        if ((submenuinputret > maxfiles)); then
                            err "Exceeded maximum files per process"
                            info "Setting number of connections to 90%% of maximum value..."
                            if $newedit; then
                                param[2]=$((maxfiles * 90 / 100))
                            else
                                param+=$((maxfiles * 90 / 100))
                            fi
                            ok "Set \"connections\" value to $param[2]"
                        fi

                        if ((param[1] != default[1] && submenuinputret == default[2])); then
                            # clear
                            # cmdhelp
                            warn "Custom thread count detected"
                            info "Resetting value to optimized number given thread count..."
                            param+=$((param[1]*1000))
                            ok "Set \"connections\" value to ${param[2]}"
                            if $newedit; then
                                infobold "======================================"
                            fi
                        else
                            param+=("$submenuinputret")
                        fi
                        ;;
                    *) param+=("$submenuinputret");;
                esac

                ((i++))
                newedit=false
            done

            print -nP -- "%BEnter target: %bhttps://"
            read target
            if [[ $target == 'b' ]]; then 
                displaysubmenu 1
            fi
            print
            
            wrk -t"${param[1]}" -c"${param[2]}" -d"${param[3]}" "https://${target}"
            ;;
        2)
            clear
            local default=(10000 5)
            local defaulttxt=(
                "Enter number of sockets: " 
                "Enter interval: "
            )
            local i=1

            while ((i <= ${#default[@]})); do
                inputprompt "$defaulttxt[i]"
                submenuinput "$default[i]" 2 i
                param+=("$submenuinputret")
                ((i++))
            done

            print -nP -- "%BEnter target: %bhttps://"
            read target
            if [[ $target == 'b' ]]; then 
                displaysubmenu 1
            fi
            print
            
            if $gitslowloris; then
                cd $HOME/scripts/slowloris
                python3 slowloris.py -s $param[1] -ua --sleeptime $param[2] "https://${target}"
            else
                slowloris -s $param[1] -ua --sleeptime $param[2] "https://${target}"
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

mainhelp() {
    clear
    cat << 'HLP'

    MAIN MENU:
    
    Number keys             Open category

    q                       Quit

    h                       Open this menu
HLP
    inputprompt "\n\nPress any key: "
    read -k1
    displaymenu
}

subhelp() {
    clear
    cat << 'HLP'

    SUB MENU:

    Number keys             Open category

    b                       Return to main menu

    h                       Open this menu
HLP
    inputprompt "\n\nPress any key: "
    read -k1
    displaymenu
}

cmdhelp() {
    info "For every input field, you may press [q] then [enter] to return to the submenu"
    info "Pressing [b] then [enter] will allow you to change the previous field's value\n"
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
        h)
            mainhelp;;
        *)
            displaymenu
    esac
done

# wrk -t8 -c200 -d120s http://211.119.252.77/
