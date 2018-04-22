#!/bin/bash
#
# 登録画面から送られてきた登録データの検査を行い予実マスタへ登録する。
# last modify : 2017/12/26 kehukef(kehukef@gmail.com)
############################################################################

export LANG=ja_JP.UTF-8

apld=/var/www/webkids
tmpd=$apld/tmp
datad=$apld/data
indata=$datad/input
msdata=$datad/master
scriptd=$apld/scripts/bin
msgcat=$msdata/msgcat.lst

rtext=0

function ERROR_CHECK(){
  rc=$( expr $(echo ${PIPESTATUS[@]} | sed 's/ / + /g') )
  [[ $rc -ne 0 ]] && ON_ERROR $1
}

function ON_ERROR(){
  # エラーコードからメッセージ引っ張ってエラーログへ出力
  echo "errmsg----" >> $logf
  errmsg=$( grep "^$1" $msgcat )
  echo "$errmsg" >> $logf
  echo "----errmsg" >> $logf

  errpage=$(mktemp $tmpd/regist_er_XXXXXXXXXXXXXXXXXXXX.html)
  sed "s/%%TEXT%%/$errmsg/" $apld/html/error.html > $errpage
  errpage=${errpage##*/}

  echo "Content-type:text/plain"
  echo ""
  echo "$errpage"

  exit 1
}

#-- エラーログ出力開始
logf=$tmpd/$(basename $0).$$.log
exec 2> $logf

#-- 共通関数読み込み
if [[ -r $scriptd/common.fnc ]]; then
  . $scriptd/common.fnc
else
  ON_ERROR 00001
  exit 1
fi

#-- input data format --
#-------------------------------------
# date  YYYY/MM/DD
# t_text hoge
# c_text fuga
# mem_code(1) sch_mor_s (<- "sch_mor_s" is "HH:MM", if "--:--" then no data)
# mem_code(1) sch_mor_e
# mem_code(1) sch_eve_s
# mem_code(1) sch_eve_e
# mem_code(1) act_mor_s
# ...
#-------------------------------------
inputf=$tmpd/in_data.regist.$$    # 登録画面から受け取った入力データ
h_tmpf=$tmpd/h_tmp.$$             # 入力データのヘッダ部分(登録対象日付・担当・備考）
b_tmp1=$tmpd/b1_tmp.$$            # 入力データの各メンバコードを抜き出してソート/ユニークしたもの
b_tmp2=$tmpd/b2_tmp.$$            # 入力データの時刻を抜き出して, 空行を--:--に変換後、1人分ずつ(8行ごと)横並びにしたもの
b_tmp3=$tmpd/b3_tmp.$$            # b1_tmpの行数分の登録日付
b_tmp4=$tmpd/b4_tmp.$$            # b1_tmpを元に名簿マスタから抽出したデータ（実質名簿マスタそのものになるはず）
reg_tmp=$tmpd/reg_tmp.$$          # 作り出した登録データ（1日分)
yj_tmp=$tmpd/yj_tmp.$$            # 作り出した新予実マスタ
tt_tmp=$tmpd/tt_tmp.$$            # 作り出した新担当マスタ

inputs=""
target_date=""
sdate=$(date +%Y%m%d.%H%M%S)

#-- 登録するデータを取得
#-------------------------------------------------------------------------------------------------------
cat - | cgi-name > $inputf
# -- debug --
# cat - > $inputf
# -- debug --

# ヘッダと明細に分けて、横並びにする(100)
#-------------------------------------------------------------------------------------------------------
head -n 3 $inputf | self 2 > $h_tmpf;                                     ERROR_CHECK 01101
tail -n +4 $inputf | self 1 | uniq > $b_tmp1;                             ERROR_CHECK 01102
tail -n +4 $inputf | self 2 | sed "s/^$/--:--/" | xargs -n 8 > $b_tmp2;   ERROR_CHECK 01103
target_date=$(head -n 1 $h_tmpf) #登録する日付

#担当マスタの作成処理(200)
#-------------------------------------------------------------------------------------------------------
#空のデータはNO_DATAとして横並びにしていったんtmpファイルに保存
tmpstr=$(head -n 1 $h_tmpf)
[[ $(sed -n 2p $h_tmpf) == "" ]] && tmpstr=$tmpstr"" || tmpstr=$tmpstr" $(sed -n 2p $h_tmpf)"
[[ $(sed -n 3p $h_tmpf) == "" ]] && tmpstr=$tmpstr"" || tmpstr=$tmpstr" $(sed -n 3p $h_tmpf)"

# 最新の担当マスタのファイル名を取得
tanto_master=$(ls -1 $msdata/tanto.* | LANG=C sort | tail -n 1); ERROR_CHECK 01201

# 対象日だけのぞいたマスタの後ろに合体したデータをくっつけてsortしたらいったんtmpファイルとして保存
cat <(grep -v "^$target_date" $tanto_master) <(echo $tmpstr) | LANG=C sort -k1,1 > $tt_tmp; ERROR_CHECK 01202

#予実マスタの作成処理(300)
#-------------------------------------------------------------------------------------------------------
# 行数があっているかチェック
[[ $(cat $b_tmp1 | wc -l) != $(cat $b_tmp2 | wc -l) ]] && ON_ERROR 01301

# 登録データの左端につける日付を作成
awk '1 {print "'$target_date'"}' $b_tmp1 > $b_tmp3

# 登録日の属する年度のmeiboマスタを特定する
nendo=$( echo $target_date | cut -c1-4 )
[[ "0" == $( echo $target_date | cut -c5 ) ]] && nendo=$( expr $nendo - 1 )
meibo_master=$( ls -1 $msdata/meibo.* | LANG=C sort | tail -n 1); ERROR_CHECK 01302

# コードを元にメンバ情報を取得
grep -f $b_tmp1 $meibo_master > $b_tmp4

# 日付・氏名コード・予実データを合体
paste -d' ' $b_tmp3 $b_tmp4 $b_tmp2 > $reg_tmp

# reg_tmpの時刻正当性確認
# -- reg_tmp format --
# date code class name sch_mor_s sch_mor_e sch_eve_s sch_eve_e act_mor_s act_mor_e act_eve_s act_eve_e
# -- reg_tmp format --
ng_list=$( cat $reg_tmp | awk '{if($5 > $6 || $7 > $8 || $9 > $10 || $11 > $12) print $4}' )

if [[ -z $ng_list ]];then
  # 最新の予実マスタのファイル名を取得
  yojitu_master=$(ls -1 $msdata/yojitu.*  | LANG=C sort | tail -n 1); ERROR_CHECK 01303

  # 対象日だけのぞいたマスタの後ろに合体したデータをくっつけてsortしたらいったんtmpファイルとして保存
  cat <(grep -v "^$target_date" $yojitu_master) $reg_tmp | LANG=C sort -k1,1 -k2,2 > $yj_tmp; ERROR_CHECK 01304

  #担当・予実それぞれマスタとして登録
  cp -p $yj_tmp $msdata/yojitu.$sdate
  cp -p $tt_tmp $msdata/tanto.$sdate
else
  rtextf=$(mktemp $tmpd/regist_ng_XXXXXXXXXXXXXXXXXXXX.html)
  echo "以下の園児の時刻に不整合があります。" > $rtextf
  echo "" >> $rtextf
  for ngmember in $ng_list; do
    echo $ngmember | sed 's/_/ /g' >> $rtextf
  done
  rtext=$(cat $rtextf)
fi

#tmpを後片付け
#-------------------------------------------------------------------------------------------------------
rm -f $tmpd/*_tmp.$$
[[ $(cat $logf) == "" ]] && rm -f $logf

#ブラウザへ返す（OKなら0, NGならNGページ)
#-------------------------------------------------------------------------------------------------------
echo "Content-type:text/plain"
echo ""
echo "$rtext"

exit 0
