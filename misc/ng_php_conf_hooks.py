import os, re, shutil
# #
internalIp = os.environ['OPENSHIFT_DIY_IP']
internalPort = os.environ['OPENSHIFT_DIY_PORT']
OPENSHIFT_HOMEDIR=os.environ['OPENSHIFT_HOMEDIR'] 
runtimeDir = os.environ['OPENSHIFT_HOMEDIR'] + "/app-root/runtime"
Destination = os.environ['OPENSHIFT_HOMEDIR'] + "/app-root/runtime/repo"
Bash_File=os.environ['OPENSHIFT_HOMEDIR']
repoDir=Destination+'/www'
nginx_dir=os.environ['OPENSHIFT_HOMEDIR']+"/app-root/runtime/srv/nginx"

CurrentDir=os.path.dirname(os.path.realpath(__file__))
Parent_Dir=os.path.abspath(os.path.join(CurrentDir, '..'))

print Parent_Dir

Parent_Dir=Parent_Dir.replace('\\','/')
Destination=Destination.replace('\\','/')

## copy file_source Contains to File_Target if is not similar and make it if
# there is no target file

def replace(file_pattern,file_target):
    # Read contents from file_target as a single string
    if os.path.isfile(file_target):
        pass
    else:
        file_pattern2 = open(file_pattern, 'r')
        pattern = file_pattern2.readlines()
        file_pattern2.close()

        file_handle2= open(file_target, 'wb')
        file_handle2.writelines(pattern)
        file_handle2.close()

    file_handle = open(file_target, 'r')
    # file_string1 = file_handle.read()
    file_string = file_handle.readlines()
    file_handle.close()
    file_pattern2 = open(file_pattern, 'r')
    pattern = file_pattern2.readlines()
    file_pattern2.close()
    file_handle2= open(file_target, 'a+b')
    i=-1
    t=-1
    for line in range(i+1, len(pattern)):
        I_S=0
        for j in range(t+1, len(file_string)):
            if pattern[line] in file_string[j] :
                I_S=1
                break
            else:
                pass
        if I_S==0 :
            file_handle2.writelines(pattern[line])
    file_handle2.close()

## copy new files and strings to destination
for root, dirs, files in os.walk(Parent_Dir):
    curent_path0=root.split(Parent_Dir)[1]+'/'
    curent_path=curent_path0.replace('\\','/')
    root=root.replace('\\','/')
    for dir2 in dirs:
        if os.path.isdir(Destination+ curent_path+dir2):
            pass
        else:
            if not os.path.isdir(Destination):os.mkdir(Destination)
            os.mkdir(Destination+ curent_path+dir2)
    for file2 in files:
        if os.path.isfile(Destination+ curent_path+file2):
            path = os.path.join(root, file2)
            size_source = os.stat(path.replace('\\','/')).st_size # in bytes
            size_target=os.stat(Destination+ curent_path+file2).st_size
            if size_source != size_target:
                replace(Parent_Dir+curent_path+file2,Destination+ curent_path+file2)
        else:
            replace(Parent_Dir+curent_path+file2,Destination+ curent_path+file2)

#replace(Parent_Dir+"/misc/templates/bash_profile.tpl",Bash_File+'/app-root/data/.bash_profile')

f = open(repoDir + '/misc/templates/httpd.conf.tpl', 'r')
conf = f.read().replace('{{OPENSHIFT_INTERNAL_IP}}', internalIp).replace('9000','25641').replace('{{OPENSHIFT_REPO_DIR}}', repoDir).replace('{{OPENSHIFT_RUNTIME_DIR}}', runtimeDir)
f.close()

f = open(runtimeDir + '/srv/php/etc/php-fpm.conf', 'w')
f.write(conf)
f.close()

f = open(repoDir + '/misc/templates/php.ini.tpl', 'r')
conf = f.read().replace('{{OPENSHIFT_INTERNAL_IP}}', internalIp).replace('8081',internalPort).replace('{{OPENSHIFT_REPO_DIR}}', repoDir).replace('{{OPENSHIFT_RUNTIME_DIR}}', runtimeDir)
f.close()

f = open(runtimeDir + '/srv/php/etc/apache2/php.ini', 'w')
f.write(conf)
f.close()

f = open(repoDir + '/misc/templates/nginx.conf.tpl', 'r')
conf = f.read().replace('{{OPENSHIFT_INTERNAL_IP}}', internalIp).replace('{{OPENSHIFT_INTERNAL_PORT}}',internalPort)
conf=conf.replace('{{OPENSHIFT_HOMEDIR}}',OPENSHIFT_HOMEDIR).replace('{{OPENSHIFT_REPO_DIR}}', repoDir)
conf=conf.replace('{{OPENSHIFT_RUNTIME_DIR}}', runtimeDir)
f.close()

f = open(runtimeDir + '/srv/nginx/conf/nginx.conf', 'w')
f.write(conf)
f.close()
