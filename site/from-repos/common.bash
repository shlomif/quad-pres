root="http://stalker.iguide.co.il:8080/svn/lm-solve/quad-pres/"
devel_dir="devel"
prog_name="quad-pres"
stable_dir="stable"

mkdir_if_not_exists()
{
    dir="$1";
    if [ ! -e "$dir" ] ; then
        mkdir "$dir"
    fi
}

