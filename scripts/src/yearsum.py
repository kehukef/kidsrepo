#!/usr/bin/python3.6
# coding:utf-8

import sys
import re

def listFilter(lines, colmn, regkey):
  records = []
  for line in lines:
    if re.match( regkey, line.split()[colmn] ) != None :
      records.append(line)
  return records

def hm2m(hm):
  hh = int( hm.split(':')[0] ) * 60
  mm = int( hm.split(':')[1] )
  return hh + mm

def m2hm(ms):
  hh = str(int(ms / 60)).zfill(2)
  mm = str(int(ms % 60)).zfill(2)
  return hh + ':' + mm

def getDiff(ftime, ttime):
  if ftime == "--:--" and ttime == "--:--" :
    return 0
  else :
    if ftime != "--:--" and ttime != "--:--" :
      return hm2m(ttime) - hm2m(ftime)
    else :
      return -1

def main(yyyy):
  #-- 月単位、人単位の合計を保持するリスト
  #-- [ [id, month, time, day, extime], ... ] 
  totalPerMonth = []

  # ---------------------------------------------------------
  # まず月ごとに集計したリスト(totalPerMonth)を作ってしまう
  # 年度でIDを抽出して各IDに対して処理を行う
  # ---------------------------------------------------------
  meiboRecords = list( open(meibo, 'r') )
  yojituRecords = list( open(yojitu, 'r') )

  for idLine in listFilter(meiboRecords, 0, "^" + yyyy):
    ii = idLine.split()[0]
    cls = idLine.split()[1]
    name = idLine.split()[2]

    perTimeTotal = 0

    #-- 予実からIDで抜き出す
    #-------------------------
    idAllLines = listFilter(yojituRecords, 1, ii)

    # --------------------------------------------------------
    # IDをキーに抽出したレコードに対して各月ごとの処理を行う
    # --------------------------------------------------------
    for m in range(1, 12+1) :
      if m in [1, 2, 3]:
        ystr = str( int(yyyy) + 1 )
      else:
        ystr = yyyy

      #-- 日の合計、時間の合計、ex時間の合計
      monthDayTotal = 0
      monthTimeTotal = 0
      monthExTimeTotal = 0

      #-- 月でさらにレコードを絞る
      #-----------------------------
      records = listFilter( idAllLines, 0, '^' + ystr + '/' + str(m).zfill(2) + '...' )

      #-- 月で絞ったレコードをすべて使って該当月の時間（分）と日数を計算する
      #----------------------------------------------------------------------
      for record in records:
        dt = record.split()[0]  # 日付(エラー表示用)
        ms = record.split()[8]
        me = record.split()[9]
        es = record.split()[10]
        ee = record.split()[11]
        exms = "08:00"
        exme = "18:00"
        exes = "08:00"
        exee = "18:00"

        #-- 時間外の計算
        if ms != "--:--":
          if hm2m(ms) < hm2m("08:00"):
            exms = ms
            ms   = "08:00"
        if me != "--:--":
          if hm2m(me) > hm2m("18:00"):
            exme = me
            me   = "18:00"
        mtime = getDiff(ms, me)
        exmtime = getDiff(exms, "8:00") + getDiff("18:00", exme)

        if es != "--:--":
          if hm2m(es) < hm2m("08:00"):
            exes = es
            es   = "08:00"
        if ee != "--:--":
          if hm2m(ee) > hm2m("18:00"):
            exee = ee
            ee   = "18:00"
        etime = getDiff(es, ee)
        exetime = getDiff(exes, "8:00") + getDiff("18:00", exee)


        #-- 取得した時間(分)のいずれかが-1ならエラー
        #---------------------------------------------
        if mtime == -1 or etime == -1 or exmtime == -1 or exetime == -1 :
          return "Oops!! invalid data -> " + dt + name
          sys.exit()

        #-- 利用時間が0でないなら、日数を増やす
        #---------------------------------------
        if mtime + etime + exmtime + exetime != 0 :
          monthDayTotal += 1

        #-- 合計時間を足す
        #------------------
        monthTimeTotal = mtime + etime + monthTimeTotal
        monthExTimeTotal = exmtime + exetime + monthExTimeTotal

      #-- ひと月分が出たので、totalPerMonthへ追加
      totalPerMonth.append( (cls, name, m, monthTimeTotal, monthDayTotal, monthExTimeTotal) )

  #-- HTML出力開始
  #-- 出来上がったtotalPerMonthを元にテーブルを作っていく
  #-- yojituRecordsはもう使わないので解放しておく
  yojituRecords = None
  TBPRE = "  "
  THPRE = TBPRE + "  "
  TRPRE = THPRE + "  "
  TDPRE = TRPRE + "  "
  mttl  = [0,0,0, 0,0,0, 0,0,0, 0,0,0] #-- 月ごとの合計金額
  mday  = [0,0,0, 0,0,0, 0,0,0, 0,0,0] #-- 月ごとの合計日数
  marr  = [4,5,6,7,8,9,10,11,12,1,2,3]

  #-- まずテーブルのヘッダを出力する
  print("<!-- maintable start -->")
  print(TBPRE + '<table class="maintbl">')
  print(THPRE + '<thead class="maintbl">')
  print(TRPRE + '<tr>')
  print(TDPRE + '<th class="h_class">クラス</th>', end='')
  print('<th class="h_name">氏名</th>', end='')
  print('<th class="h_label">項目</th>', end='')
  for m in marr :
    print('<th class="h_month">' + str(m) + '月</th>', end='')
  print('<th class="h_total">年間</th>')
  print(TRPRE + '</tr>')
  print(THPRE + '</thead>')

  print(THPRE + '<tbody class="maintbl mdata">')
  #一人ずつ出力する
  for record in listFilter(meiboRecords, 0, "^" + yyyy):
    cls = record.split()[1]
    name = record.split()[2]
    #-- name = name.replace('_', ' ')

    #-- cls, nameを出力
    print(TRPRE + '<tr>')
    print(TDPRE + '<td class="d_class" rowspan="2">' + cls + '</td><td class="d_name" rowspan="2">' + name.replace('_', ' ') + '</td>' + '<td class="d_label d_cancel_foot">金額</td>', end='')
    pttl = 0 #-- 個人別合計金額
    pday = 0 #-- 個人別合計日数

    #-- 各月の金額を出力しつつ合計を計算
    for i in marr:
      for line in totalPerMonth:
        if line[1] == name and line[2] == i :
          print('<td class="d_month d_cancel_foot">', end='')
          print("{:,d}".format( (line[3] * 5) + (line[5] * 20) ) + '円</td>', end='')

          #-- 個人ごとの合計を計算
          pttl = pttl + (line[3] * 5) + (line[5] * 20)

          #-- 月ごとの合計は先に計算しておく
          mttl[i-1] = mttl[i-1] + (line[3] * 5) + (line[5] * 20)
          mday[i-1] = mday[i-1] + line[4]

    #-- 個人の合計を出力
    print('<td class="d_total d_cancel_foot">', end='')
    print("{:,d}".format(pttl) + '円</td>' )
    print(TRPRE + "</tr>")

    #-- 日数のタイトルを出力
    print(TRPRE + '<tr>')
    print(TDPRE + '<td class="d_label d_dot">日数</td>', end='')

    #-- 続いて日数も同様に出力する
    for i in marr:
      for line in totalPerMonth:
        if line[1] == name and line[2] == i :
          print('<td class="d_month d_dot">' + str(line[4]) + '日</td>', end='')
          pday = pday + line[4]
    print('<td class="d_total d_dot">' + str(pday) + '日</td>' )
    print(TRPRE + "</tr>")

  #-- 月ごとの合計を出力する
  #-- 行ヘッダ部を出力
  print(TRPRE + '<tr>')
  print(TDPRE + '<td class="f_label" colspan="3">金額合計</td>', end='')
  #-- 各月の合計を出力
  for i in marr:
    print('<td class="f_month">', end='')
    print("{:,d}".format(mttl[i-1]) + '円</td>', end='')
  #-- 年間の合計を出力
  print('<td class="f_label">', end='')
  print("{:,d}".format(sum(mttl)) + '円</td>')
  print(TRPRE + '</tr>')
         
  #-- 行ヘッダ部を出力
  print(TRPRE + '<tr>')
  print(TDPRE + '<td class="f_label" colspan="3">日数合計</td>', end='')
  #-- 各月の合計を出力
  for i in marr:
    print('<td class="f_month">' + str(mday[i-1]) + '日</td>', end='')
  #-- 年間の合計を出力
  print('<td class="f_total">' + str(sum(mday)) + '日</td>')
  print(TRPRE + '</tr>')

  print(THPRE + '</tbody>')
  print(TBPRE + '</table>')
  print("<!-- maintable end -->")

  #-- 最後にサマリのテーブルを出して終了
  print("<!-- tabletop start -->")
  print(TBPRE + '<div class="subcontainer">')
  print(TBPRE + '<table class="subtbl">')
  print(THPRE + '<thead>')
  print(TRPRE + '<tr>')
  print(TDPRE + '<th class="subtbl h_label", colspan="4">' + nendo + '年度：集計結果</th>')
  print(TRPRE + '</tr>')
  print(THPRE + '</thead>')
  print(THPRE + '<tbody>')
  print(TRPRE + '<tr>')
  print(TDPRE + '<th class="subtbl h_label">１カ月平均金額</th><td class="subtbl">' + "{:,d}".format( int(sum(mttl) / 12) ) + '円</td>')
  print(TDPRE + '<th class="subtbl h_label">１カ月平均日数</th><td class="subtbl">' + "{:d}".format( int(sum(mday) / 12) ) + '日</td>')
  print(TRPRE + '</tr>')
  print(THPRE + '</tbody>')
  print(TBPRE + '</table>')
  print(TBPRE + '</div>')
  print("<!-- tabletop end -->")

nendo = sys.argv[1]          
yojitu = sys.argv[2]
meibo = sys.argv[3]
main(nendo)
