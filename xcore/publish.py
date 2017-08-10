#coding=utf-8
import os
import sys
import platform


#Win编译
def MSBuild(target, config):
    print "msbuild:",target,config
    #获取msbuild路径
    msbuild = "%s\\MSBuild\\12.0\\bin\\MSBuild.exe" % os.environ.get("ProgramFiles")
    if not os.path.isfile(msbuild):
        msbuild = "\"%s\"\\MSBuild\\12.0\\bin\\MSBuild.exe" % os.environ.get("ProgramFiles(x86)")
        if not os.path.isfile(msbuild):
            return MSDevenv(target, config)
    cmd = "\"%s\" build\\luv.sln /t:%s /p:Configuration=%s" % (msbuild, target, config)
    os.system(cmd)
    

def MSDevenv(target, config):
    print "msdevenv:", target, config
    execpath = "%s\..\IDE\devenv.exe" % os.environ.get("VS120COMNTOOLS")
    if target == "build":
        cmd = "\"%s\" win32\\xcore.sln /Build %s" (execpath, config)
    elif target == "rebuild":
        cmd = "\"%s\" win32\\xcore.sln /Rebuild %s" (execpath, config)
    else:
        return
    os.system(cmd)

def Build(target, config):
    if platform.system() == "Windows":
        print "build xcore in windows"
        MSBuild(target, config)
        os.system("copy bin\\xcore.exe ..\\publish\\xcore.exe")


def main():
    rootpath = os.curdir
    
    print "options:"
    print "1:build"
    print "2:rebuild"
    choice = int(raw_input("please choice:(1/2):"))
    if choice == 1:
        Build("build", "Release")
    elif choice == 2:
        Build("rebuild", "Release")
    else:
        return


if __name__ == "__main__":
    main()
    
