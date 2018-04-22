import java.io.*;
import java.util.*;
import java.math.*;

public class Msummary{

  public static final String tbIndent = "      ";
  public static final String trIndent = tbIndent + "  ";
  public static final String tdIndent = trIndent + "  ";

  public int timeToMinute(String cs){
    // HH:MM形式のデータを分に換算して返す
    String [] tArr = new String[2];
    int min;
    tArr = cs.split(":");
    min = (Integer.parseInt(tArr[0])*60) + (Integer.parseInt(tArr[1]));
    return min;
  }

  public String minuteToTime1(int ms){
    // 分をHH:MM形式の文字列にして返す
    String hh, mm;
    hh = String.format("%d", ms / 60);
    mm = String.format("%02d", ms % 60);
    return (hh + ":" + mm);
  }

  public String minuteToTime2(int ms){
    // 分をHH:MM形式の文字列にして返す
    String hh, mm;
    hh = String.format("%02d", ms / 60);
    mm = String.format("%02d", ms % 60);
    return (hh + ":" + mm);
  }

  public String getWeekday(String y, String m, String d){
    int yyyy = Integer.parseInt(y);
    int mm = Integer.parseInt(m);
    int dd = Integer.parseInt(d);
    String rStr="()";

    Calendar cl = new GregorianCalendar(yyyy, mm-1, dd);
    switch (cl.get(Calendar.DAY_OF_WEEK)){
      case Calendar.SUNDAY:
        rStr = "(日)";
        break;
      case Calendar.MONDAY:
        rStr = "(月)";
        break;
      case Calendar.TUESDAY:
        rStr = "(火)";
        break;
      case Calendar.WEDNESDAY:
        rStr = "(水)";
        break;
      case Calendar.THURSDAY:
        rStr = "(木)";
        break;
      case Calendar.FRIDAY:
        rStr = "(金)";
        break;
      case Calendar.SATURDAY:
        rStr = "(土)";
        break;
    }
    return rStr;
  }

  public static void main(String [] args){
    int intDiffTime;
    int jikangaiDiffTime;
    int intSumTime=0;
    int intSumFee=0;
    int fTime, tTime;
    int jikangaiBef, jikangaiAft;
    int tanka = Integer.parseInt(args[0]);
    int koutanka = Integer.parseInt(args[1]);
    int jikangaiBefBorder = 480;
    int jikangaiAftBorder = 1080;
    String strDiffTime;
    String strDiffKingaku;
    String strSumTime;
    String strSumKingaku;
    String weekday;
    String hizuke, line;
    String [] fields = new String[3];
    String [] dtArr = new String[3];

    Msummary msum = new Msummary();
  
    try{
      BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in));

      //一行出力しつつ、合計用の値を加算
      while ( ( line = stdin.readLine() ) != null ){
        intDiffTime = fTime = tTime = 0;

        fields = line.split(" ");

        //年月日を直す(yyyy/mm/dd -> mm月dd日(曜日))
        dtArr = fields[0].split("/");
        weekday = msum.getWeekday(dtArr[0], dtArr[1], dtArr[2]);
        hizuke=Integer.parseInt(dtArr[1]) + "月" + Integer.parseInt(dtArr[2]) + "日" + weekday;

        //開始、終了時刻を分に直して、差分を計算
        fTime = msum.timeToMinute(fields[1]);
        tTime = msum.timeToMinute(fields[2]);
        //時間外(8:00前 or 18:00以降は時間外単価を適用するため仕分ける
        if (jikangaiBefBorder > fTime){
          jikangaiBef = jikangaiBefBorder - fTime;
          fTime = jikangaiBefBorder;
        }else{
          jikangaiBef = 0;
        }

        if (jikangaiAftBorder < tTime){
          jikangaiAft = tTime - jikangaiAftBorder;
          tTime = jikangaiAftBorder;
        }else{
          jikangaiAft = 0;
        }
        //仕分けが終わったら合計を計算
        intDiffTime = tTime - fTime;
        jikangaiDiffTime = jikangaiBef + jikangaiAft;
        strDiffTime = msum.minuteToTime1(intDiffTime + jikangaiDiffTime);
        strDiffKingaku= "¥" + String.format( "%,3d", (intDiffTime * tanka) + (jikangaiDiffTime * koutanka) );

        //合計時間と金額を足しておく
        intSumTime += (intDiffTime + jikangaiDiffTime);
        intSumFee += (intDiffTime * tanka) + (jikangaiDiffTime * koutanka);

        System.out.println(trIndent + "<tr>");
        System.out.printf("%s<td class=\"meisai_data\">%s</td>\n", tdIndent, hizuke);
        System.out.printf("%s<td class=\"meisai_data\">%s ～ %s</td>\n", tdIndent, 
          msum.minuteToTime1(msum.timeToMinute(fields[1])), msum.minuteToTime1(msum.timeToMinute(fields[2])));
        System.out.printf("%s<td class=\"meisai_data td_money\">%s</td>\n", tdIndent, strDiffTime);
        System.out.printf("%s<td class=\"meisai_data td_money\">%s</td>\n", tdIndent, strDiffKingaku);
        System.out.println(trIndent + "</tr>");
      }
    }catch(IOException e){}

    strSumTime = msum.minuteToTime1(intSumTime);
    strSumKingaku = "¥" + String.format("%,3d", intSumFee);

    System.out.println(trIndent + "<tr>");
    System.out.printf("%s<th class=\"meisai_title t_foot total_foot\" colspan=\"2\">合計</th>\n", tdIndent);
    System.out.printf("%s<td class=\"t_foot\">%s</td>\n", tdIndent, strSumTime);
    System.out.printf("%s<td class=\"t_foot td_money\">%s</td>\n", tdIndent, strSumKingaku);
    System.out.println(trIndent + "</tr>");
    System.out.println(tbIndent + "</table>");
  }
}
