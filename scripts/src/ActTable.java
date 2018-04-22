import java.io.*;
import java.util.*;

public class ActTable{
  public static final String trIndent = "      ";
  public static final String tdIndent = trIndent + "  ";
  public static Set<Integer> eachMin = new HashSet<Integer>();
  public static Set<Integer> totalMin = new HashSet<Integer>();

  public static void makeTable(String cls, String nm, String mss, String mes, String ess, String ees, boolean even_flg){
    int ms, me, es, ee;
    eachMin.clear();

    StringBuffer outStr = new StringBuffer();
    outStr.append(tdIndent);

    String hdrStr;
    if ( even_flg ){
      hdrStr = "eve_hd";
    }else{
      hdrStr = "odd_hd";
    }

    outStr.append("<td class=\"" + hdrStr + "\">" + cls + "</td>");
    outStr.append("<td class=\"" + hdrStr + "\">" + nm + "</td>");
    if ( mss.equals("--:--") || mes.equals("--:--") ){
      outStr.append("<td class=\"" + hdrStr + "\"> - </td>");
    }else{
      outStr.append("<td class=\"" + hdrStr + "\">" + chgMin(mss) + " ～ " + chgMin(mes) + "</td>");
      ms = getMin(mss);
      me = getMin(mes);
      for ( int i = ms; i < me; i++ ){
        eachMin.add(i);
        totalMin.add(i);
      }
    }

    if ( ess.equals("--:--") || ees.equals("--:--") ){
      outStr.append("<td class=\"" + hdrStr + "\"> - </td>");
    }else{
      outStr.append("<td class=\"" + hdrStr + "\">" + chgMin(ess) + " ～ " + chgMin(ees) + "</td>");
      es = getMin(ess);
      ee = getMin(ees);
      for ( int j = es; j < ee; j++ ){
        eachMin.add(j);
        totalMin.add(j);
      }
    }

    outStr.append("<td class=\"" + hdrStr + " lst_td" + "\">" + revMin( eachMin.size() ) + "</td>");
    System.out.println(outStr);
  }

  public static int getMin(String tStr){
    //HH:MM -> minutes
    int hh = Integer.parseInt(tStr.split(":")[0]);
    int mm = Integer.parseInt(tStr.split(":")[1]);
    return ( hh * 60 + mm );
  }

  public static String revMin(int im){
    //minutes -> HH:MM(ex 0:01)
    return ( String.format("%d:%02d", ( im / 60 ), ( im % 60 )) );
  }

  public static String revMin_zero(int im){
    //minutes -> HH:MM(ex 00:01)
    return ( String.format("%02d:%02d", ( im / 60 ), ( im % 60 )) );
  }

  public static String chgMin(String tStr){
    //HH:MM -> [H]H:MM (ex 08:01 -> 8:01)
    int hh = Integer.parseInt(tStr.split(":")[0]);
    int mm = Integer.parseInt(tStr.split(":")[1]);
    return ( String.format("%d:%02d", hh, mm) );
  } 

  public static String chgMin_zero(String tStr){
    //[H]H:MM -> HH:MM (ex 8:01 -> 08:01)
    int hh = Integer.parseInt(tStr.split(":")[0]);
    int mm = Integer.parseInt(tStr.split(":")[1]);
    return ( String.format("%02d:%02d", hh, mm) );
  }
 
  public static void main(String args[]){
    ActTable at = new ActTable();

    String line;
    String [] fields = new String[8];
    String cl, nm, mss, mes, ess, ees;
    int ms, me, es, ee;
    boolean flg = false;
    int totalMember = 0;

    // Get Stdin
    try {
      BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in));
      line = stdin.readLine();

      // If target date is no data.
      if ( line == null ){
        System.out.printf( "%s<tr>\n", trIndent);
        System.out.printf(tdIndent);
        System.out.printf("<td colspan=\"5\" class=\"odd_of fst_td lst_td\" >実績は登録されていません</td>\n");
        //makeTable(0,0,0,0,false);
        System.out.printf( "%s</tr>\n", trIndent);
        return;
      }else{
      // Set a ArrayList, and output record until the end of data.
        while ( line != null ){
          fields = line.split(" ");
    
          cl = fields[2];
          nm = fields[3].replace("_", " ");
          mss = fields[4];
          mes = fields[5];
          ess = fields[6];
          ees = fields[7];
          flg = !flg;

          // --- output 1 line ---
          System.out.printf( "%s<tr>\n", trIndent);
          makeTable(cl, nm, mss, mes, ess, ees, flg);
          System.out.printf( "%s</tr>\n", trIndent);

          line = stdin.readLine();
          totalMember += 1;
        }
        System.out.println(trIndent + "<tr>");
        System.out.print(tdIndent + "<th class=\"head_title foot\" >人数合計</th>");
        System.out.println("<td class=\"head_data foot\">" + totalMember + "人</td>");
        System.out.print(tdIndent + "<th class=\"head_title foot\" colspan=\"2\">一日の保育時間</th>");
        System.out.println("<td class=\"head_data foot\">" + revMin( totalMin.size() ) + "</td>");
        System.out.println(trIndent + "</tr>");
        stdin.close();
      }
    }catch(IOException e){
      System.out.println("System error");
    }

  }
}
