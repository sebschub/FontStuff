#!/bin/bash

FONT=MinionPro

# temporary directory
TEMPF=~/temp/
V1=$TEMPF/$FONT"V1"
V2=$TEMPF/$FONT"V2"
SCRIPTS=~/FontPro		# generating scripts
OTF=~/otf/${FONT}		# font files

# version 1 fonts
V1F="${FONT}-BoldCapt.otf    ${FONT}-ItSubh.otf \
${FONT}-BoldDisp.otf \
${FONT}-BoldItCapt.otf \
${FONT}-BoldItDisp.otf  ${FONT}-Regular.otf \
${FONT}-BoldIt.otf      ${FONT}-SemiboldCapt.otf \
${FONT}-BoldItSubh.otf  ${FONT}-SemiboldDisp.otf \
${FONT}-Bold.otf        ${FONT}-SemiboldItCapt.otf \
${FONT}-BoldSubh.otf    ${FONT}-SemiboldItDisp.otf \
${FONT}-Capt.otf        ${FONT}-SemiboldIt.otf \
${FONT}-Disp.otf        ${FONT}-SemiboldItSubh.otf \
${FONT}-ItCapt.otf      ${FONT}-Semibold.otf \
${FONT}-ItDisp.otf      ${FONT}-SemiboldSubh.otf \
${FONT}-It.otf          ${FONT}-Subh.otf"

# version 2 fonts
V2F="${FONT}-MediumCapt.otf ${FONT}-MediumItCapt.otf"

# prepare temporary folders
rm -rf $V1 $V2
cp -r ${SCRIPTS} $V1
cp -r ${SCRIPTS} $V2
mkdir $V1/otf $V2/otf
for i in $V1F; do
    cp ${OTF}/$i $V1/otf
done
for i in $V2F; do
    cp ${OTF}/$i $V2/otf
done

# patch version 2 to remove some checking and generating
# patch only fit to my very needs
patch -d $V2/ -p1 < ${FONT}v2.patch

# generate tex files
cd $V1
./scripts/makeall ${FONT} --pack=scripts/${FONT}-glyph-list-1.000

cd $V2
./scripts/makeall ${FONT} --pack=scripts/${FONT}-glyph-list-2.000


# rename and modify encoding files
cd $V1
for i in dvips/base*.enc
do
    let=${i##*-}
    let=${let%.enc}
    sed s/Encoding-${let}/Encoding-${let}v1000/1 < $i > ${i%.enc}v1000.enc
    rm $i
done
cd $V2
for i in dvips/base*.enc
do
    let=${i##*-}
    let=${let%.enc}
    sed s/Encoding-${let}/Encoding-${let}v2000/1 < $i > ${i%.enc}v2000.enc
    rm $i
done

# copy everything from version 2 to 1
cp $V2/dvips/base*.enc $V1/dvips/
cp $V2/dvips/$FONT.map $V1/dvips/tempv2.map

cp $V2/pfb/* $V1/pfb
cp $V2/tfm/* $V1/tfm
cp $V2/vf/* $V1/vf

# modify map files to reflect changes of enc files
cd $V1/dvips/
sed 's/Encoding-\(..\)/Encoding-\1v1000/g;s/${FONT}-\(a.\)/${FONT}-\1v1000/g;s/Medium\(.\{0,6\}\) "${FONT}-Base-Encoding-\(..\)v1000 ReEncodeFont" <\[base-${FONT}-..v1000.enc/Medium\1 "${FONT}-Base-Encoding-\2v2000 ReEncodeFont" <\[base-${FONT}-\2v2000.enc/g' <${FONT}.map > v1.map
sed 's/Encoding-\(..\)/Encoding-\1v1000/g;s/${FONT}-\(a.\)/${FONT}-\1v1000/g;s/Medium\(.\{0,6\}\) "${FONT}-Base-Encoding-\(..\)v1000 ReEncodeFont" <\[base-${FONT}-..v1000.enc/Medium\1 "${FONT}-Base-Encoding-\2v2000 ReEncodeFont" <\[base-${FONT}-\2v2000.enc/g' <tempv2.map > v2.map

# join map files
cat v1.map v2.map > $FONT.map
