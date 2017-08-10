--登录处理

net.s_login_version = function (vfd, ptoSum, urs, password, phoneInfo, sdkInfo, langType)
    print("s_login_version:", vfd, ptoSum, urs, password, phoneInfo, sdkInfo, langType)

    net.c_login_error(vfd, 12, {})
end