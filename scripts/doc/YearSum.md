## 目標とするデータ形式
    type Each = (String, String, [Int], [Int])
    type Fiscal = [Each]
    これは
    [ (class, name, [Apr_fee, ... , Mar_fee], [Apr_day, ... , Mar_day]), 
      (class, name, [Apr_fee, ... , Mar_fee], [Apr_day, ... , Mar_day]), 
      ...が人数分
    ]
    ということ。

ひとり分の作り方(2017の場合)
該当年度のユーザIDで(filter)すればおのずとその年度のデータだけになる。
んで、それをこんどは月ごとにわける(groupby)かな
月ごとの合計金額・合計日数をリストにする。
  [201704, 201705, 201706, .. ,201803]でmap
  yyyymmでフィルタ。さらに実績ありのみでフィルタ。
  すると、このレコード数は合計日数と一致する。
  合計金額はwriterとかmonoidあたりでコツコツ積めそう。

## 必要な関数
### main :: IO()
メイン

### readData :: FilePath -> Fiscal
ファイルを呼んで↑のデータ形式で返す

### plotTable :: Fiscal -> String
テーブルを作成する

