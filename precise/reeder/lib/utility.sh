#!/bin/bash

service_name=`config-get service_name`
export_root=`config-get storage_root`
export_owner=`config-get export_owner`
webroot=`config-get webroot`
project_name=`config-get project_name`
export_path="$export_root/$service_name"
django_webroot="$export_path/$webroot"
project_path="$export_path/$project_name"

configure_site() {
    local virtualenv=`config-get virtualenv_path`
    local virtualenv_path="$export_path/$virtualenv"
	local admin_user=`config-get admin_user`
	local admin_email=`config-get admin_email`
    local site_name=`config-get env_sitename`

	su -l $export_owner -c "(cd $project_path/$project_name; \
        $virtualenv_path/bin/python manage.py syncdb --noinput --migrate; \
        $virtualenv_path/bin/python manage.py createsuperuser --noinput --username=$admin_user --email=$admin_email; \
        $virtualenv_path/bin/python manage.py collectstatic --noinput; \
        )"
	
}

# install virtualenv based on a pip-requirements file
install_virtualenv(){
    local virtualenv=`config-get virtualenv_path`
    local virtualenv_path="$export_path/$virtualenv"
    
    juju-log "Install virtualenv"
    [ -d "$virtualenv_path" ] || mkdir -p $virtualenv_path
    
    # run the commands in a subshell, since virtualenv is going to mess with our environment
    (   virtualenv $virtualenv_path; \
        source $virtualenv_path/bin/activate; \
        easy_install -U distribute; \
        pip install -r config/pip-requirements.txt \
    )
}

# grab the website code
install_source(){
    local source_url=`config-get source_url`
	local sourcefile="/tmp/source.tgz"
	
    [ -d $export_path ] || mkdir -p $export_path
    chown -R $export_owner.$export_owner $export_path
    juju-log "Get website source"
    wget -O $sourcefile "$source_url"
    su -l $export_owner -c "tar xzvf $sourcefile --directory $export_path"
}
