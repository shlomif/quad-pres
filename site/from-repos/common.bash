root="http://localhost:8080/svn/repos/progs/quad-pres/"
devel_dir="devel"
prog_name="quad-pres"

mkdir_if_not_exists()
{
    dir="$1";
    if [ ! -e "$dir" ] ; then
        mkdir "$dir"
    fi
}

