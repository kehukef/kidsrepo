#-----------------------------------------------------------------
# HH:MM形式で文字列を受け、00:00 - 23:59以内であるか検査する
#-----------------------------------------------------------------
function tfcheck(){
  is=$( echo $1 | grep '[0-9][0-9]:[0-9][0-9]' )
  [[ -z $is ]] && return 1
  
  hh=$( echo $is | awk -F':' '{print $1}' ); hh=$( echo "$hh * 1" | bc );
  mm=$( echo $is | awk -F':' '{print $2}' ); mm=$( echo "$mm * 1" | bc );
 
  if [[ $hh -lt 0 ]] || [[ $hh -gt 24 ]]; then
    return 1
  fi

  if [[ $mm -lt 0 ]] || [[ $mm -gt 59 ]]; then
    return 1
  fi

  return 0
}

#-----------------------------------------------------------------
# HH:MM形式の文字列を受け、それを分(MM)にして標準出力に返す。
#-----------------------------------------------------------------
function mch(){
  is=$1
  tfcheck $is; [[ $? -ne 0 ]] && return 1;
  
  hh=$( echo $is | awk -F':' '{print $1}' ); hh=$( echo "$hh * 1" | bc );
  mm=$( echo $is | awk -F':' '{print $2}' ); mm=$( echo "$mm * 1" | bc );
  echo "$hh * 60 + $mm" | bc
  
  return 0
}

#-----------------------------------------------------------------
# mchの逆(少なくとも数値が渡ってくる前提)
#-----------------------------------------------------------------
function mrv(){

  [[ -z $1 ]] && return 1
  is=$1

  if [[ $is -lt 0 ]] || [[ $is -gt 1439 ]]; then
    return 1
  fi

  hh=$( echo "$is / 60" | bc )
  hh=$( printf '%02d\n' $hh )
  mm=$( echo "$is % 60" | bc )
  mm=$( printf '%02d\n' $mm )

  echo $hh:$mm
}

#-----------------------------------------------------------------
# from - to の日付を受けて日付リストをスペース区切りで返す
# ex) 2001/01/01 2001/01/04
#  -> 2001/01/01 2001/01/02 2001/01/03 2001/01/04
# ただし無限ループ防止のため2999/12/31までとする
#-----------------------------------------------------------------
function durdate(){
  fd=$1; td=$2; nd=$fd;
  
  rd=$nd

  while [[ $nd != $td ]];do
    nd=$(date --date "$nd 1 days" +%Y/%m/%d)
    rd=$rd" "$nd
    [[ $nd == "2999/12/31" ]] && break
  done

  echo $rd
}

#-----------------------------------------------------------------
# YYYY/MM/DD から前0を取り除く
#-----------------------------------------------------------------
function chgDate(){
  yy=$(echo $1 | awk -F'/' '{print $1}')
  mm=$(echo $1 | awk -F'/' '{print $2}')
  dd=$(echo $1 | awk -F'/' '{print $3}')

  # 普通にやると前0の2桁は八進数と思われちゃう
  mm=$(expr $mm \* 1)
  dd=$(expr $dd \* 1)

  echo "$yy/$mm/$dd"

  return 0
}