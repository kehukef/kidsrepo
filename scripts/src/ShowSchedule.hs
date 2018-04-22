--------------------------------------------------------------------------
-- summary      : show schedule of from $1 to $2.
-- usage        : ShowSchedule "YYYY/MM/DD" "YYYY/MM/DD"
-- last modify  : 2018/03/13 toshiro shimauchi(kehukef@gmail.com)
--------------------------------------------------------------------------
import Mutil

main :: IO()
main = do
    fromDate <- getLine
    toDate   <- getLine
    -- putStrLn $ getBanner fromDate toDate
    print $ s2d "2018/01/01" >>= \fd -> s2d "2018/01/30" >>= \td -> return $ getDays fd td
    pms putString
    --print $ getHTML fromDate toDate

-- Header
getBanner :: String -> String -> String
getBanner f t = "Content-type:text/plain\n" ++
                "<div id=\"during\">表示期間：" ++ f ++ " ～ " ++ t ++ "</div>"

-- HTML Contents
--getHTML :: String -> String -> Maybe [Day]
--getHTML f t = s2d f >>= \fd -> s2d t >>= \td -> getDays fd td

putString = Just "hoge"
