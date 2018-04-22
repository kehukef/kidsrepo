import java.io.*;
import java.util.*;

public class Timeline{
  public static final String trIndent = "     ";
  public static final String tdIndent = "       ";

  public void makeHeader(String cls, String nm, String ms, String me, String es, String ee, boolean even_flg){
    String outStr = tdIndent;
    String hdrStr = "odd_hd";

    if ( even_flg ){
      hdrStr = "eve_hd";
    }

    outStr = outStr + "<td class=\"" + hdrStr + "\">" + cls + "</td>";
    outStr = outStr + "<td class=\"" + hdrStr + "\">" + nm + "</td>";
    if ( ms.equals("--:--") ){
      outStr = outStr + "<td class=\"" + hdrStr + "\"> - </td>";
    }else{
      outStr = outStr + "<td class=\"" + hdrStr + "\">" + ms + " ～ " + me + "</td>";
    }

    if ( es.equals("--:--") ){
      outStr = outStr + "<td class=\"" + hdrStr + "\"> - </td>";
    }else{
      outStr = outStr + "<td class=\"" + hdrStr + "\">" + es + " ～ " + ee + "</td>";
    }

    System.out.println(outStr);
  }

  public void makeChart(int ms, int me, int es, int ee, boolean even_flg){
    System.out.printf("%s",tdIndent);
    for ( int i=480; i < (19 * 60); i += 5 ){
      String outStr = "<td";

      if ( (i >= ms && i < me) || (i >= es && i < ee) ){
        // When i is in a range.
        if ( even_flg ){
          outStr = outStr + " class=\"eve_on";
        }else{
          outStr = outStr + " class=\"odd_on";
        }
      }else{
        // When i is out of range.
        if ( even_flg ){
          outStr = outStr + " class=\"eve_of";
        }else{
          outStr = outStr + " class=\"odd_of";
        }
      }
      
      if ( i % 30 == 0){
        // Draw border every 30 minutes.
        outStr = outStr + " bdsell\" ></td>";
        System.out.print(outStr);
        System.out.printf("\n      ");
      }else{
        if ( i == (19 * 60 - 5) ){
          // When last cell, draw right border.
          outStr = outStr + " fnlsell\" ></td>";
          System.out.print(outStr);
        }else{
          outStr = outStr + "\" ></td>";
          System.out.print(outStr);
        }
      }
    }
    System.out.printf("\n");
  }

  public int changeMinutes(String timeString){
    if ( timeString.indexOf("--") < 0 ){
      int bef = Integer.parseInt(timeString.substring(0,2)) * 60;
      int aft = Integer.parseInt(timeString.substring(3,5));
      return bef + aft;
    }else{
      return 0;
    }
  }

  public static void main(String args[]){
    Timeline tl = new Timeline();

    String line;
    String [] fields = new String[8];
    String cl, nm, mss, mes, ess, ees;
    int ms, me, es, ee;
    boolean flg = false;

    // Get Stdin
    try {
      BufferedReader stdin = new BufferedReader(new InputStreamReader(System.in));
      line = stdin.readLine();

      // If target date is no data.
      if ( line == null ){
        System.out.printf( "%s<tr>\n", trIndent);
        System.out.printf(tdIndent);
        System.out.printf("<td colspan=\"4\" class=\"odd_of fst_td lst_td\" >予定は登録されていません</td>\n");
        tl.makeChart(0,0,0,0,false);
        System.out.printf( "%s<tr>\n", trIndent);
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
          ms = tl.changeMinutes(mss);
          me = tl.changeMinutes(mes);
          es = tl.changeMinutes(ess);
          ee = tl.changeMinutes(ees);
          flg = !flg;
    
          // --- output 1 line ---
          System.out.printf( "%s<tr>\n", trIndent);
          tl.makeHeader(cl, nm, mss, mes, ess, ees, flg);
          tl.makeChart(ms, me, es, ee, flg);
          System.out.printf( "%s</tr>\n", trIndent);

          line = stdin.readLine();
        }
        stdin.close();
      }
    }catch(IOException e){
      System.out.println("System error");
    }

  }
}
