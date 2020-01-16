#!/bin/sh

#  Resign.sh
#  WeChat
#
#  Created by Ericydong on 2020/1/7.
#  Copyright © 2020 EricyDong. All rights reserved.

#临时存放解压后文件的目录
TEMP_PATH=${SRCROOT}/Temp
#存放原始ipa文件的目录
ASSETS_PATH=${SRCROOT}/APP
#原始ipa文件的路径
TARGET_IPA_PATH=${ASSETS_PATH}/*.ipa
if [ -d $TEMP_PATH ];then
rm -rf $TEMP_PATH
else
mkdir -p $TEMP_PATH
fi

#解压ipa到Temp文件夹
unzip -oqq $TARGET_IPA_PATH -d $TEMP_PATH
#获取解压之后的app文件
TEMP_APP_PATH=`find ./Temp -maxdepth 2 -iname *.app`
echo "HERE $TEMP_APP_PATH"
if [ -d $TEMP_APP_PATH ];then
echo ".app文件存在:$TEMP_APP_PATH"
else
echo ".app不存在,请检查原始ipa文件是否存在"
exit 0;
fi



#将.app移动到BUILT_PRODUCTS_DIR

TARGET_APP_PATH=$BUILT_PRODUCTS_DIR/${TARGET_NAME}.app
#获取签名证书
if [ -z $EXPANDED_CODE_SIGN_IDENTITY ]; then
    echo "$EXPANDED_CODE_SIGN_IDENTITY 变量为空"
    EXPANDED_CODE_SIGN_IDENTITY=`codesign -d -vv $TARGET_APP_PATH 2>&1 | grep --after-context=1 "Signature size="`
    EXPANDED_CODE_SIGN_IDENTITY=${EXPANDED_CODE_SIGN_IDENTITY##*=}
fi



#拷贝文件中的描述文件进行保存
cp "$TARGET_APP_PATH/embedded.mobileprovision"  "$TARGET_APP_PATH/../embedded.mobileprovision"




rm -rf $TARGET_APP_PATH
cp -rf $TEMP_APP_PATH $TARGET_APP_PATH

#拷贝之前保存的描述文件到文件夹中
cp "$TARGET_APP_PATH/../embedded.mobileprovision" "$TARGET_APP_PATH/embedded.mobileprovision"
##删除Plugin和Watch中的插件
rm -rf $TARGET_APP_PATH/Watch
rm -rf $TARGET_APP_PATH/PlugIns

#修改bundleidentifier
PlistBuddy -c "Set :CFBundleIdentifier $PRODUCT_BUNDLE_IDENTIFIER" "$TARGET_APP_PATH/Info.plist"

EXECUTABLE_NAME_REAL=`PlistBuddy -c "Print :CFBundleExecutable" "$TARGET_APP_PATH/Info.plist"`

#echo "EXECUTABLE_NAME == $EXECUTABLE_NAME"
#二进制文件添加可执行权限
chmod u+x $TARGET_APP_PATH/$EXECUTABLE_NAME_REAL

#签名frameworks
TARGET_APP_FRAMEWORKS_PATH=$TARGET_APP_PATH/Frameworks
echo "TARGET_APP_FRAMEWORKS_PATH == $TARGET_APP_FRAMEWORKS_PATH"
if [ -d $TARGET_APP_FRAMEWORKS_PATH ];then
    cd $TARGET_APP_FRAMEWORKS_PATH
    allFrameworks=`ls $TARGET_APP_FRAMEWORKS_PATH`
    for framework in ${allFrameworks[@]}
    do
        codesign -fs "$EXPANDED_CODE_SIGN_IDENTITY" "$framework"
    done
fi

# 5. 添加自定义framework加载
    #获取可执行文件的名称
    EXECUTABLEFILE=`PlistBuddy -c "Print :CFBundleExecutable" "$TARGET_APP_PATH/Info.plist"`
#    echo "EXECUTABLEFILE == $EXECUTABLEFILE"
    
yololib  $TARGET_APP_PATH/$EXECUTABLEFILE Frameworks/EWInject.framework/EWInject


