----------------------------------------------------------------------------------------------------------------
-- Msummary.hs
-- last modify: 2018/04/18 (kehukef@gmail.com)
----------------------------------------------------------------------------------------------------------------

import Mutil
import Data.List
import Data.Ord

pheight :: Int
pheight = 3500

main :: IO ()
main = do
  -- yyyymmを標準入力、contentをファイルの中身に束縛
  yyyymm  <- getLine
  flpath  <- getLine
  content <- readFile flpath
  --content <- readFile "/home/kehukef/haskell/Msummary/testData"

  -- ファイルの中身に対し"年月" "実績有無"でフィルタ後、メンバーIDでソート、
  -- AM/PM分離、MemberIDでグループ化したデータにtlinesを束縛
  let tlines = groupBy (\xs ys -> xs!!0 == ys!!0) $  -- [[String]] -> [[[String]]]
               dvRecord $                            -- [[String]] -> [[String]]
               sortBy (comparing (!!1)) $            -- [[String]] -> [[String]]
               acFilter $                            -- [[String]] -> [[String]]
               hdFilter yyyymm $                     -- [[String]] -> [[String]]
               map words (lines content)             -- String -> [[String]]

  -- HTML出力()
  putStrLn $ gSub (">sameday", " class=\"nbt\">") (getHTML tlines)

-- dvRecord : 一人分のデータを受け取り、朝夕のデータを分割しつつ金額を付与したリストに直す
----------------------------------------------------------------------------------------------------------------
dvRecord :: [[String]] -> [[String]]
dvRecord = concatMap dvRecord'
  where dvRecord' (ymd:id:cls:nm:_:_:_:_:amf:amt:aef:aet:[])
          | all (/=blank) [amf,amt,aef,aet] = [[id, wadate ymd, cls, nm, toHMM (toMin amf), toHMM (toMin amt), dfHMM amf amt, getFee amf amt, ymd]
                                              ,[id, "sameday",  cls, nm, toHMM (toMin aef), toHMM (toMin aet), dfHMM aef aet, getFee aef aet, ymd]]
          | all (/=blank) [amf,amt]         = [[id, wadate ymd, cls, nm, toHMM (toMin amf), toHMM (toMin amt), dfHMM amf amt, getFee amf amt, ymd]]
          | otherwise                       = [[id, wadate ymd, cls, nm, toHMM (toMin aef), toHMM (toMin aet), dfHMM aef aet, getFee aef aet, ymd]]
          where blank      = "--:--"

-- getHTML：tlinesが空になるまでonePageを繰り返す
----------------------------------------------------------------------------------------------------------------
getHTML :: [[[String]]] -> String
getHTML tlines 
  | tlines == []  = ""
  | otherwise     = (onePage tlines) ++ (getHTML (drop (getTableCount (tlines, False, pheight, 0)) tlines))

-- onePage：1ページ分のHTML文字列を返す。
----------------------------------------------------------------------------------------------------------------
onePage :: [[[String]]] -> String
onePage tlines =
  "<div class=\"nobreak\">\n" ++ concat ( map ptPerson (take (getTableCount (tlines, False, pheight, 0)) tlines) ) ++ "</div>\n"

-- getTableCount：先頭から何人分で1ページになるかを計算して返す
-- pheight：1ページの高さ
--      20：明細1行分の高さ
--      30：ヘッダ・フッタ1行分の高さ
----------------------------------------------------------------------------------------------------------------
getTableCount :: ([[[String]]], Bool, Int, Int) -> Int
getTableCount (xs, flg, rest, cnt)
  | xs  == []                = cnt
  | flg == True  && rest < 0 = cnt
  | flg == False && rest < 0 = getTableCount (xs, True, pheight, cnt)
  | otherwise                = getTableCount (tail xs, flg, rest - (length (head xs) * 20 + (30 * 3) ), cnt + 1)

-- ptPerson : 一人分の朝夕分割されたデータを受け取って、HTMLの1テーブル分を出力する
----------------------------------------------------------------------------------------------------------------
ptPerson :: [[String]] -> String
ptPerson []  = ""
ptPerson xss =
  -- ヘッダ
  "  <table class=\"meisai\">\n    <thead>\n"
  ++ "      <tr><th class=\"head_title\">"
  ++ take 4 (last (head xss)) ++ "年" ++ ( take 2 ( drop 5 (last (head xss))) ) ++ "月</th>"
  ++ "<th class=\"head_title\" colspan=\"3\">" ++ ((head xss)!!2) ++ "：" ++ ((head xss)!!3) ++ "</th></tr>\n"
  ++ "      <tr>"
  ++ "<th class=\"meisai_title_1\">キッズ日時</th>"
  ++ "<th class=\"meisai_title_2\"></th>"
  ++ "<th class=\"meisai_title_3\">時間</th>"
  ++ "<th class=\"meisai_title_4\">金額</th>"
  ++ "</tr>\n"
  ++ "    </thead>\n    <tbody>\n"
  -- 中身：exchで各レコードを置換した文字列を入手しくっつける
  ++ concat ( map (exch ("      <tr>"
  ++ "<td class=\"meisai_data\">@2@</td>"
  ++ "<td class=\"meisai_data\">@5@ ～ @6@</td>"
  ++ "<td class=\"meisai_data td_money\">@7@</td>"
  ++ "<td class=\"meisai_data td_money\">\\@8@</td>\n") ) xss )
  -- フッタ
  ++ "      <tr><th class=\"meisai_title t_foot total_foot\" colspan=\"2\">合計</th>"
  ++ "<td class=\"t_foot\">" ++ perTime xss ++ "</td>"
  ++ "<td class=\"t_foot td_money\">" ++ perSum xss ++ "</td></tr>\n"
  ++ "    </tbody>\n  </table>\n"
  where
    -- perTime：一人分の合計時間を出力する
    perTime :: [[String]] -> String
    perTime xss = toHMM $ foldr1 (+) $ map (toMin . (flip (!!) 6)) xss

    -- perSum ：一人分の合計金額を出力する
    perSum :: [[String]] -> String
    perSum xss = "\\" ++ (cmm . show $ foldr1 (+) $ map (read . mmc . (flip (!!) 7)) xss)
