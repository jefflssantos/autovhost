#!/bin/bash

function createVHost() {
    D_ROOT="/var/www/html"
    D_PUBLIC="$SITE_NAME/public"

    if [ "$ROOT" ]; then
        D_ROOT=$ROOT
    fi

    if [ "$PUBLIC" ]; then
        D_PUBLIC=$SITE_NAME$PUBLIC
    fi

    if [ "$FORCE" == 1 ]; then
        sudo rm -r /etc/nginx/sites-available/$SITE_NAME
        sudo rm -r /etc/nginx/sites-enabled/$SITE_NAME
    fi

     TEMPLATE="server {
                    listen  80;
                    server_name $SITE_NAME;

                    sendfile off;

                    root $D_ROOT/$D_PUBLIC;
                    index index.php index.html;

                    location / {
                        try_files \$uri \$uri/ /index.php?\$query_string;
                    }

                    error_page 404 /404.html;

                    error_page 500 502 503 504 /50x.html;
                    location = /50x.html {
                        root $D_ROOT/$D_PUBLIC;
                    }

                    location ~ \.php$ {
                        fastcgi_split_path_info ^(.+\.php)(/.+)$;
                        fastcgi_pass unix:/var/run/php5-fpm.sock;
                        fastcgi_index index.php;
                        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
                        include fastcgi_params;
                    }
                }";

    echo "$TEMPLATE" >> /etc/nginx/sites-available/$SITE_NAME;

    printf "\e[30;42m
    \n VIRTUAL HOST CREATED | >> $SITE_NAME <<
    \e[0m\n\n"

}

function deleteVHost() {
    sudo rm -r /etc/nginx/sites-available/$SITE_NAME
    sudo rm -r /etc/nginx/sites-enabled/$SITE_NAME

    printf "\e[39;41m
    \n VIRTUAL HOST DELETED | >> $SITE_NAME <<
    \e[0m\n\n"
}

function enableVHost() {
    sudo ln -s /etc/nginx/sites-available/$SITE_NAME /etc/nginx/sites-enabled/$SITE_NAME

    printf "\e[30;42m
    \n VIRTUAL HOST ENABLED | >> $SITE_NAME <<
    \e[0m\n\n"
}

function disableVHost() {
    sudo rm -r /etc/nginx/sites-enabled/$SITE_NAME

    printf "\e[30;42m
    \n VIRTUAL HOST DISABLED | >> $SITE_NAME <<
    \e[0m\n\n"
}

function installPackages() {

    sudo apt-get update
    sudo apt-get -y install python-software-properties

    sudo apt-get install -y language-pack-en-base
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8

    sudo add-apt-repository -y ppa:nginx/stable
    sudo add-apt-repository -y ppa:ondrej/php5-5.6
    sudo add-apt-repository -y ppa:ondrej/mysql-5.7
    sudo add-apt-repository -y ppa:chris-lea/redis-server
    sudo apt-get update

    sudo apt-get install -y nginx php5 php5-fpm php5-mysql php5-curl php5-mcrypt  redis-server

    echo -en "\a"
    echo -en "\a"
    echo -en "\a"

    sudo apt-get install -y mysql-server

    echo -en "\a"
    echo -en "\a"
    echo -en "\a"

    sudo mysql_secure_installation

    sudo apt-get autoremove
    sudo apt-get autoclean

    sudo service php5-fpm restart
    sudo service nginx restart

    printf '\e[30;42m
    \n ALL PACKAGES INSTALLED
    \e[0m\n\n'
}

function helper() {
    echo ""
    echo "Options:"
    echo "      -o [ install (no required -n)| create | delete | enable | disable ]"
    echo "      -n virtual host name"
    echo ""
    echo "Create options:"
    echo "      -f force"
    echo "      -r root path    : default /var/www/html"
    echo "      -p public path  : default /public"

    exit 1

}

if [ "$(whoami)" != 'root' ]; then
    printf "\e[39;41m
   \n You have no permission to run $0 as non-root user. Use sudo
   \e[0m\n\n"
    exit 1;
fi

while getopts "fvho:n:p:r:" G_OPTION
do
    case $G_OPTION in
        h|help) helper
            ;;
        f) FORCE=1
            ;;
        o) OPTION=$OPTARG
            ;;
        n) SITE_NAME=$OPTARG
            ;;
        p) PUBLIC=$OPTARG
            ;;
        r) ROOT=$OPTARG
            ;;
        *)
            helper
            ;;
    esac
done
shift $((OPTIND-1))

if [ "$OPTION" != "install" ] && [ "$SITE_NAME" ]; then
    case $OPTION in
        create)
            createVHost

            printf '\e[39;41m ENABLE VIRTUAL HOST? [Y/n]:\e[0m '
            read
            case $REPLY in
                n|N)
                    printf '\e[30;46m
                    \n -o enable -n <NAME> TO ENABLE
                    \e[0m\n\n'
                    ;;
                y|Y|*) enableVHost
                    ;;
            esac
            ;;
        delete)
            deleteVHost
            ;;
        enable)
            enableVHost
            ;;
        disable)
            disableVHost
            ;;
        *)
            helper
            ;;
    esac
elif [ "$OPTION" == "install" ]; then
    installPackages
    exit 1
else
   printf '\e[39;41m
   \n -o [ create | delete | enable | disable ] -n <NAME> THIS CAMPUS ARE REQUIRED
   \e[0m\n\n'
fi

printf "\e[30;42m
\n Complete! You now have a new Virtual Host
\e[0m\n\n"

sudo service php5-fpm restart
sudo service nginx restart

exit 1
