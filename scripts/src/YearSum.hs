-------------------------------------------------
-- YearSum.hs
-- last modify: 2018/02/05 (kehukef@gmail.com)
-------------------------------------------------

import Mutil
import Data.List
import Data.Ord

main :: IO ()
main = do
  -- yyyy(FiscalYear)を標準入力、contentをファイルの中身に束縛
  yyyy    <- getLine
  content <- readFile "/home/kehukef/haskell/testData"

  -- ファイルの中身に対し"年月" "実績有無"でフィルタ後、メンバーIDでソート、
  -- 集計、MemberIDでグループ化したデータにtlinesを束縛
  let tlines = tally $ 
               groupBy (\xs ys -> xs!!1 == ys!!1) $  -- [[String]] -> [[[String]]]
               sortBy (comparing (!!1)) $            -- [[String]] -> [[String]]
               acFilter $                            -- [[String]] -> [[String]]
               sndFilter yyyy $                      -- [[String]] -> [[String]]
               map words (lines content)             -- String -> [[String]]

  -- html出力

  -- テスト用。一人分の出力
  -- ptPerson $ last tlines
  
  mapM_ ptPerson $ tlines

-- tally :: 一人分の全レコードを欲しい形[(cls, name), [Int], [Int]]に直す
----------------------------------------------------------------------------------
tally :: [[String]] -> [(String, String), [Int], [Int]]
tally xs = [ ((head xs)!!2, (head xs)!!3), tallyFee xs, tallyDay xs]
where
  ms = ["/04/", "/05/", "/06/", "/07/", "/08/", "/09/", "/10/", "/11/", "/12/", "/01/", "/02/", "/03/"]
  tallyFee xs = concatMap (tallyFee' xs) ms
  where
    tallyFee' xs m = map (cnvt . drop 8) $ filter (\x -> m `isPrefixOf` (drop 4 (head x))) xs

  tallyDay xs = concatMap (tallyDay' xs) ms

-- ptPerson : 一人分のテーブルを出力する
-----------------------------------------------------------------
ptPerson :: [[String]] -> IO ()
ptPerson [] = return ()
ptPerson xss = do
  putStrLn $ "<table>\n  <thead>\n    <tr>\n      <th>"
             ++ take 4 ((head xss)!!1) ++ "年" ++ ( take 2 ( drop 5 ((head xss)!!1) ) ) ++ "月</th>\n"
             ++ "      <th>" ++ ((head xss)!!2) ++ "：" ++ ((head xss)!!3) ++ "</th>\n"
             ++ "    </tr>\n  </thead>\n  <tbody>"
  mapM_ putStrLn $ map (exch "    <tr><td>@2@</td><td>@5@～@6@</td><td>@7@</td><td>\\@8@</td>") xss
  putStrLn $ "    <tr><td>合計</td><td>" ++ perTime xss ++ "</td><td>" ++ perSum xss ++ "</td></tr>"
  putStrLn $ "  </tbody>\n</table>"
  where
    -- perTime：一人分の合計時間を出力する
    perTime :: [[String]] -> String
    perTime xss = toHHMM $ foldr1 (+) $ map (toMin . (flip (!!) 6)) xss

    -- perSum：一人分の合計金額を出力する
    perSum :: [[String]] -> String
    perSum xss = "\\" ++ (cmm . show $ foldr1 (+) $ map (read . mmc . (flip (!!) 7)) xss)

