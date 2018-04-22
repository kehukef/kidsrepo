# プログラム仕様書：ShowSchecule.hs

指定された範囲の予定表を表示する。
- 入力値の妥当性チェックは画面にて行われる。
- Haskellスクリプトが返すのはHTMLの書き換え部分のみ
- 入力値は以下のとおり
  1. 照会開始日
  2. 照会終了日
usage : ShowSchedule "2017/01/01" "2017/01/05"

### 実装方針
まず、mainの型はIO()。
mainは外(CGI)とやりとりする。
```
main :: IO()
main = do
  inDate  <- getLine
  outDate <- getLIne
  putStrLn $ getSchedule inDate outDate
```

getScheduleの型は
```
getSchedule :: String -> String -> String
```
で、返すのは最終的なHTML文字列。

### 続いてgetScheduleを細分化
getScheduleが必要とする関数は  
- 照会したい日付のリストを返す関数。            -> getDays
- 日付からその日のヘッダーとなるHTMLを返す関数。-> outHeader
- 日付からその日の明細となるHTMLを返す関数。    -> outDetail
よって
```
getSchedule :: String -> String -> String
getSchedule start end = foldl (\d -> outHeader d ++ outDetail d) "Content-type:text:plain\n" (getDays start end)
```
getDaysはstartからendまでの日付のリストを返す(getDays :: Day -> Day -> Maybe [Day])
outHeaderは日付を受けて、その日のヘッダーとなるHTML文字列を返す。(outHeader :: String -> String)
outDetailは日付を受けて、その日の明細となるHTML文字列を返す。(outDetail :: String -> String)

getDaysは汎用的に使えそうなので、myUtilで実装する。
(その他のString <-> Day変換などもmyUtilで実装しておく)
outHeader, outDetailは結構面倒。それぞれ考える。

### outHeader
入力された日付に関するデータを最新のtantoファイルから抜き出し、HTML文字列にして返す。
これはそんなに難しくなさそうだけど、IOが発生するのでそこは別の関数にやらせる。  
これも汎用化しておこう。
区分（tantoなのか、yojituなのか)と日付を受けて該当するファイルからその日付分だけ抜き出し、
リストのリストとして返す関数。
```
readRecords :: String -> String -> [[String]]
```
