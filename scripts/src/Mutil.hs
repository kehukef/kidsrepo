module Mutil where

import System.IO
import System.Directory
import Text.Printf(printf)
import Data.List(isPrefixOf, sort)
import Data.List.Split(splitOn)
import Data.Time.Calendar
import qualified Data.Text as DT
import qualified Data.Text.IO as DTI

toi :: String -> Int
toi = read

-- getFiscal
getFiscal :: String -> String
getFiscal ymd
  | m < 4     = show $ y - 1
  | otherwise = show y
    where (y, m, _) = bara ymd

-- bara
bara :: String -> (Integer, Int, Int)
bara ymd = let [y, m, d] = splitOn "/" ymd
            in (read y, read m, read d)

-- searchFile
searchFile :: String -> String -> IO (Maybe String)
searchFile dir file = do
  cnt <- getDirectoryContents dir
  case filter (== file) cnt of
    [] -> return Nothing
    _  -> return $ Just (dir ++ file)

-- yojituByDate
-- 日付(yyyy/mm/dd)を受けてその日付のデータが含まれるyojituファイルから該当日付分のデータだけ抜き出す
yojituByDate :: String -> IO [[String]]
yojituByDate ymd = getDirectoryContents "/var/www/webkids/data"
                   >>= return . last . sort . filter ( ("yojitu." ++ getFiscal ymd) `isPrefixOf`)
                   >>= readFile . ("/var/www/webkids/data/" ++)
                   >>= return . map words . lines
                   >>= return . hdFilter ymd

-- yojituByID
-- IDを受けて該当するyojituファイルから該当IDのデータだけ抜き出す
--yojituByID :: String -> [[String]]

-- tantoByDate
-- 日付(yyyy/mm/dd)を受けて該当するtantoファイルから該当日付分のデータだけ抜き出す
--tantoByDate :: String -> [[String]]

-- > toMin "01:23"
--   83
-----------------------------------------------------
toMin :: String -> Int
toMin hhss = hh + mm
  where hh = (*60) . read . fst $ break (== ':') hhss :: Int
        mm = read . tail . snd $ break (== ':') hhss  :: Int

-- > toHHMM 62
--   "01:02"
-----------------------------------------------------
toHHMM :: Int -> String
toHHMM minute = hh ++ ":" ++ mm
  where hh = printf "%02d" (minute `div` 60)
        mm = printf "%02d" (minute `mod` 60)

-- > toHMM 62
--   " 1:02"
-----------------------------------------------------
toHMM :: Int -> String
toHMM minute = hh ++ ":" ++ mm
  where hh = printf "%2d" (minute `div` 60)
        mm = printf "%02d" (minute `mod` 60)

-- > dfHHMM "10:00" "11:11"
--   "01:11"
-----------------------------------------------------
dfHHMM :: String -> String -> String
dfHHMM f t = toHHMM $ (toMin t) - (toMin f)

-- > dfHMM "10:00" "11:11"
--   " 1:11"
-----------------------------------------------------
dfHMM :: String -> String -> String
dfHMM f t = toHMM $ (toMin t) - (toMin f)

-- getFee : from(HH:MM) - to(HH:MM)をうけて金額を返す
-----------------------------------------------------
getFee :: String -> String -> String
getFee from to
  | mF < lb && mT > hb = cmm $ show $ (lb - mF) * ht + (hb - lb) * lt + (mT - hb) * ht
  | mF < lb            = cmm $ show $ (lb - mF) * ht + (mT - lb) * lt
  | mT > hb            = cmm $ show $ (hb - mF) * lt + (mT - hb) * ht
  | otherwise          = cmm $ show $ (mT - mF) * lt
  where
    mF = toMin from -- minuteFrom
    mT = toMin to   -- minuteTo
    lb = 480        -- low border
    hb = 6480       -- high border
    lt = 5          -- low tanka
    ht = 20         -- high tanka

-- > getWD "2017-11-30"
--   "Thu"
-----------------------------------------------------
getWD :: String -> String
getWD ymd = getWD' $ fromEnum $ fromGregorian (read y) (read m) (read d)
  where [y,m,d]   = splitOn "-" $ gSub ("/", "-") ymd
        getWD' xs = case (xs `mod` 7) of
                      0 -> "Wed"
                      1 -> "Thu"
                      2 -> "Fri"
                      3 -> "Sat"
                      4 -> "Sun"
                      5 -> "Mon"
                      6 -> "Tue"

-- > getYB "2017-11-30"
--   "(木)"
-----------------------------------------------------
getYB :: String -> String
getYB ymd = getYB' $ fromEnum $ fromGregorian (read y) (read m) (read d)
  where [y,m,d]   = splitOn "-" $ gSub ("/", "-") ymd
        getYB' xs = case (xs `mod` 7) of
                      0 -> "(水)"
                      1 -> "(木)"
                      2 -> "(金)"
                      3 -> "(土)"
                      4 -> "(日)"
                      5 -> "(月)"
                      6 -> "(火)"

-- > s2d "2017/01/01"
--   2017-01-01
s2d :: String -> Maybe Day
s2d cs = case reads (gSub ("/", "-") cs) of
  [(x, "")] -> Just x
  _         -> Nothing

-- > d2s (2017-01-01 :: Day)
--   2017/01/01
d2s :: Day -> Maybe String
d2s = return . gSub ("-", "/") . show

-- > getDays 2018-03-01 2018-03-05
--   [2018-03-01, 2018-03-02, 2018-03-03, 2018-03-04, 2018-03-05]
getDays :: Day -> Day -> [Day]
getDays f t
  | f > t    = []
  | otherwise = f : getDays (addDays 1 f) t

sGetDays :: String -> String -> Maybe [Day]
sGetDays fs ts = do
    f <- s2d fs
    t <- s2d ts
    return $ getDays f t

-- memo
-- 2つの日付の差の日数はdiffDaysで取得できる。
-- n日後はaddDays (n :: Integer) (yyyy-mm-dd :: Day)で取得できる。

-- > wadate "2018/04/01"
--   " 4月 1日(日)"
-----------------------------------------------------
wadate :: String -> String
wadate ymd = let [_, mm, dd] = splitOn "/" ymd
              in printf "%2d月%2d日%s" (toi mm) (toi dd) (getYB ymd)

-- > cmm "10000000"
--   "10,000,000"
-----------------------------------------------------
cmm ::  String -> String
cmm xs
  | head xs == '-'         = '-' : cmm (tail xs)
  | length xs <= 3         = xs
  | length xs `mod` 3 == 1 = take 1 xs ++ "," ++ cmm (drop 1 xs)
  | length xs `mod` 3 == 2 = take 2 xs ++ "," ++ cmm (drop 2 xs)
  | length xs `mod` 3 == 0 = take 3 xs ++ "," ++ cmm (drop 3 xs)

-- > mmc "10,000,000"
--   "10000000"
-----------------------------------------------------
mmc :: String -> String
mmc [] = []
mmc (x:xs)
  | x /= ','  = x : (mmc xs)
  | otherwise = mmc xs

-- > gSub ("abc", "ABC") "aabcdeabcg"
--   "aABCdeABCg"
-----------------------------------------------------
gSub :: (String, String) -> String -> String
gSub _ [] = []
gSub (k,v) tx@(x:xs)
  | k `isPrefixOf` tx = v ++ ( gSub (k,v) (drop (length k) tx) )
  | otherwise         = x :  ( gSub (k,v) xs )

-- > exch "<td>@1@</td><td>@2@</td><td>@3@</td>" ["hoge", "fuga", "piyo"]
--   "<td>hoge</td><td>fuga</td><td>piyo</td>"
-----------------------------------------------------
exch :: String -> [String] -> String
exch txt flds = foldr1 (.) ( map gSub (zip keys flds) ) $ txt
  where keys = map ("@"++) $ map (++"@") $ map show [1..(length flds)]

-- > exch' "@1@_@2@_@3@_@1@" [["ABC", "DEF", "GHI"], ["JKL", "MNO", "PQR"], ["STU", "VWX", "YZ"]]
--   ["ABC_DEF_GHI_ABC","JKL_MNO_PQR_JKL","STU_VWX_YZ_STU"]
-----------------------------------------------------
exch' :: String -> [[String]] -> [String]
exch' txt lns = map (exch txt) lns

-- > flex "@1@_@2@_@3@_@1@" FILEPATH ( <- ABC DEF GHI\nJKL MNO PQR\nSTU VWX YZ\n )
--   ABC_DEF_GHI_ABC
--   JKL_MNO_PQR_JKL
--   STU_VWX_YZ_STU
-----------------------------------------------------
flex :: String -> String -> IO ()
flex txt fl = readFile fl >>= (mapM_ putStrLn ) . (exch' txt) . (map words) . lines

-- hdFilter : 先頭要素が指定された文字列で始まるリストだけ残す
----------------------------------------------------------------------------------
hdFilter :: String -> [[String]] -> [[String]]
hdFilter keyword = filter f
  where f (x:_) = keyword `isPrefixOf` x

-- sndFilter : 2番目の要素が指定された文字列で始まるリストだけ残す
----------------------------------------------------------------------------------
sndFilter :: String -> [[String]] -> [[String]]
sndFilter keyword = filter f
  where f (_:x:_) = keyword `isPrefixOf` x

-- acFilter : 実績があるデータだけ残す
----------------------------------------------------------------------------------
acFilter :: [[String]] -> [[String]]
acFilter = filter f
  where f xs = ((xs!!8 /= blank) && (xs!!9 /= blank)) || ((xs!!10 /= blank) && (xs!!11 /= blank))
            where blank = "--:--"

-- pms : Maybe String を putStrLnする
--       途中で失敗していた場合は、第二引数で受け取った文字列を返す
----------------------------------------------------------------------------------
pms :: Maybe String -> String -> IO ()
pms (Just cs) _ = putStrLn cs
pms Nothing cs  = putStrLn cs

