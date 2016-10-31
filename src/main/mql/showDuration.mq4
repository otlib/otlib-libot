// showDuration.mq4 [Script]

#property description "Draw vertical lines onto the active chart, separated by"
#property description "increments of the specified number of bars"
#property copyright "Sean Champ"
#property link      "http://onename.com/spchamp"
#property version   "1.00"
#property strict
#property script_show_inputs

// See also: clearObj.mq4

// input parameters
input int               sd_tf=20;                // Period for Chart Markup
input color             sd_color=clrSilver;     // Line Color
input ENUM_LINE_STYLE   sd_style=STYLE_SOLID;   // Line Style
input int               sd_width=1;             // Line Width
input bool              sd_asbackg=false;       // Draw as Background
input bool              sd_selectable=true;     // Draw Selectable Objects
input bool              sd_hideobj=true;        // Hide Objects from Object List
input bool              sd_zidx=0;              // Z Index for Drawn Objects

void initVline(const long chart, 
               const string name, 
               const color clr,
               const ENUM_LINE_STYLE style,
               const int width,
               const bool asbackg,
               const bool selectable,
               const bool hideobj,
               const long zidx) {
   ObjectSetInteger(chart,name,OBJPROP_COLOR,clr);
   ObjectSetInteger(chart,name,OBJPROP_STYLE,style);
   ObjectSetInteger(chart,name,OBJPROP_WIDTH,width);
   ObjectSetInteger(chart,name,OBJPROP_BACK,asbackg);
   ObjectSetInteger(chart,name,OBJPROP_SELECTABLE,selectable);
   ObjectSetInteger(chart,name,OBJPROP_SELECTED,false);
   ObjectSetInteger(chart,name,OBJPROP_HIDDEN,hideobj);
   ObjectSetInteger(chart,name,OBJPROP_ZORDER,zidx);
}

bool drawVline(const long              chart=0, 
               string                  name=NULL,
               const int               subwindow=0,
               const int               backshift=0,
               const color             clr=clrSilver,
               const ENUM_LINE_STYLE   style=STYLE_SOLID,
               const int               width=1,
               const bool              asbackg=false,
               const bool              selectable=true,
               const bool              hideobj=true,
               const long              zidx=0) {

   const string symbol=ChartSymbol(chart);
   const ENUM_TIMEFRAMES tf=ChartPeriod(chart);
   const datetime time=iTime(symbol,tf,backshift);
   
   if(name == NULL) {
      name="VLine " + TimeToString(time,TIME_DATE|TIME_MINUTES|TIME_SECONDS);
   }

   // create a vertical line in only the specified subwindow (will 0 cover all subwindows?)
   const bool objp = ObjectCreate(chart,name,OBJ_VLINE,subwindow,time,0);
   if(!objp) {
      PrintFormat("%s error %d when creating vertical line for time %s", __FUNCTION__, GetLastError(),TimeToStr(time));
      return false;
   } else {
      // initialize the single vertical line
      initVline(chart,name,clr,style,width,asbackg,selectable,hideobj,zidx);
      return true;
   }
   
}

void OnStart() {
  const int nBars = iBars(NULL,0);
  for(int n = 0; n < nBars; n+=sd_tf) {
   drawVline(0,NULL,0,n,sd_color,sd_style,sd_width,sd_asbackg,sd_selectable,sd_hideobj,sd_zidx);
  }
}
