#!/bin/bash

#The stage1 will create a base.io, which include all the components we modified for sslgw except the sslgw rpms.

#parameter
VERSION=
USER=
PASSWD=

if [ $# -lt 3 ]
then
    echo "Usage : $0 SSLGW_VERSION,username,password)"
    echo "    Eg: $0 3.1.1.1,bob,bobpwd"
    exit 1
else
    VERSION=$1
    USER=$2
    PASSWD=$3
fi

TMP=$PWD/tmp
BASE=$TMP/base
BUILD=$TMP/build
REMOTE=$TMP/remote
RPMBUILD=$TMP/rpmbuild
RELEASE=$TMP/release

LDAP=$RPMBUILD/ldap/
LB=$RPMBUILD/loadbalance/
GW=$RPMBUILD/sslgw/
GWWEB=$RPMBUILD/sslgw_web/

SSLGW=$RELEASE/SSLGateway/$VERSION


prepare()
{
    mkdir -p {$BASE,$BUILD,$REMOTE}
    mount -t cifs -o username=$USER,password=$PASSWD //192.168.117.3/CentOS65forSSLGateway $REMOTE
    cp $REMOTE/CentOS-6.5-x86_64-minimal.iso .
    mount -o loop,ro CentOS-6.5-x86_64-minimal.iso $BASE
    rsync -av $BASE/ $BUILD/
    umount -df $BASE && rmdir $BASE
    find $BUILD -name TRANS.TBL -exec rm -f {} \;
    rm -rf $BUILD/Packages/{audit-*,kernel-2.6*}
    cp -rf $REMOTE/RPMS/*.rpm $BUILD/Packages/
    cp -rf $REMOTE/CFIST/ $BUILD/
    umount $REMOTE && rmdir $REMOTE
    rm -rf $BUILD/repodata/{*.{bz2,gz},*.xml} 
   rm CentOS-6.5-x86_64-minimal.iso
}

modify()
{
    #Modify repository data file
    cp -f $BUILD/CFIST/comps.xml $BUILD/repodata/
    #Modify the image and create kickstart file
    cp -f $BUILD/CFIST/{ks.cfg,isolinux.cfg,splash.jpg} $BUILD/isolinux/

    #Modify the installation display
    cd $BUILD/isolinux/ && mv initrd.img initrd.img.lzma
    unlzma initrd.img.lzma && mkdir initrd/
    mv initrd.img initrd/ && cd initrd/
    cpio -div < initrd.img && rm initrd.img
    sed -i 's/CentOS/CFIST SSL Gateway/g' .buildstamp
    find .|cpio -c -o >../initrd.img && cd ..
    rm initrd -rf&&lzma -z initrd.img
    mv initrd.img.lzma initrd.img

    #Modify the installation image
    cd $BUILD/images/ && unsquashfs install.img
    chmod 755 squashfs-root/usr/share/anaconda/pixmaps/*.png
    cp $BUILD/CFIST/*.png squashfs-root/usr/share/anaconda/pixmaps/
    sed -i '/quiet/d' squashfs-root/usr/lib/anaconda/packages.py
    sed -i 's/anaconda.*append("rhgb")/pass/' squashfs-root/usr/lib/anaconda/packages.py
    sed -i "/splash.xpm.gz.*:/a \                f.write('password --md5 \$1\$3XKWm1\$E5UYb6OtA4tVfdkMjzovA1\\\n')" squashfs-root/usr/lib/anaconda/booty/x86.py
    rm -rf install.img &&mksquashfs squashfs-root/ install.img
    rm -rf squashfs-root/
}

release()
{
    cd $TMP
    #prepare rpmbuild environment
    mkdir -p {$LDAP,$LB,$GW,$GWWEB}/usr/local/
    mkdir -p $RELEASE
    mount -t cifs -o username=$USER,password=$PASSWD //192.168.117.2/Build $RELEASE

    #SSLGWWEB
    cp -rf $SSLGW/SSLGW_WEB $GWWEB/usr/local/

    cp -rf $SSLGW/sslgw/openssl $GWWEB/usr/local/SSLGW_WEB/web/script/certificate/openssl
    mkdir -p $GWWEB/etc/init.d/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/sslgwWeb $GWWEB/etc/init.d/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/autorun $GWWEB/etc/init.d/
    mkdir -p $GWWEB/root/
    cp -rf $BUILD/CFIST/setup.sh $GWWEB/root/
    cp -rf $BUILD/CFIST/blacklist.conf $GWWEB/root/
    mkdir -p $GWWEB/usr/bin
    cp -rf $BUILD/CFIST/lsb_release $GWWEB/usr/bin/
    find $SSLGW/ -name "*.pdf" |xargs -i cp {} $GWWEB/usr/local/SSLGW_WEB/web/docs/

    #LDAP
    cp -rf $SSLGW/LDAP/ $LDAP/usr/local/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/LDAP_startup.sh $LDAP/usr/local/LDAP/startup.sh
    mkdir -p $LDAP/etc/init.d/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/socketLdap $LDAP/etc/init.d/

    #LOADBALANCE
    cp -rf $SSLGW/LoadBalance $LB/usr/local/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/LB_startup.sh $LB/usr/local/LoadBalance/startup.sh
    mkdir -p $LB/etc/init.d/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/socketLoadBalance $LB/etc/init.d/

    #SSLGW
    cp -rf $SSLGW/sslgw $GW/usr/local/
    mkdir -p $GW/etc/init.d/
    cp -rf $GWWEB/usr/local/SSLGW_WEB/web/script/init.d/sslgw $GW/etc/init.d/

    #SPEC
    cp -rf $BUILD/CFIST/*.spec $RPMBUILD
    v=`echo $VERSION|echo $VERSION|cut -d . -f1`
    r=`echo $VERSION|echo $VERSION|cut -d . -f2-`
    sed -i "s:vvv:$v:g;s:rrr:$r:g" $RPMBUILD/*.spec

    #rpmbuild
    [ -e ~/.rpmmacros ] && mv ~/.rpmmacros ~/.rpmmacros.bak
    echo "%_topdir $RPMBUILD/" >& ~/.rpmmacros
    rpmbuild -bb --buildroot=$LDAP $RPMBUILD/ldap.spec
    rpmbuild -bb --buildroot=$LB $RPMBUILD/loadbalance.spec
    rpmbuild -bb --buildroot=$GW $RPMBUILD/sslgw.spec
    rpmbuild -bb --buildroot=$GWWEB $RPMBUILD/sslgw_web.spec
    rm ~/.rpmmacros
    [ -e ~/.rpmmacros.bak ] && mv ~/.rpmmacros.bak ~/.rpmmacros
    umount $RELEASE
}

package()
{
    cp -rf $RPMBUILD/RPMS/x86_64/* $BUILD/Packages/
    discinfo=$(head -1 $BUILD/.discinfo)
    createrepo -u "media://$discinfo" -g $BUILD/repodata/comps.xml $BUILD
    mkisofs -R -J -T -r -l -d -joliet-long -allow-multidot -allow-leading-dots -no-bak -o $PWD/CFIST.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table $BUILD
    implantisomd5 $PWD/CFIST.iso
}

clean()
{
    mv $TMP/CFIST.iso ..
    rm -rf $TMP
}

prepare
modify
release
package
clean
