#! /bin/bash

# Will move to Genshi templates in future

# Defaults
SITE=site
PORT=90
CREATE_DIR=/tmp

# Prompt for params
echo -n "Egg name, eg. jmbo-myapp. It MUST have this form. [enter]: "
read EGG
#echo -n "Django app name, eg. myapp. [enter]: "
#read APP
echo -n "Site name, eg. ghana. This is useful if you have different sites forming a logical whole, eg. a site per country. (default=site) [enter]: "
read asite
if [ -n "$asite" ];
then
    SITE=$asite
fi    
echo -n "Port base. Service ports are offset from this port. (default=90) [enter]: "
read aport
if [ -n "$aport" ];
then
    PORT=$aport
fi    
echo -n "Source code directory. (default=/tmp) [enter]: "
read adir
if [ -n "$adir" ];
then
    CREATE_DIR=$adir
fi    

# Extract app name. Convention is repo has form jmbo-foo or jmbo.foo.
INDEX=`expr index "$EGG" [-.]`
APP=${EGG:${INDEX}}

# Create the project
PROJECT_DIR=${CREATE_DIR}/${APP}
APP_DIR=${PROJECT_DIR}/${APP}
mkdir $PROJECT_DIR

# Copy requisite bits
cp bootstrap.py ${PROJECT_DIR}/
cp .gitignore ${PROJECT_DIR}/
cp setup.py ${PROJECT_DIR}/
cp versions.cfg ${PROJECT_DIR}/
cp setup-development.sh ${PROJECT_DIR}/
cp handler.py ${PROJECT_DIR}/
cp deviceproxy.yaml.in ${PROJECT_DIR}/deviceproxy_${SITE}.yaml
cp test_settings.py ${PROJECT_DIR}/
touch ${PROJECT_DIR}/AUTHORS.rst
touch ${PROJECT_DIR}/CHANGELOG.rst
touch ${PROJECT_DIR}/README.rst
cp *.cfg ${PROJECT_DIR}/
cp -r buildout_templates ${PROJECT_DIR}/
cp -r scripts ${PROJECT_DIR}/
cp -r skeleton ${PROJECT_DIR}/${APP}

# Rename buildout config files
if [ $SITE != "site" ];
then
    for f in ${PROJECT_DIR}/*_site.cfg; do mv $f ${f/site/${SITE}}; done
fi

# Copy and rename buildout config files for qa and live
for f in base_*.cfg.in; do cp $f ${PROJECT_DIR}/qa_${f/\.cfg\.in/\.cfg}; done
for f in *_site.cfg.in; do cp $f ${PROJECT_DIR}/qa_${f/\_site.cfg\.in/_${SITE}\.cfg}; done
for f in base_*.cfg.in; do cp $f ${PROJECT_DIR}/live_${f/\.cfg\.in/\.cfg}; done
for f in *_site.cfg.in; do cp $f ${PROJECT_DIR}/live_${f/\_site.cfg\.in/_${SITE}\.cfg}; done

# Create the settings files. First delete the existing ones, then copy and rename.
rm ${PROJECT_DIR}/${APP}/settings_*_site.*
for f in skeleton/settings_*.py; do 
    F=$(basename $f)
    cp $f ${PROJECT_DIR}/${APP}/${F/site/${SITE}}; 
done

# Change strings in the newly copied source
sed -i s/name=\'jmbo-skeleton\'/name=\'${EGG}\'/ ${PROJECT_DIR}/setup.py
sed -i "s/PORT_PREFIX_PLACEHOLDER/${PORT}/g" ${PROJECT_DIR}/*.cfg
sed -i "s/SITE_NAME_PLACEHOLDER/${SITE}/g" ${PROJECT_DIR}/*.cfg
sed -i "s/PORT_PREFIX_PLACEHOLDER/${PORT}/g" ${PROJECT_DIR}/deviceproxy_*.yaml
sed -i "s/DEPLOY_TYPE_PLACEHOLDER/qa/g" ${PROJECT_DIR}/qa_*.cfg
sed -i "s/DEPLOY_TYPE_PLACEHOLDER/live/g" ${PROJECT_DIR}/live_*.cfg

sed -i "14s/.*/    ${EGG}/" ${PROJECT_DIR}/dev_base.cfg

sed -i "16s/.*/    ${EGG}/" ${PROJECT_DIR}/qa_base_mobi.cfg
sed -i "17s/.*/    ${EGG}/" ${PROJECT_DIR}/qa_base_conventional.cfg

sed -i "16s/.*/    ${EGG}/" ${PROJECT_DIR}/live_base_mobi.cfg
sed -i "17s/.*/    ${EGG}/" ${PROJECT_DIR}/live_base_conventional.cfg

# Replace the word skeleton with the app name
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/*.cfg
sed -i s/skeleton/${APP}/g ${PROJECT_DIR}/*.py
sed -i s/skeleton/${APP}/g ${APP_DIR}/*.py
sed -i s/skeleton/${APP}/g ${APP_DIR}/migrations/*.py

# Set the secret key
SECRET_KEY=`date +%s | sha256sum | head -c 56`
sed -i "s/SECRET_KEY_PLACEHOLDER/${SECRET_KEY}/" ${APP_DIR}/settings.py

# Replace site name in site specific buildout config files
if [ "$SITE" != "site" ];
then
    sed -i s/_site/_${SITE}/g ${PROJECT_DIR}/*_${SITE}.cfg
    sed -i s/-site/-${SITE}/g ${PROJECT_DIR}/*_${SITE}.cfg
fi

# Indicate version of jmbo-skeleton used to create project
VERSION=`sed "5q;d" setup.py | awk -F= '{print $2}'`
echo "Changelog" > ${PROJECT_DIR}/CHANGELOG.rst
echo "=========" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "0.1" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "---" >> ${PROJECT_DIR}/CHANGELOG.rst
echo "Project generated by jmbo-skeleton $VERSION" >> ${PROJECT_DIR}/CHANGELOG.rst 
echo "" >> ${PROJECT_DIR}/CHANGELOG.rst

